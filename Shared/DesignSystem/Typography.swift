import SwiftUI

// Fraunces (SOFT 100) pour les titres, Figtree pour le texte.
// Les fichiers sont des instances statiques des polices variables (voir DECISIONS.md).
enum RituelFontFace: String {
    case display = "FrauncesSoft-Display"   // 400, opsz 72 : titres
    case displayText = "FrauncesSoft-Text"  // 400, opsz 24 : petits titres, citations
    case displayLight = "FrauncesSoft-Light" // 300, opsz 144 : grand chiffre du score
    case regular = "Figtree-Regular"
    case semibold = "Figtree-SemiBold"
    case bold = "Figtree-Bold"
}

extension Font {
    /// Police Rituel qui suit le Dynamic Type à partir du style de référence.
    static func rituel(_ face: RituelFontFace, size: CGFloat, relativeTo style: Font.TextStyle = .body) -> Font {
        .custom(face.rawValue, size: size, relativeTo: style)
    }

    static let rituelLargeTitle = rituel(.display, size: 34, relativeTo: .largeTitle)
    static let rituelTitle = rituel(.display, size: 22, relativeTo: .title2)
    static let rituelBrand = rituel(.displayText, size: 19, relativeTo: .title3)
    static let rituelNote = rituel(.displayText, size: 17, relativeTo: .body)
    static let rituelScore = rituel(.displayLight, size: 64, relativeTo: .largeTitle)

    static let rituelBody = rituel(.regular, size: 15, relativeTo: .body)
    static let rituelBodyStrong = rituel(.semibold, size: 15, relativeTo: .body)
    static let rituelHeadline = rituel(.semibold, size: 16, relativeTo: .headline)
    static let rituelCallout = rituel(.regular, size: 13, relativeTo: .subheadline)
    static let rituelChip = rituel(.semibold, size: 12, relativeTo: .caption)
    static let rituelEyebrow = rituel(.semibold, size: 12, relativeTo: .caption)
    static let rituelSmall = rituel(.regular, size: 11, relativeTo: .caption2)
}

extension Text {
    /// Surtitre : petites capitales espacées, encre 3.
    func eyebrow() -> some View {
        self.font(.rituelEyebrow)
            .textCase(.uppercase)
            .tracking(12 * 0.08)
            .foregroundStyle(.ink3)
    }
}
