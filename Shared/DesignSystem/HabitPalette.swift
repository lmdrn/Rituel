import SwiftUI

/// Palette des habitudes (16 teintes). La clé est stockée dans `Habit.colorKey`.
enum HabitColor: String, CaseIterable, Identifiable, Sendable {
    case citron, soleil, mandarine, tomate
    case pivoine, lilas, violet, pervenche
    case bleu, ciel, lagon, menthe
    case pomme, sable, ardoise, encre

    var id: String { rawValue }

    var name: String {
        switch self {
        case .citron: "Citron"
        case .soleil: "Soleil"
        case .mandarine: "Mandarine"
        case .tomate: "Tomate"
        case .pivoine: "Pivoine"
        case .lilas: "Lilas"
        case .violet: "Violet"
        case .pervenche: "Pervenche"
        case .bleu: "Bleu"
        case .ciel: "Ciel"
        case .lagon: "Lagon"
        case .menthe: "Menthe"
        case .pomme: "Pomme"
        case .sable: "Sable"
        case .ardoise: "Ardoise"
        case .encre: "Encre"
        }
    }

    /// Versions pastel des 16 teintes du brief, accordées au thème (voir DECISIONS.md).
    var hex: UInt32 {
        switch self {
        case .citron: 0xEFD77A
        case .soleil: 0xF2C26B
        case .mandarine: 0xF0A47A
        case .tomate: 0xE58A7A
        case .pivoine: 0xEBA3BE
        case .lilas: 0xC3B2E8
        case .violet: 0x9E8FD6
        case .pervenche: 0x9DAEE3
        case .bleu: 0x7F9FD6
        case .ciel: 0x9CCBE6
        case .lagon: 0x7CC3BC
        case .menthe: 0x8CCFAE
        case .pomme: 0xB9D98C
        case .sable: 0xD9C6A5
        case .ardoise: 0x9AA0AE
        case .encre: 0x5A5560
        }
    }

    var color: Color { Color(hex: hex) }

    /// Anciennes clés de la version web, et repli sur menthe pour une clé inconnue.
    init(key: String) {
        let legacy = ["sauge": "menthe", "brume": "pervenche", "lavande": "lilas", "abricot": "mandarine", "mousse": "citron"]
        self = HabitColor(rawValue: legacy[key] ?? key) ?? .menthe
    }
}
