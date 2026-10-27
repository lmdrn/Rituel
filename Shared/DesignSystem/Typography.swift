import SwiftUI

// Outfit (géométrique, proche du logotype) pour les titres et les chiffres, Figtree pour le texte.
// Les fichiers sont des instances statiques des polices variables (voir DESIGN_SYSTEM.md).
enum RituelFontFace: String {
    case title = "Outfit-Bold"
    case titleMedium = "Outfit-Medium"
    case regular = "Figtree-Regular"
    case semibold = "Figtree-SemiBold"
    case bold = "Figtree-Bold"
}

extension Font {
    /// Police Rituel qui suit le Dynamic Type à partir du style de référence.
    static func rituel(_ face: RituelFontFace, size: CGFloat, relativeTo style: Font.TextStyle = .body) -> Font {
        .custom(face.rawValue, size: size, relativeTo: style)
    }

    static let rituelLargeTitle = rituel(.title, size: 36, relativeTo: .largeTitle)
    static let rituelTitle = rituel(.title, size: 22, relativeTo: .title2)
    static let rituelCardTitle = rituel(.title, size: 20, relativeTo: .title3)
    static let rituelBrand = rituel(.title, size: 20, relativeTo: .title3)
    static let rituelNote = rituel(.titleMedium, size: 17, relativeTo: .body)
    static let rituelScore = rituel(.title, size: 64, relativeTo: .largeTitle)

    static let rituelBody = rituel(.regular, size: 15, relativeTo: .body)
    static let rituelBodyStrong = rituel(.semibold, size: 15, relativeTo: .body)
    static let rituelHeadline = rituel(.semibold, size: 16, relativeTo: .headline)
    static let rituelCallout = rituel(.regular, size: 13, relativeTo: .subheadline)
    static let rituelChip = rituel(.bold, size: 12, relativeTo: .caption)
    static let rituelEyebrow = rituel(.bold, size: 12, relativeTo: .caption)
    static let rituelSmall = rituel(.regular, size: 11, relativeTo: .caption2)
}

extension Text {
    /// Surtitre : petites capitales espacées.
    func eyebrow(_ color: Color = .ink3) -> some View {
        self.font(.rituelEyebrow)
            .textCase(.uppercase)
            .tracking(12 * 0.08)
            .foregroundStyle(color)
    }
}
