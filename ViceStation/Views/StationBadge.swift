import SwiftUI

/// Runder Sender-Button. Zeigt das eigene Logo (logo.png), sonst ein
/// generiertes Badge in den Senderfarben.
struct StationBadge: View {
    let station: Station
    let logo: UIImage?
    var size: CGFloat = 64
    var selected = false

    var body: some View {
        ZStack {
            if let logo {
                Image(uiImage: logo)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .background(Color.black)
                    .clipShape(Circle())
            } else {
                generated
            }
        }
        .overlay(
            Circle().strokeBorder(selected ? Vice.teal : .white.opacity(0.25), lineWidth: selected ? max(2, size * 0.05) : 1)
        )
        .shadow(color: selected ? Vice.teal.opacity(0.9) : station.primaryColor.opacity(0.4),
                radius: selected ? size * 0.2 : size * 0.06)
        .frame(width: size, height: size)
        .accessibilityLabel(station.name)
    }

    private var generated: some View {
        let textColor: Color = station.primaryColor.isLight ? .black : .white
        return ZStack {
            Circle().fill(LinearGradient(colors: [station.primaryColor, station.secondaryColor],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
            Circle()
                .strokeBorder(station.secondaryColor.opacity(0.9), lineWidth: size * 0.04)
                .padding(size * 0.08)
            Text(station.shortName.uppercased())
                .font(.vice(size * 0.2))
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .minimumScaleFactor(0.4)
                .foregroundStyle(textColor)
                .shadow(color: .black.opacity(textColor == .white ? 0.6 : 0), radius: 2, y: 1)
                .padding(size * 0.16)
        }
        .frame(width: size, height: size)
    }
}

/// „Aus“-Slot im Rad
struct OffBadge: View {
    var size: CGFloat = 64
    var selected = false
    var body: some View {
        ZStack {
            Circle().fill(Color.black.opacity(0.7))
            Image(systemName: "power")
                .font(.system(size: size * 0.36, weight: .bold))
                .foregroundStyle(selected ? Vice.teal : .white.opacity(0.7))
        }
        .overlay(Circle().strokeBorder(selected ? Vice.teal : .white.opacity(0.25), lineWidth: selected ? 3 : 1))
        .frame(width: size, height: size)
    }
}
