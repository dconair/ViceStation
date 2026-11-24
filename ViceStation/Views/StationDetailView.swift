import PhotosUI
import SwiftUI
import UniformTypeIdentifiers

struct StationDetailView: View {
    let station: Station
    @Environment(StationLibrary.self) private var library
    @Environment(RadioPlayer.self) private var player
    @State private var importingSongs = false
    @State private var importingExtras = false
    @State private var importingLogoFile = false
    @State private var photoItem: PhotosPickerItem?
    @State private var showPhotoPicker = false
    @State private var filter: Filter = .all

    enum Filter: String, CaseIterable { case all = "Alle", missing = "Fehlend", present = "Vorhanden" }

    var body: some View {
        let content = library.content(for: station)
        ZStack {
            SunsetBackground()
            ScrollView {
                VStack(spacing: 16) {
                    header(content)
                    actions(content)
                    tracklist(content)
                }
                .padding()
                .padding(.bottom, 100)
            }
        }
        .navigationTitle(station.name)
        .navigationBarTitleDisplayMode(.inline)
        .fileImporter(isPresented: $importingSongs, allowedContentTypes: [.audio], allowsMultipleSelection: true) { result in
            if case let .success(urls) = result { library.importFiles(urls, into: station) }
        }
        .fileImporter(isPresented: $importingExtras, allowedContentTypes: [.audio], allowsMultipleSelection: true) { result in
            if case let .success(urls) = result { library.importFiles(urls, into: station, asExtras: true) }
        }
        .fileImporter(isPresented: $importingLogoFile, allowedContentTypes: [.image], allowsMultipleSelection: false) { result in
            guard case let .success(urls) = result, let url = urls.first else { return }
            let scoped = url.startAccessingSecurityScopedResource()
            defer { if scoped { url.stopAccessingSecurityScopedResource() } }
            if let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
                library.setLogo(image, for: station)
            }
        }
        .photosPicker(isPresented: $showPhotoPicker, selection: $photoItem, matching: .images)
        .onChange(of: photoItem) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self), let image = UIImage(data: data) {
                    library.setLogo(image, for: station)
                }
                photoItem = nil
            }
        }
    }

    private func header(_ content: StationContent) -> some View {
        VStack(spacing: 10) {
            Menu {
                Button("Aus Fotos wählen", systemImage: "photo") { showPhotoPicker = true }
                Button("Aus Dateien wählen", systemImage: "folder") { importingLogoFile = true }
                if library.logos[station.id] != nil {
                    Button("Eigenes Logo entfernen", systemImage: "trash", role: .destructive) { library.removeLogo(for: station) }
                }
            } label: {
                StationBadge(station: station, logo: library.logos[station.id], size: 150,
                             selected: player.currentStation?.id == station.id)
                    .overlay(alignment: .bottomTrailing) {
                        Image(systemName: "pencil.circle.fill")
                            .font(.title)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.white, Vice.sunsetPink)
                    }
            }
            Text(station.name.uppercased()).font(.vice(34)).foregroundStyle(Vice.logo)
            Text(station.genre).font(.viceBody(16)).foregroundStyle(.white)
            Text("Hosts: \(station.hosts)").font(.viceBody(13)).foregroundStyle(.white.opacity(0.7))
            Text("\(content.matched.count) von \(station.tracks.count) Songs vorhanden · \(content.extras.count) Jingles")
                .font(.viceBody(13, weight: .bold)).foregroundStyle(Vice.teal)
        }
        .frame(maxWidth: .infinity)
        .neonCard(station.primaryColor)
    }

    private func actions(_ content: StationContent) -> some View {
        VStack(spacing: 10) {
            Button {
                player.tune(to: station)
            } label: {
                Label(player.currentStation?.id == station.id && player.isPlaying ? "Läuft gerade" : "Einschalten",
                      systemImage: "dot.radiowaves.left.and.right")
                    .font(.vice(20))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Vice.logo, in: Capsule())
                    .foregroundStyle(.white)
            }
            .disabled(!content.isPlayable)
            .opacity(content.isPlayable ? 1 : 0.5)

            HStack(spacing: 10) {
                smallButton("Songs importieren", "square.and.arrow.down") { importingSongs = true }
                smallButton("Jingles / Ansagen", "megaphone") { importingExtras = true }
            }
            ShareLink(item: library.missingSongsText(for: [station])) {
                Label("Liste fehlender Songs teilen", systemImage: "square.and.arrow.up")
                    .font(.viceBody(14, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.1), in: Capsule())
                    .foregroundStyle(.white)
            }
        }
    }

    private func smallButton(_ title: String, _ icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.viceBody(14, weight: .bold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.1), in: Capsule())
                .overlay(Capsule().strokeBorder(Vice.teal.opacity(0.6)))
                .foregroundStyle(.white)
        }
    }

    private func tracklist(_ content: StationContent) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("TRACKLIST").font(.vice(22)).foregroundStyle(.white)
                Spacer()
            }
            Picker("Filter", selection: $filter) {
                ForEach(Filter.allCases, id: \.self) { Text($0.rawValue) }
            }
            .pickerStyle(.segmented)

            let tracks = station.tracks.filter { track in
                switch filter {
                case .all: true
                case .missing: content.matched[track.number] == nil
                case .present: content.matched[track.number] != nil
                }
            }
            ForEach(tracks) { track in
                let present = content.matched[track.number] != nil
                let playing = player.currentItem?.trackNumber == track.number && player.currentStation?.id == station.id
                HStack(spacing: 10) {
                    Text(String(format: "%03d", track.number))
                        .font(.viceBody(12)).monospacedDigit()
                        .foregroundStyle(.white.opacity(0.5))
                    VStack(alignment: .leading, spacing: 1) {
                        Text(track.title).font(.viceBody(15, weight: .bold))
                            .foregroundStyle(playing ? Vice.teal : .white)
                        Text(track.artist).font(.viceBody(12)).foregroundStyle(.white.opacity(0.65))
                    }
                    Spacer()
                    Image(systemName: playing ? "speaker.wave.2.fill" : (present ? "checkmark.circle.fill" : "xmark.circle"))
                        .foregroundStyle(playing ? Vice.teal : (present ? Color.green : Vice.sunsetOrange.opacity(0.8)))
                }
                .padding(.vertical, 4)
                Divider().overlay(Color.white.opacity(0.1))
            }
            let custom = content.songs.filter { $0.trackNumber == nil }
            if !custom.isEmpty {
                Text("EIGENE SONGS (nicht in der GTA-VI-Liste)").font(.vice(16)).foregroundStyle(Vice.sunsetOrange).padding(.top, 8)
                ForEach(custom) { item in
                    VStack(alignment: .leading, spacing: 1) {
                        Text(item.title).font(.viceBody(15, weight: .bold)).foregroundStyle(.white)
                        Text(item.artist).font(.viceBody(12)).foregroundStyle(.white.opacity(0.65))
                    }
                }
            }
        }
        .neonCard(station.secondaryColor)
    }
}
