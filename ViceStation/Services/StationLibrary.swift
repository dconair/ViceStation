import Foundation
import Observation
import UIKit

/// Lädt den Senderkatalog, legt die Ordnerstruktur in „Dateien“ an und gleicht
/// vorhandene Audiodateien mit der GTA-VI-Trackliste ab.
@Observable
@MainActor
final class StationLibrary {
    private(set) var game = ""
    private(set) var stations: [Station] = []
    private(set) var content: [String: StationContent] = [:]
    private(set) var logos: [String: UIImage] = [:]
    private(set) var isScanning = false

    /// Geheimsender (The Vault Radio) – wie im Spiel erst freischalten.
    var vaultUnlocked: Bool = UserDefaults.standard.bool(forKey: "vaultUnlocked") {
        didSet { UserDefaults.standard.set(vaultUnlocked, forKey: "vaultUnlocked") }
    }

    /// Sender, die im Radio-Rad auftauchen.
    var visibleStations: [Station] {
        stations.filter { !$0.secret || vaultUnlocked }
    }

    nonisolated static let audioExtensions: Set<String> = ["mp3", "m4a", "aac", "wav", "aiff", "aif", "flac", "caf", "mp4"]
    nonisolated static let imageExtensions: Set<String> = ["png", "jpg", "jpeg", "heic", "webp"]

    let rootURL: URL = {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("Stations", isDirectory: true)
    }()

    func folder(for station: Station) -> URL {
        rootURL.appendingPathComponent(station.id, isDirectory: true)
    }

    func extrasFolder(for station: Station) -> URL {
        folder(for: station).appendingPathComponent("_extras", isDirectory: true)
    }

    func content(for station: Station) -> StationContent {
        content[station.id] ?? StationContent()
    }

    var totalTracks: Int { stations.reduce(0) { $0 + $1.tracks.count } }
    var totalMatched: Int { content.values.reduce(0) { $0 + $1.matched.count } }

    // MARK: - Setup

    func bootstrap() {
        guard stations.isEmpty else { return }
        if let url = Bundle.main.url(forResource: "Stations", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let catalog = try? JSONDecoder().decode(StationCatalog.self, from: data) {
            game = catalog.game
            stations = catalog.stations
        }
        createFolders()
        rescan()
    }

    private func createFolders() {
        let fm = FileManager.default
        for station in stations {
            try? fm.createDirectory(at: extrasFolder(for: station), withIntermediateDirectories: true)
            let list = station.tracks
                .map { "\($0.fileName)" }
                .joined(separator: "\n")
            let header = """
            \(station.name) – \(station.genre)
            Lege hier die Songs ab (mp3/m4a/…). Empfohlene Dateinamen:

            """
            let readme = folder(for: station).appendingPathComponent("_SONGLISTE.txt")
            try? (header + list + "\n").write(to: readme, atomically: true, encoding: .utf8)
        }
    }

    // MARK: - Scan

    func rescan() {
        isScanning = true
        let stations = self.stations
        let root = rootURL
        Task.detached(priority: .userInitiated) {
            var result: [String: StationContent] = [:]
            var logos: [String: UIImage] = [:]
            for station in stations {
                let folder = root.appendingPathComponent(station.id, isDirectory: true)
                let scanned = Self.scan(station: station, folder: folder)
                result[station.id] = scanned
                if let logo = scanned.logoURL, let image = UIImage(contentsOfFile: logo.path) {
                    logos[station.id] = image
                }
            }
            await MainActor.run {
                self.content = result
                self.logos = logos
                self.isScanning = false
            }
        }
    }

    nonisolated private static func scan(station: Station, folder: URL) -> StationContent {
        let fm = FileManager.default
        var content = StationContent()
        let files = (try? fm.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil,
                                                 options: [.skipsHiddenFiles])) ?? []

        content.logoURL = files.first {
            $0.deletingPathExtension().lastPathComponent.lowercased() == "logo"
                && imageExtensions.contains($0.pathExtension.lowercased())
        }

        let audio = files
            .filter { audioExtensions.contains($0.pathExtension.lowercased()) }
            .sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }

        let matcher = TrackMatcher(tracks: station.tracks)
        for file in audio {
            if let track = matcher.match(fileName: file.lastPathComponent, excluding: Set(content.matched.keys)) {
                content.matched[track.number] = file
                content.songs.append(PlayableItem(url: file, title: track.title, artist: track.artist,
                                                  kind: .song, trackNumber: track.number))
            } else {
                let (artist, title) = TrackMatcher.guessArtistTitle(from: file)
                content.songs.append(PlayableItem(url: file, title: title, artist: artist ?? station.name,
                                                  kind: .song, trackNumber: nil))
            }
        }

        let extrasDir = folder.appendingPathComponent("_extras", isDirectory: true)
        let extras = (try? fm.contentsOfDirectory(at: extrasDir, includingPropertiesForKeys: nil,
                                                  options: [.skipsHiddenFiles])) ?? []
        content.extras = extras
            .filter { audioExtensions.contains($0.pathExtension.lowercased()) }
            .map { PlayableItem(url: $0, title: $0.deletingPathExtension().lastPathComponent,
                                artist: station.name, kind: .extra, trackNumber: nil) }
        return content
    }

    // MARK: - Import

    /// Kopiert vom Nutzer gewählte Dateien in den Senderordner.
    func importFiles(_ urls: [URL], into station: Station, asExtras: Bool = false) {
        let target = asExtras ? extrasFolder(for: station) : folder(for: station)
        let fm = FileManager.default
        try? fm.createDirectory(at: target, withIntermediateDirectories: true)
        for url in urls {
            let scoped = url.startAccessingSecurityScopedResource()
            defer { if scoped { url.stopAccessingSecurityScopedResource() } }
            let dest = target.appendingPathComponent(url.lastPathComponent)
            try? fm.removeItem(at: dest)
            try? fm.copyItem(at: url, to: dest)
        }
        rescan()
    }

    /// Speichert ein vom Nutzer gewähltes Bild als logo.png des Senders.
    func setLogo(_ image: UIImage, for station: Station) {
        let fm = FileManager.default
        let folder = folder(for: station)
        try? fm.createDirectory(at: folder, withIntermediateDirectories: true)
        // alte Logos (andere Endungen) entfernen
        for ext in Self.imageExtensions {
            try? fm.removeItem(at: folder.appendingPathComponent("logo.\(ext)"))
        }
        let square = image.squareCropped(maxSide: 600)
        if let data = square.pngData() {
            try? data.write(to: folder.appendingPathComponent("logo.png"))
        }
        logos[station.id] = square
    }

    func removeLogo(for station: Station) {
        let fm = FileManager.default
        for ext in Self.imageExtensions {
            try? fm.removeItem(at: folder(for: station).appendingPathComponent("logo.\(ext)"))
        }
        logos[station.id] = nil
    }

    // MARK: - Export

    func missingSongsText(for stations: [Station]? = nil) -> String {
        var lines: [String] = ["ViceStation – fehlende Songs (GTA VI Radio)", ""]
        for station in stations ?? self.stations {
            let matched = content(for: station).matched
            let missing = station.tracks.filter { matched[$0.number] == nil }
            guard !missing.isEmpty else { continue }
            lines.append("== \(station.name) (\(missing.count) fehlen) – Ordner Stations/\(station.id)/")
            lines += missing.map { "\($0.number). \($0.artist) – \($0.title)" }
            lines.append("")
        }
        return lines.joined(separator: "\n")
    }
}

extension UIImage {
    func squareCropped(maxSide: CGFloat) -> UIImage {
        let side = min(size.width, size.height)
        let origin = CGPoint(x: (size.width - side) / 2, y: (size.height - side) / 2)
        let target = min(side, maxSide)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        return UIGraphicsImageRenderer(size: CGSize(width: target, height: target), format: format).image { _ in
            let scale = target / side
            draw(in: CGRect(x: -origin.x * scale, y: -origin.y * scale,
                            width: size.width * scale, height: size.height * scale))
        }
    }
}
