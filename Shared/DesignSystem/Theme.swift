import SwiftUI

// Tokens de couleur du thème pastel. Les valeurs clair/sombre vivent dans DesignSystem.xcassets.
// `bg` s'appelle `canvas` pour ne pas masquer le `.background` de SwiftUI.
extension ShapeStyle where Self == Color {
    static var canvas: Color { Color("Canvas") }
    static var surface: Color { Color("Surface") }
    /// Haut des surfaces en relief, un peu plus clair.
    static var surfaceHigh: Color { Color("SurfaceHigh") }
    static var surface2: Color { Color("Surface2") }
    static var line: Color { Color("Line") }
    static var ink: Color { Color("Ink") }
    static var ink2: Color { Color("Ink2") }
    static var ink3: Color { Color("Ink3") }
    /// Pêche : fonds des éléments actifs, avec `accentInk` par-dessus.
    static var accent: Color { Color("Accent") }
    static var accentSoft: Color { Color("AccentSoft") }
    static var accentInk: Color { Color("AccentInk") }
    /// Terracotta lisible pour du texte accentué sur fond clair.
    static var accentText: Color { Color("AccentText") }
    static var sun: Color { Color("Sun") }
    /// Bleu brumeux et rose poudré des formes organiques.
    static var mist: Color { Color("Mist") }
    static var blush: Color { Color("Blush") }
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

/// Ombre douce et chaude, très diffuse.
struct SoftShadow: ViewModifier {
    var lifted = true
    @Environment(\.colorScheme) private var scheme

    func body(content: Content) -> some View {
        let dark = scheme == .dark
        content
            .shadow(color: dark ? .black.opacity(0.3) : Color(hex: 0x6B4A3F, opacity: 0.06), radius: 1, y: 1)
            .shadow(color: dark ? .black.opacity(0.45) : Color(hex: 0x8A5E4E, opacity: lifted ? 0.16 : 0.1),
                    radius: lifted ? 16 : 6, y: lifted ? 12 : 4)
    }
}

/// Surface en relief doux : dégradé vertical, liseré lumineux en haut, ombre chaude.
struct ClaySurface<S: InsettableShape>: ViewModifier {
    let shape: S
    var fill: Color = .surface
    @Environment(\.colorScheme) private var scheme

    func body(content: Content) -> some View {
        content
            .background {
                ZStack {
                    shape.fill(LinearGradient(colors: [.surfaceHigh, fill], startPoint: .top, endPoint: .bottom))
                    shape.strokeBorder(
                        LinearGradient(colors: [.white.opacity(scheme == .dark ? 0.08 : 0.9), .white.opacity(0)],
                                       startPoint: .top, endPoint: .center),
                        lineWidth: 1
                    )
                }
            }
            .modifier(SoftShadow())
    }
}

/// Galet : forme bombée avec reflet en haut à gauche, utilisée pour les boutons.
struct Pebble<S: InsettableShape>: View {
    let shape: S
    var base: Color = .surface
    var tint: Color? = nil
    var tintOpacity: Double = 0.4
    var lifted = true
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let dark = scheme == .dark
        ZStack {
            shape.fill(base)
            if let tint { shape.fill(tint.opacity(tintOpacity)) }
            shape.fill(LinearGradient(
                colors: [.white.opacity(dark ? 0.12 : 0.55), .white.opacity(0), .black.opacity(dark ? 0.18 : 0.05)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            ))
            shape.strokeBorder(
                LinearGradient(colors: [.white.opacity(dark ? 0.15 : 0.85), .white.opacity(0)],
                               startPoint: .topLeading, endPoint: .center),
                lineWidth: 1
            )
        }
        .modifier(SoftShadow(lifted: lifted))
    }
}

extension View {
    func softShadow() -> some View { modifier(SoftShadow()) }

    /// Fond de carte : relief doux, rayon 20.
    func cardStyle() -> some View {
        modifier(ClaySurface(shape: RoundedRectangle(cornerRadius: Metrics.cardRadius, style: .continuous)))
    }

    func claySurface<S: InsettableShape>(_ shape: S, fill: Color = .surface) -> some View {
        modifier(ClaySurface(shape: shape, fill: fill))
    }
}
