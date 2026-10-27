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

    var hex: UInt32 {
        switch self {
        case .citron: 0xF7DC4A
        case .soleil: 0xFFB627
        case .mandarine: 0xFF8A3D
        case .tomate: 0xF2553D
        case .pivoine: 0xFF7AB6
        case .lilas: 0xB9A2FF
        case .violet: 0x7B61FF
        case .pervenche: 0x7C93FF
        case .bleu: 0x2F6BFF
        case .ciel: 0x6CC8FF
        case .lagon: 0x19B8B0
        case .menthe: 0x3DD598
        case .pomme: 0xA3DB4D
        case .sable: 0xD8C29C
        case .ardoise: 0x7A8296
        case .encre: 0x2A2A2E
        }
    }

    var color: Color { Color(hex: hex) }

    /// Anciennes clés de la version web, et repli sur menthe pour une clé inconnue.
    init(key: String) {
        let legacy = ["sauge": "menthe", "brume": "pervenche", "lavande": "lilas", "abricot": "mandarine", "mousse": "citron"]
        self = HabitColor(rawValue: legacy[key] ?? key) ?? .menthe
    }
}
