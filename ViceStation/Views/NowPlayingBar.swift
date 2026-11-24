import SwiftUI

struct NowPlayingBar: View {
    @Environment(StationLibrary.self) private var library
    @Environment(RadioPlayer.self) private var player

    var body: some View {
        HStack(spacing: 12) {
            if let station = player.currentStation {
                StationBadge(station: station, logo: library.logos[station.id], size: 46)
                VStack(alignment: .leading, spacing: 2) {
                    Text(player.currentItem?.title ?? (library.content(for: station).isPlayable ? "Einschalten…" : "Keine Songs vorhanden"))
                        .font(.viceBody(16, weight: .bold))
                        .lineLimit(1)
                    Text(player.currentItem.map { $0.kind == .extra ? station.name : $0.artist } ?? station.name)
                        .font(.viceBody(13))
                        .foregroundStyle(Vice.teal)
                        .lineLimit(1)
                    ProgressView(value: player.progress)
                        .tint(Vice.sunsetPink)
                        .scaleEffect(x: 1, y: 0.6)
                }
                Spacer(minLength: 4)
                Button { player.nextStation(-1) } label: { Image(systemName: "backward.fill") }
                Button { player.togglePlayPause() } label: {
                    Image(systemName: player.isPlaying ? "pause.fill" : "play.fill").font(.title2)
                }
                Button { player.nextStation(1) } label: { Image(systemName: "forward.fill") }
            } else {
                Image(systemName: "dot.radiowaves.left.and.right")
                    .font(.title2)
                    .foregroundStyle(Vice.logo)
                Text("Kein Sender eingeschaltet")
                    .font(.viceBody(15))
                    .foregroundStyle(.white.opacity(0.7))
                Spacer()
            }
        }
        .buttonStyle(.plain)
        .foregroundStyle(.white)
        .neonCard()
    }
}
