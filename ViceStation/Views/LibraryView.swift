import SwiftUI

/// Übersicht: Wie viel der 810 Songs schon da sind, Anleitung, Einstellungen.
struct LibraryView: View {
    @Environment(StationLibrary.self) private var library
    @Environment(RadioPlayer.self) private var player

    var body: some View {
        @Bindable var player = player
        ScrollView {
            VStack(spacing: 16) {
                VStack(spacing: 8) {
                    Text("SAMMLUNG").font(.vice(28)).foregroundStyle(Vice.logo)
                    Text("\(library.totalMatched) / \(library.totalTracks)")
                        .font(.vice(54)).foregroundStyle(.white).monospacedDigit()
                    Text("Songs aus dem GTA-VI-Soundtrack auf deinem iPhone")
                        .font(.viceBody(13)).foregroundStyle(.white.opacity(0.7))
                    ProgressView(value: library.totalTracks == 0 ? 0 : Double(library.totalMatched) / Double(library.totalTracks))
                        .tint(Vice.teal)
                    HStack {
                        Button {
                            library.rescan()
                        } label: {
                            Label(library.isScanning ? "Suche…" : "Neu einlesen", systemImage: "arrow.clockwise")
                        }
                        Spacer()
                        ShareLink(item: library.missingSongsText()) {
                            Label("Fehlende Songs teilen", systemImage: "square.and.arrow.up")
                        }
                    }
                    .font(.viceBody(14, weight: .bold))
                    .foregroundStyle(Vice.teal)
                    .padding(.top, 4)
                }
                .neonCard()

                VStack(alignment: .leading, spacing: 8) {
                    Text("SO KOMMEN DIE SONGS REIN").font(.vice(20)).foregroundStyle(.white)
                    instruction("1", "Öffne die Dateien-App › Auf meinem iPhone › ViceStation › Stations.")
                    instruction("2", "Jeder Sender hat einen eigenen Ordner. Kopiere die Songs hinein (mp3, m4a, wav, flac …). In jedem Ordner liegt eine _SONGLISTE.txt mit den empfohlenen Dateinamen.")
                    instruction("3", "Alternativ: Sender öffnen › „Songs importieren“.")
                    instruction("4", "Optional: Jingles, Werbung und DJ-Ansagen in den Unterordner _extras – sie laufen zufällig zwischen den Songs.")
                    instruction("5", "Eigenes Senderlogo: im Sender aufs Logo tippen oder logo.png in den Ordner legen.")
                    instruction("6", "Zurück in der App: „Neu einlesen“ tippen.")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .neonCard(Vice.teal)

                VStack(alignment: .leading, spacing: 12) {
                    Text("RADIO-EINSTELLUNGEN").font(.vice(20)).foregroundStyle(.white)
                    Toggle("Live einsteigen (Song läuft „schon“)", isOn: $player.liveTuneIn)
                    Toggle("Rauschen beim Senderwechsel", isOn: $player.staticEnabled)
                    VStack(alignment: .leading) {
                        Text("Jingles zwischen Songs: \(Int(player.extrasChance * 100)) %")
                        Slider(value: $player.extrasChance, in: 0...1, step: 0.05).tint(Vice.sunsetPink)
                    }
                    if library.vaultUnlocked {
                        Button("Geheimsender wieder verstecken", role: .destructive) { library.vaultUnlocked = false }
                    }
                }
                .font(.viceBody(15))
                .tint(Vice.sunsetPink)
                .foregroundStyle(.white)
                .neonCard(Vice.sunsetOrange)

                Text("Fan-Projekt ohne Verbindung zu Rockstar Games oder Take-Two. Musik wird nicht mitgeliefert – nutze nur Dateien, die du rechtmäßig besitzt.")
                    .font(.viceBody(11)).foregroundStyle(.white.opacity(0.5)).multilineTextAlignment(.center)
            }
            .padding()
            .padding(.bottom, 120)
        }
    }

    private func instruction(_ number: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(number).font(.vice(18)).foregroundStyle(Vice.sunsetPink).frame(width: 18)
            Text(text).font(.viceBody(14, weight: .regular)).foregroundStyle(.white.opacity(0.85))
        }
    }
}
