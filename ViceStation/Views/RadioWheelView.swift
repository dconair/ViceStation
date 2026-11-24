import SwiftUI

/// Das Radio-Rad wie im Spiel: Sender kreisförmig angeordnet, Mitte zeigt
/// Sender + laufenden Song. Antippen oder mit dem Finger um das Rad fahren.
struct RadioWheelView: View {
    @Environment(StationLibrary.self) private var library
    @Environment(RadioPlayer.self) private var player
    @State private var hoveredIndex: Int?
    @State private var detailStation: Station?

    var body: some View {
        let stations = library.visibleStations
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let count = stations.count + 1 // + „Aus“
            let radius = side * 0.40
            let badge = min(side * 0.15, (2 * .pi * radius / CGFloat(count)) * 0.86)
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)

            ZStack {
                // Ring
                Circle()
                    .stroke(Color.black.opacity(0.45), lineWidth: badge * 1.25)
                    .frame(width: radius * 2, height: radius * 2)
                Circle()
                    .stroke(LinearGradient(colors: [Vice.sunsetPink, Vice.teal], startPoint: .top, endPoint: .bottom).opacity(0.5),
                            lineWidth: 1)
                    .frame(width: radius * 2 + badge * 1.25, height: radius * 2 + badge * 1.25)

                centerInfo(stations: stations, hovered: hoveredIndex)
                    .frame(width: radius * 1.35)
                    .position(center)

                ForEach(0..<count, id: \.self) { index in
                    let pos = point(index: index, count: count, radius: radius, center: center)
                    let station = index == 0 ? nil : stations[index - 1]
                    let isCurrent = station?.id == player.currentStation?.id && (station != nil || player.currentStation == nil)
                    let isHovered = hoveredIndex == index
                    Group {
                        if let station {
                            StationBadge(station: station, logo: library.logos[station.id], size: badge,
                                         selected: isCurrent || isHovered)
                                .opacity(library.content(for: station).isPlayable ? 1 : 0.45)
                        } else {
                            OffBadge(size: badge, selected: isCurrent || isHovered)
                        }
                    }
                    .scaleEffect(isHovered ? 1.22 : (isCurrent ? 1.1 : 1))
                    .animation(.spring(response: 0.25, dampingFraction: 0.6), value: isHovered)
                    .position(pos)
                    .onTapGesture { player.tune(to: station) }
                    .onLongPressGesture { if let station { detailStation = station } }
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 8)
                    .onChanged { value in
                        let idx = index(at: value.location, center: center, count: count, radius: radius)
                        if idx != hoveredIndex {
                            hoveredIndex = idx
                            if idx != nil { UISelectionFeedbackGenerator().selectionChanged() }
                        }
                    }
                    .onEnded { _ in
                        if let idx = hoveredIndex { player.tune(to: idx == 0 ? nil : stations[idx - 1]) }
                        hoveredIndex = nil
                    }
            )
        }
        .aspectRatio(1, contentMode: .fit)
        .sheet(item: $detailStation) { station in
            NavigationStack { StationDetailView(station: station) }
        }
    }

    @ViewBuilder
    private func centerInfo(stations: [Station], hovered: Int?) -> some View {
        let shown: Station? = {
            if let hovered { return hovered == 0 ? nil : stations[hovered - 1] }
            return player.currentStation
        }()
        VStack(spacing: 6) {
            if let shown {
                Text(shown.name.uppercased())
                    .font(.vice(26))
                    .foregroundStyle(Vice.logo)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.5)
                Text(shown.genre)
                    .font(.viceBody(13))
                    .foregroundStyle(.white.opacity(0.7))
                if hovered == nil, let item = player.currentItem {
                    Divider().overlay(Vice.teal.opacity(0.5)).padding(.horizontal, 20)
                    Text(item.title)
                        .font(.viceBody(16, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                    Text(item.kind == .extra ? "On Air" : item.artist)
                        .font(.viceBody(13))
                        .foregroundStyle(Vice.teal)
                        .lineLimit(1)
                } else if !library.content(for: shown).isPlayable {
                    Text("Noch keine Songs – lange drücken zum Befüllen")
                        .font(.viceBody(12))
                        .foregroundStyle(Vice.sunsetOrange)
                        .multilineTextAlignment(.center)
                }
            } else {
                Text("RADIO AUS")
                    .font(.vice(26))
                    .foregroundStyle(.white.opacity(0.8))
                Text("Sender antippen oder übers Rad wischen")
                    .font(.viceBody(12))
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
        }
        .animation(.easeOut(duration: 0.15), value: shown?.id)
    }

    private func angle(index: Int, count: Int) -> Double {
        -Double.pi / 2 + Double(index) / Double(count) * 2 * .pi
    }

    private func point(index: Int, count: Int, radius: CGFloat, center: CGPoint) -> CGPoint {
        let a = CGFloat(angle(index: index, count: count))
        return CGPoint(x: center.x + CoreGraphics.cos(a) * radius, y: center.y + CoreGraphics.sin(a) * radius)
    }

    private func index(at location: CGPoint, center: CGPoint, count: Int, radius: CGFloat) -> Int? {
        let dx = location.x - center.x, dy = location.y - center.y
        guard hypot(dx, dy) > radius * 0.35 else { return nil }
        var a = Double(atan2(dy, dx)) + .pi / 2
        if a < 0 { a += 2 * .pi }
        let step = 2 * Double.pi / Double(count)
        return Int((a + step / 2) / step) % count
    }
}
