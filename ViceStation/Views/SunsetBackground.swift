import SwiftUI

/// Leonida-Sonnenuntergang: Himmelverlauf, Sonne, Meer mit Spiegelung und Palmen-Silhouetten.
struct SunsetBackground: View {
    var dimmed: Bool = true

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            ZStack {
                Vice.sky
                // Sonne
                Circle()
                    .fill(RadialGradient(colors: [Vice.sand, Vice.sunsetOrange, Vice.sunsetPink.opacity(0)],
                                         center: .center, startRadius: 0, endRadius: w * 0.45))
                    .frame(width: w * 0.9, height: w * 0.9)
                    .position(x: w * 0.5, y: h * 0.58)
                // Meer
                LinearGradient(colors: [Vice.teal.opacity(0.85), Color(hex: "#0B5E7A"), Vice.night],
                               startPoint: .top, endPoint: .bottom)
                    .frame(height: h * 0.36)
                    .overlay(alignment: .top) { WaterGlints().frame(height: h * 0.2) }
                    .position(x: w / 2, y: h * 0.82)
                // Palmen
                Palm()
                    .fill(Color.black.opacity(0.85))
                    .frame(width: w * 0.55, height: h * 0.62)
                    .position(x: w * 0.1, y: h * 0.62)
                Palm()
                    .fill(Color.black.opacity(0.8))
                    .frame(width: w * 0.42, height: h * 0.5)
                    .scaleEffect(x: -1)
                    .position(x: w * 0.92, y: h * 0.69)
                if dimmed {
                    LinearGradient(colors: [.black.opacity(0.15), .black.opacity(0.55), .black.opacity(0.85)],
                                   startPoint: .top, endPoint: .bottom)
                }
            }
        }
        .ignoresSafeArea()
    }
}

private struct WaterGlints: View {
    var body: some View {
        Canvas { ctx, size in
            var rng = SystemRandomNumberGenerator()
            for i in 0..<14 {
                let y = CGFloat(i) / 14 * size.height
                let width = size.width * (0.5 - CGFloat(i) * 0.03) * CGFloat.random(in: 0.7...1, using: &rng)
                let rect = CGRect(x: (size.width - width) / 2, y: y, width: max(width, 8), height: 2)
                ctx.fill(Path(roundedRect: rect, cornerRadius: 1), with: .color(Vice.sand.opacity(0.45 - Double(i) * 0.03)))
            }
        }
    }
}

/// Stilisierte Palme (Stamm + Wedel) als Shape.
struct Palm: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        let top = CGPoint(x: rect.minX + w * 0.62, y: rect.minY + h * 0.18)
        // Stamm (gebogen, unten breiter)
        p.move(to: CGPoint(x: rect.minX + w * 0.36, y: rect.maxY))
        p.addQuadCurve(to: CGPoint(x: top.x - 4, y: top.y), control: CGPoint(x: rect.minX + w * 0.30, y: rect.minY + h * 0.45))
        p.addLine(to: CGPoint(x: top.x + 4, y: top.y + 2))
        p.addQuadCurve(to: CGPoint(x: rect.minX + w * 0.46, y: rect.maxY), control: CGPoint(x: rect.minX + w * 0.40, y: rect.minY + h * 0.47))
        p.closeSubpath()
        // Wedel
        let fronds: [(angle: Double, length: CGFloat, droop: CGFloat)] = [
            (-170, 0.55, 0.30), (-140, 0.50, 0.22), (-105, 0.38, 0.10), (-70, 0.42, 0.12),
            (-35, 0.52, 0.22), (-5, 0.56, 0.32), (160, 0.40, 0.30), (25, 0.44, 0.34),
        ]
        for f in fronds {
            let rad = CGFloat(f.angle * .pi / 180)
            let len = w * f.length
            let tip = CGPoint(x: top.x + cos(rad) * len, y: top.y + sin(rad) * len + h * f.droop * 0.5)
            let ctrl = CGPoint(x: top.x + cos(rad) * len * 0.55, y: top.y + sin(rad) * len * 0.55 - h * 0.04)
            let normal = CGPoint(x: -sin(rad), y: cos(rad))
            let thick = w * 0.045
            p.move(to: top)
            p.addQuadCurve(to: tip, control: CGPoint(x: ctrl.x + normal.x * thick, y: ctrl.y + normal.y * thick))
            p.addQuadCurve(to: top, control: CGPoint(x: ctrl.x - normal.x * thick, y: ctrl.y - normal.y * thick))
        }
        return p
    }
}
