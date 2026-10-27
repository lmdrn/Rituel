import SwiftUI

// Tokens de couleur du thème « Marguerite ». Les valeurs clair/sombre vivent dans DesignSystem.xcassets.
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
    /// Le pervenche du logo : fonds des éléments actifs, avec `accentInk` par-dessus.
    static var accent: Color { Color("Accent") }
    static var accentSoft: Color { Color("AccentSoft") }
    static var accentInk: Color { Color("AccentInk") }
    /// Pervenche lisible pour du texte sur fond clair ou doux.
    static var accentText: Color { Color("AccentText") }
    /// Le cœur soleil du logo.
    static var sun: Color { Color("Sun") }
    static var sunText: Color { Color("SunText") }
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

    /// Pervenche exact du logo, identique dans les deux modes.
    static let brand = Color(hex: 0x4B4BF0)

    /// Mélange opaque de deux couleurs, résolues pour le mode clair ou sombre courant.
    func mixed(with other: Color, amount: Double, in environment: EnvironmentValues) -> Color {
        let a = resolve(in: environment), b = other.resolve(in: environment)
        let t = Float(min(1, max(0, amount)))
        return Color(Color.Resolved(red: a.red + (b.red - a.red) * t,
                                    green: a.green + (b.green - a.green) * t,
                                    blue: a.blue + (b.blue - a.blue) * t))
    }
}

enum Metrics {
    static let cardRadius: CGFloat = 28
    static let fieldRadius: CGFloat = 16
    static let tapSize: CGFloat = 78
    static let gutter: CGFloat = 16
    static let sectionSpacing: CGFloat = 22
}

/// Ombre portée teintée pervenche : une couche proche et nette, une large et diffuse.
struct SoftShadow: ViewModifier {
    var lifted = true
    /// Couleur de l'ombre large ; par défaut le pervenche, sinon la couleur de l'élément (effet « gelée »).
    var glow: Color? = nil
    @Environment(\.colorScheme) private var scheme

    func body(content: Content) -> some View {
        let dark = scheme == .dark
        content
            .shadow(color: dark ? .black.opacity(0.35) : Color(hex: 0x1C1B4A, opacity: 0.06), radius: lifted ? 2 : 1, y: 1)
            .shadow(color: (glow ?? (dark ? .black : .brand)).opacity(dark ? 0.5 : (glow == nil ? 0.13 : 0.35)),
                    radius: lifted ? 18 : 7, y: lifted ? 10 : 4)
    }
}

/// Lumière commune : reflet clair en haut, ombre douce en bas.
private struct Light {
    let highlight: Color
    let shade: Color

    init(_ scheme: ColorScheme) {
        highlight = scheme == .dark ? .white.opacity(0.12) : .white
        shade = scheme == .dark ? .black.opacity(0.45) : Color(hex: 0x3A3AB0, opacity: 0.12)
    }
}

/// Surface en relief : léger dégradé vertical, liseré lumineux en haut, ombre teintée pervenche.
struct RaisedSurface<S: InsettableShape>: ViewModifier {
    let shape: S
    var fill: Color = .surface
    @Environment(\.colorScheme) private var scheme

    func body(content: Content) -> some View {
        let light = Light(scheme)
        content
            .background {
                shape
                    .fill(
                        LinearGradient(colors: [.surfaceHigh, fill], startPoint: .top, endPoint: .bottom)
                            .shadow(.inner(color: light.highlight, radius: 1, x: 0, y: 1.5))
                            .shadow(.inner(color: light.shade, radius: 10, x: 0, y: -5))
                    )
                    .modifier(SoftShadow())
            }
    }
}

/// Bouton « gelée » : forme bombée et brillante, avec une ombre de sa propre couleur.
struct Pebble<S: InsettableShape>: View {
    let shape: S
    var base: Color = .surface
    var tint: Color? = nil
    var tintOpacity: Double = 0.4
    var lifted = true
    /// L'ombre prend la couleur du bouton (pour les boutons pleins, pervenche ou couleur d'habitude).
    var glows = false
    @Environment(\.colorScheme) private var scheme
    @Environment(\.self) private var environment

    var body: some View {
        let light = Light(scheme)
        let color = tint.map { base.mixed(with: $0, amount: tintOpacity, in: environment) } ?? base
        ZStack {
            shape.fill(
                LinearGradient(colors: [color.mixed(with: .white, amount: scheme == .dark ? 0.08 : 0.18, in: environment), color],
                               startPoint: .top, endPoint: .bottom)
                    .shadow(.inner(color: light.highlight.opacity(0.9), radius: 1.5, x: 0, y: 2))
                    .shadow(.inner(color: light.shade, radius: 5, x: 0, y: -3))
            )
            // Reflet brillant en haut, comme une goutte.
            shape.fill(LinearGradient(colors: [.white.opacity(scheme == .dark ? 0.12 : 0.35), .white.opacity(0)],
                                      startPoint: .top, endPoint: .center))
                .padding(2)
                .allowsHitTesting(false)
        }
        .modifier(SoftShadow(lifted: lifted, glow: glows ? color : nil))
    }
}

/// Creux : forme légèrement enfoncée (pastilles, cases, pistes de progression, champs).
struct Well<S: Shape>: View {
    let shape: S
    var color: Color = .surface2
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let light = Light(scheme)
        shape.fill(
            color
                .shadow(.inner(color: light.shade.opacity(scheme == .dark ? 1 : 1.4), radius: 2, x: 0, y: 1.5))
                .shadow(.inner(color: light.highlight.opacity(0.7), radius: 1, x: 0, y: -1))
        )
    }
}

extension View {
    func softShadow() -> some View { modifier(SoftShadow()) }

    /// Fond de carte : relief doux, rayon 28.
    func cardStyle() -> some View {
        modifier(RaisedSurface(shape: RoundedRectangle(cornerRadius: Metrics.cardRadius, style: .continuous)))
    }

    func raisedSurface<S: InsettableShape>(_ shape: S, fill: Color = .surface) -> some View {
        modifier(RaisedSurface(shape: shape, fill: fill))
    }
}
