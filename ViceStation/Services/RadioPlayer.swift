import AVFoundation
import MediaPlayer
import Observation
import SwiftUI

/// Spielt Sender wie im Spiel: Beim Einschalten läuft der Sender „schon“,
/// d. h. ein zufälliger Song startet an einer zufälligen Stelle. Danach
/// werden Songs gemischt (ohne Wiederholung) und Jingles/Ansagen eingestreut.
@Observable
@MainActor
final class RadioPlayer {
    private(set) var currentStation: Station?
    private(set) var currentItem: PlayableItem?
    private(set) var isPlaying = false
    private(set) var progress: Double = 0

    /// Einstellungen
    var liveTuneIn: Bool {
        didSet { UserDefaults.standard.set(liveTuneIn, forKey: "liveTuneIn") }
    }
    var extrasChance: Double {
        didSet { UserDefaults.standard.set(extrasChance, forKey: "extrasChance") }
    }
    var staticEnabled: Bool {
        didSet { UserDefaults.standard.set(staticEnabled, forKey: "staticEnabled") }
    }

    private let player = AVPlayer()
    private let noise = TuningNoise()
    private weak var library: StationLibrary?
    private var bags: [String: [PlayableItem]] = [:]
    private var lastWasExtra = false
    private var endObserver: NSObjectProtocol?
    private var timeObserver: Any?
    private var tuneTask: Task<Void, Never>?

    init() {
        let defaults = UserDefaults.standard
        defaults.register(defaults: ["liveTuneIn": true, "extrasChance": 0.25, "staticEnabled": true])
        liveTuneIn = defaults.bool(forKey: "liveTuneIn")
        extrasChance = defaults.double(forKey: "extrasChance")
        staticEnabled = defaults.bool(forKey: "staticEnabled")

        configureSession()
        configureRemoteCommands()

        endObserver = NotificationCenter.default.addObserver(
            forName: AVPlayerItem.didPlayToEndTimeNotification, object: nil, queue: .main
        ) { [weak self] note in
            MainActor.assumeIsolated {
                guard let self, (note.object as? AVPlayerItem) === self.player.currentItem else { return }
                self.advance()
            }
        }
        timeObserver = player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.5, preferredTimescale: 600),
                                                      queue: .main) { [weak self] time in
            MainActor.assumeIsolated {
                guard let self, let item = self.player.currentItem else { return }
                let duration = item.duration.seconds
                self.progress = duration.isFinite && duration > 0 ? time.seconds / duration : 0
            }
        }
    }

    func attach(library: StationLibrary) {
        self.library = library
    }

    // MARK: - Steuerung

    func tune(to station: Station?) {
        tuneTask?.cancel()
        guard let station else { turnOff(); return }
        if station.id == currentStation?.id, isPlaying { return }
        currentStation = station
        UISelectionFeedbackGenerator().selectionChanged()

        tuneTask = Task {
            player.pause()
            if staticEnabled { await noise.burst(duration: 0.45) }
            guard !Task.isCancelled else { return }
            guard let item = nextItem(for: station, allowExtra: false) else {
                currentItem = nil
                isPlaying = false
                updateNowPlaying()
                return
            }
            await play(item, randomOffset: liveTuneIn)
        }
    }

    func turnOff() {
        tuneTask?.cancel()
        player.pause()
        player.replaceCurrentItem(with: nil)
        currentStation = nil
        currentItem = nil
        isPlaying = false
        progress = 0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }

    func togglePlayPause() {
        guard currentItem != nil else {
            if let station = currentStation { tune(to: station) }
            return
        }
        if isPlaying { player.pause() } else { player.play() }
        isPlaying.toggle()
        updateNowPlaying()
    }

    func skip() { advance(forceSong: true) }

    func nextStation(_ step: Int) {
        guard let library else { return }
        let list = library.visibleStations
        guard !list.isEmpty else { return }
        let index = currentStation.flatMap { s in list.firstIndex(of: s) } ?? -step
        let next = (index + step + list.count) % list.count
        tune(to: list[next])
    }

    // MARK: - Intern

    private func advance(forceSong: Bool = false) {
        guard let station = currentStation else { return }
        tuneTask?.cancel()
        tuneTask = Task {
            guard let item = nextItem(for: station, allowExtra: !forceSong) else { return }
            await play(item, randomOffset: false)
        }
    }

    private func nextItem(for station: Station, allowExtra: Bool) -> PlayableItem? {
        guard let content = library?.content(for: station) else { return nil }
        if allowExtra, !lastWasExtra, !content.extras.isEmpty, Double.random(in: 0..<1) < extrasChance {
            lastWasExtra = true
            return content.extras.randomElement()
        }
        lastWasExtra = false
        guard !content.songs.isEmpty else { return nil }
        var bag = bags[station.id]?.filter { content.songs.contains($0) } ?? []
        if bag.isEmpty {
            bag = content.songs.shuffled()
            // nicht direkt denselben Song nochmal
            if bag.count > 1, bag.last == currentItem { bag.swapAt(0, bag.count - 1) }
        }
        let item = bag.removeLast()
        bags[station.id] = bag
        return item
    }

    private func play(_ item: PlayableItem, randomOffset: Bool) async {
        let playerItem = AVPlayerItem(url: item.url)
        player.replaceCurrentItem(with: playerItem)
        currentItem = item
        progress = 0
        if randomOffset {
            let asset = AVURLAsset(url: item.url)
            if let duration = try? await asset.load(.duration), duration.seconds.isFinite, duration.seconds > 30 {
                let offset = duration.seconds * Double.random(in: 0.05...0.7)
                await player.seek(to: CMTime(seconds: offset, preferredTimescale: 600))
            }
        }
        guard !Task.isCancelled else { return }
        try? AVAudioSession.sharedInstance().setActive(true)
        player.play()
        isPlaying = true
        updateNowPlaying()
    }

    private func configureSession() {
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
    }

    private func configureRemoteCommands() {
        let center = MPRemoteCommandCenter.shared()
        center.playCommand.addTarget { [weak self] _ in
            MainActor.assumeIsolated { if self?.isPlaying == false { self?.togglePlayPause() } }
            return .success
        }
        center.pauseCommand.addTarget { [weak self] _ in
            MainActor.assumeIsolated { if self?.isPlaying == true { self?.togglePlayPause() } }
            return .success
        }
        center.togglePlayPauseCommand.addTarget { [weak self] _ in
            MainActor.assumeIsolated { self?.togglePlayPause() }
            return .success
        }
        // Wie im Auto: vor/zurück = Sender wechseln
        center.nextTrackCommand.addTarget { [weak self] _ in
            MainActor.assumeIsolated { self?.nextStation(1) }
            return .success
        }
        center.previousTrackCommand.addTarget { [weak self] _ in
            MainActor.assumeIsolated { self?.nextStation(-1) }
            return .success
        }
    }

    private func updateNowPlaying() {
        guard let station = currentStation else {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
            return
        }
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: currentItem?.title ?? station.name,
            MPMediaItemPropertyArtist: currentItem?.kind == .extra ? station.name : (currentItem?.artist ?? ""),
            MPMediaItemPropertyAlbumTitle: station.name,
            MPNowPlayingInfoPropertyIsLiveStream: true,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1.0 : 0.0,
        ]
        if let image = artwork(for: station) {
            info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
        }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    private func artwork(for station: Station) -> UIImage? {
        if let logo = library?.logos[station.id] { return logo }
        let renderer = ImageRenderer(content: StationBadge(station: station, logo: nil, size: 600))
        renderer.scale = 1
        return renderer.uiImage
    }
}

/// Kurzes Funkrauschen beim Senderwechsel – wird live erzeugt, keine Audiodatei nötig.
@MainActor
final class TuningNoise {
    private let engine = AVAudioEngine()
    private let node = AVAudioPlayerNode()
    private var buffer: AVAudioPCMBuffer?

    init() {
        let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!
        engine.attach(node)
        engine.connect(node, to: engine.mainMixerNode, format: format)
        let frames = AVAudioFrameCount(44_100 * 0.6)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames),
              let samples = buffer.floatChannelData?[0] else { return }
        buffer.frameLength = frames
        var last: Float = 0
        for i in 0..<Int(frames) {
            let t = Float(i) / Float(frames)
            let envelope = min(1, t * 12) * min(1, (1 - t) * 4)          // Ein-/Ausblenden
            let crackle: Float = Float.random(in: 0..<1) < 0.002 ? Float.random(in: -1...1) : 0
            let white = Float.random(in: -1...1)
            last = last * 0.55 + white * 0.45                             // leicht gefiltert
            let wobble = 0.6 + 0.4 * sin(Float(i) * 0.0021)                // „Senderdrehen“
            samples[i] = (last * wobble + crackle) * envelope * 0.35
        }
        self.buffer = buffer
    }

    func burst(duration: Double) async {
        guard let buffer else { return }
        do {
            if !engine.isRunning { try engine.start() }
        } catch { return }
        node.stop()
        node.scheduleBuffer(buffer, at: nil, options: [.interrupts], completionHandler: nil)
        node.play()
        try? await Task.sleep(for: .seconds(duration))
    }
}
