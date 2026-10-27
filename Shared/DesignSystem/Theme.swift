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

/// Ombre portée chaude, en deux couches : une proche et nette, une large et diffuse.
struct SoftShadow: ViewModifier {
    var lifted = true
    @Environment(\.colorScheme) private var scheme

    func body(content: Content) -> some View {
        let dark = scheme == .dark
        content
            .shadow(color: dark ? .black.opacity(0.35) : Color(hex: 0x7A5040, opacity: 0.1),
                    radius: lifted ? 3 : 2, y: lifted ? 3 : 2)
            .shadow(color: dark ? .black.opacity(0.55) : Color(hex: 0x8A5E4E, opacity: lifted ? 0.24 : 0.2),
                    radius: lifted ? 22 : 8, y: lifted ? 16 : 6)
    }
}

/// Teintes du relief « argile » : reflet clair en haut à gauche, ombre chaude en bas à droite.
private struct ClayLight {
    let highlight: Color
    let shade: Color

    init(_ scheme: ColorScheme) {
        highlight = scheme == .dark ? .white.opacity(0.13) : .white.opacity(0.95)
        shade = scheme == .dark ? .black.opacity(0.5) : Color(hex: 0x9C6F5C, opacity: 0.3)
    }
}

extension Color {
    /// Mélange opaque de deux couleurs, résolues pour le mode clair ou sombre courant.
    func mixed(with other: Color, amount: Double, in environment: EnvironmentValues) -> Color {
        let a = resolve(in: environment), b = other.resolve(in: environment)
        let t = Float(min(1, max(0, amount)))
        return Color(Color.Resolved(red: a.red + (b.red - a.red) * t,
                                    green: a.green + (b.green - a.green) * t,
                                    blue: a.blue + (b.blue - a.blue) * t))
    }
}

/// Surface en relief « argile » : bombée, avec un liseré lumineux en haut, une ombre interne en bas
/// et une ombre portée chaude.
struct ClaySurface<S: InsettableShape>: ViewModifier {
    let shape: S
    var fill: Color = .surface
    @Environment(\.colorScheme) private var scheme

    func body(content: Content) -> some View {
        let light = ClayLight(scheme)
        content
            .background {
                shape
                    .fill(
                        LinearGradient(colors: [.surfaceHigh, fill], startPoint: .top, endPoint: .bottom)
                            .shadow(.inner(color: light.highlight, radius: 2, x: 2, y: 3))
                            .shadow(.inner(color: light.shade, radius: 12, x: -3, y: -8))
                    )
                    .modifier(SoftShadow())
            }
    }
}

/// Galet : forme gonflée comme de l'argile, avec un reflet brillant, utilisée pour les boutons.
struct Pebble<S: InsettableShape>: View {
    let shape: S
    var base: Color = .surface
    var tint: Color? = nil
    var tintOpacity: Double = 0.4
    var lifted = true
    @Environment(\.colorScheme) private var scheme
    @Environment(\.self) private var environment

    var body: some View {
        let light = ClayLight(scheme)
        let color = tint.map { base.mixed(with: $0, amount: tintOpacity, in: environment) } ?? base
        ZStack {
            shape.fill(
                color
                    .shadow(.inner(color: light.highlight, radius: 3, x: 3, y: 4))
                    .shadow(.inner(color: light.shade, radius: lifted ? 7 : 5, x: -3, y: -5))
            )
            // Reflet brillant, comme une lumière venant d'en haut à gauche.
            shape.fill(EllipticalGradient(
                colors: [.white.opacity(scheme == .dark ? 0.16 : 0.6), .white.opacity(0)],
                center: UnitPoint(x: 0.32, y: 0.22), startRadiusFraction: 0, endRadiusFraction: 0.55
            ))
            .allowsHitTesting(false)
        }
        .modifier(SoftShadow(lifted: lifted))
    }
}

/// Creux : forme enfoncée dans l'argile (pastilles, cases, pistes de progression).
struct Well<S: Shape>: View {
    let shape: S
    var color: Color = .surface2
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let light = ClayLight(scheme)
        shape.fill(
            color
                .shadow(.inner(color: light.shade.opacity(scheme == .dark ? 0.9 : 0.75), radius: 2.5, x: 1.5, y: 2))
                .shadow(.inner(color: light.highlight.opacity(0.8), radius: 1.5, x: -1, y: -1.5))
        )
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
