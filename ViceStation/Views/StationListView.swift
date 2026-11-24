import SwiftUI

struct StationListView: View {
    @Environment(StationLibrary.self) private var library
    @Environment(RadioPlayer.self) private var player

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(library.stations) { station in
                    if station.secret && !library.vaultUnlocked {
                        lockedRow
                    } else {
                        NavigationLink(value: station) { row(station) }
                            .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 120)
        }
        .navigationDestination(for: Station.self) { StationDetailView(station: $0) }
    }

    private func row(_ station: Station) -> some View {
        let content = library.content(for: station)
        let fraction = station.tracks.isEmpty ? 0 : Double(content.matched.count) / Double(station.tracks.count)
        return HStack(spacing: 14) {
            StationBadge(station: station, logo: library.logos[station.id], size: 58,
                         selected: player.currentStation?.id == station.id)
            VStack(alignment: .leading, spacing: 4) {
                Text(station.name.uppercased()).font(.vice(20)).foregroundStyle(.white)
                Text("\(station.genre) · \(station.hosts)")
                    .font(.viceBody(12)).foregroundStyle(.white.opacity(0.65)).lineLimit(1)
                ProgressView(value: fraction).tint(fraction >= 1 ? Vice.teal : Vice.sunsetPink)
                Text("\(content.matched.count)/\(station.tracks.count) Songs"
                     + (content.songs.count > content.matched.count ? " · +\(content.songs.count - content.matched.count) eigene" : ""))
                    .font(.viceBody(11)).foregroundStyle(.white.opacity(0.6))
            }
            Spacer()
            Button { player.tune(to: station) } label: {
                Image(systemName: player.currentStation?.id == station.id && player.isPlaying ? "waveform" : "play.circle.fill")
                    .font(.title)
                    .foregroundStyle(Vice.logo)
                    .symbolEffect(.variableColor.iterative, isActive: player.currentStation?.id == station.id && player.isPlaying)
            }
            .buttonStyle(.plain)
        }
        .neonCard(station.primaryColor)
    }

    private var lockedRow: some View {
        HStack(spacing: 14) {
            Circle().fill(Color.black.opacity(0.6)).frame(width: 58, height: 58)
                .overlay(Image(systemName: "lock.fill").foregroundStyle(.white.opacity(0.6)))
            VStack(alignment: .leading, spacing: 4) {
                Text("??? GEHEIMSENDER").font(.vice(20)).foregroundStyle(.white.opacity(0.7))
                Text("Tipp: Das ViceStation-Logo kennt ein Geheimnis…")
                    .font(.viceBody(12)).foregroundStyle(.white.opacity(0.5))
            }
            Spacer()
        }
        .neonCard(.gray)
    }
}
