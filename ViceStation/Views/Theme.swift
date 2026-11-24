import SwiftUI

/// Farbwelt angelehnt an Vice City / Leonida: Sonnenuntergang (Orange → Pink → Violett),
/// türkises Meer und Neon-Akzente.
enum Vice {
    static let sunsetOrange = Color(hex: "#FF8A3D")
    static let sunsetPink = Color(hex: "#FF3D8B")
    static let magenta = Color(hex: "#D62F9E")
    static let violet = Color(hex: "#5B2A86")
    static let night = Color(hex: "#120A24")
    static let teal = Color(hex: "#19E3D3")
    static let sand = Color(hex: "#FFE3B3")

    static let sky = LinearGradient(colors: [violet, magenta, sunsetPink, sunsetOrange, sand.opacity(0.9)],
                                    startPoint: .top, endPoint: .bottom)
    static let logo = LinearGradient(colors: [sunsetOrange, sunsetPink, Color(hex: "#B44BFF")],
                                     startPoint: .topLeading, endPoint: .bottomTrailing)
    static let card = Color.black.opacity(0.35)
}

extension Font {
    /// Fette, schmale, kursive Headline-Schrift
    static func vice(_ size: CGFloat, weight: Font.Weight = .black) -> Font {
        .system(size: size, weight: weight).width(.condensed).italic()
    }
    static func viceBody(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight).width(.condensed)
    }
}

extension Color {
    init(hex: String) {
        var value: UInt64 = 0
        Scanner(string: hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))).scanHexInt64(&value)
        self.init(red: Double((value >> 16) & 0xFF) / 255,
                  green: Double((value >> 8) & 0xFF) / 255,
                  blue: Double(value & 0xFF) / 255)
    }

    var isLight: Bool {
        let ui = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        ui.getRed(&r, green: &g, blue: &b, alpha: &a)
        return (0.299 * r + 0.587 * g + 0.114 * b) > 0.6
    }
}

extension Station {
    var primaryColor: Color { Color(hex: colors.first ?? "#FF3D8B") }
    var secondaryColor: Color { Color(hex: colors.dropFirst().first ?? "#19E3D3") }
}

/// „VICESTATION“-Schriftzug im Stil eines Sonnenuntergang-Logos.
struct ViceLogo: View {
    var size: CGFloat = 34
    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 2) {
            Text("VICE")
                .font(.vice(size))
                .foregroundStyle(Vice.logo)
            Text("STATION")
                .font(.vice(size * 0.62, weight: .heavy))
                .foregroundStyle(.white)
        }
        .shadow(color: Vice.sunsetPink.opacity(0.8), radius: 10)
    }
}

/// Neon-Rahmen für Karten
struct NeonCard: ViewModifier {
    var tint: Color = Vice.sunsetPink
    func body(content: Content) -> some View {
        content
            .padding(14)
            .background(.ultraThinMaterial.opacity(0.6), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .background(Vice.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(LinearGradient(colors: [tint, Vice.teal.opacity(0.6)],
                                                 startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
            )
    }
}

extension View {
    func neonCard(_ tint: Color = Vice.sunsetPink) -> some View { modifier(NeonCard(tint: tint)) }
}
