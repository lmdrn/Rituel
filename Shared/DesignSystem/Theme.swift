import SwiftUI

// Tokens de couleur du thème « Marguerite », version native : fond groupé iOS, accents du logo.
// Les valeurs clair/sombre vivent dans DesignSystem.xcassets.
// `bg` s'appelle `canvas` pour ne pas masquer le `.background` de SwiftUI.
extension ShapeStyle where Self == Color {
    static var canvas: Color { Color("Canvas") }
    static var surface: Color { Color("Surface") }
    /// Pétales vides, emplacements du graphique.
    static var surface2: Color { Color("Surface2") }
    static var line: Color { Color("Line") }
    static var ink: Color { Color("Ink") }
    static var ink2: Color { Color("Ink2") }
    static var ink3: Color { Color("Ink3") }
    /// Le pervenche du logo : boutons pleins, sélection.
    static var accent: Color { Color("Accent") }
    static var accentSoft: Color { Color("AccentSoft") }
    static var accentInk: Color { Color("AccentInk") }
    /// Pervenche lisible pour du texte.
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
}

enum Metrics {
    static let cardRadius: CGFloat = 22
    static let gutter: CGFloat = 16
    static let sectionSpacing: CGFloat = 24
    static let buttonHeight: CGFloat = 44
}

extension StatusTone {
    /// Couleur du texte de statut, toujours accompagné d'un symbole (jamais la couleur seule).
    var color: Color {
        switch self {
        case .ok: .ok
        case .done: .sunText
        case .edge: .edge
        case .over: .over
        case .progress: .accentText
        }
    }

    var symbol: String? {
        switch self {
        case .done: "checkmark"
        case .edge: "equal"
        case .over: "exclamationmark"
        case .ok, .progress: nil
        }
    }
}

extension View {
    /// Carte de liste groupée iOS : surface, rayon 22, sans ombre.
    func cardStyle() -> some View {
        background(.surface, in: RoundedRectangle(cornerRadius: Metrics.cardRadius, style: .continuous))
    }
}

/// Bouton plein en capsule (pervenche) ou doux (lavande), à la hauteur tactile iOS.
struct CapsuleButtonStyle: ButtonStyle {
    var prominent = true
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.rituel(.bold, size: 15, relativeTo: .body))
            .foregroundStyle(prominent ? Color.accentInk : Color.accentText)
            .frame(minHeight: Metrics.buttonHeight)
            .padding(.horizontal, 14)
            .background(prominent ? Color.accent : Color.accentSoft, in: Capsule())
            .opacity(isEnabled ? (configuration.isPressed ? 0.75 : 1) : 0.4)
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
            .contentShape(Capsule())
    }
}
