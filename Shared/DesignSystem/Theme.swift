import SwiftUI

// Tokens de couleur (section 5). Les valeurs clair/sombre vivent dans DesignSystem.xcassets.
// `bg` s'appelle `canvas` pour ne pas masquer le `.background` de SwiftUI.
extension ShapeStyle where Self == Color {
    static var canvas: Color { Color("Canvas") }
    static var surface: Color { Color("Surface") }
    static var surface2: Color { Color("Surface2") }
    static var line: Color { Color("Line") }
    static var ink: Color { Color("Ink") }
    static var ink2: Color { Color("Ink2") }
    static var ink3: Color { Color("Ink3") }
    static var accent: Color { Color("Accent") }
    static var accentSoft: Color { Color("AccentSoft") }
    static var accentInk: Color { Color("AccentInk") }
    static var sun: Color { Color("Sun") }
    static var ok: Color { Color("Ok") }
    static var okSoft: Color { Color("OkSoft") }
    static var edge: Color { Color("Edge") }
    static var edgeSoft: Color { Color("EdgeSoft") }
    static var over: Color { Color("Over") }
    static var overSoft: Color { Color("OverSoft") }
}

extension Color {
    /// Couleur sRGB depuis un entier 0xRRGGBB.
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}

enum Metrics {
    static let cardRadius: CGFloat = 20
    static let fieldRadius: CGFloat = 14
    static let tapSize: CGFloat = 62
    static let tapSizeAmount: CGFloat = 68
    static let gutter: CGFloat = 16
    static let sectionSpacing: CGFloat = 22
}

/// Ombre très légère teintée pervenche : `0 1 2 rgba(37,34,62,.05), 0 10 26 -12 rgba(60,55,140,.18)`.
struct SoftShadow: ViewModifier {
    @Environment(\.colorScheme) private var scheme

    func body(content: Content) -> some View {
        let dark = scheme == .dark
        content
            .shadow(color: dark ? .black.opacity(0.3) : Color(hex: 0x25223E, opacity: 0.05), radius: 1, y: 1)
            .shadow(color: dark ? .black.opacity(0.6) : Color(hex: 0x3C378C, opacity: 0.18), radius: 13, y: 10)
    }
}

extension View {
    func softShadow() -> some View { modifier(SoftShadow()) }

    /// Fond de carte : surface, rayon 20, ombre douce.
    func cardStyle() -> some View {
        background(.surface, in: RoundedRectangle(cornerRadius: Metrics.cardRadius, style: .continuous))
            .softShadow()
    }
}
