import Foundation
import SwiftData

enum DefaultHabits {
    // Identifiants fixes : si deux appareils créent les habitudes par défaut avant la synchro,
    // on pourra reconnaître les doublons.
    static let specs: [HabitSpec] = [
        HabitSpec(id: uuid(1), name: "Sommeil", kind: .goal, target: 8, period: .day, colorKey: HabitColor.lilas.rawValue,
                  measure: .amount, unit: "h", entryMode: .set, presets: [6, 6.5, 7, 7.5, 8, 9], sortIndex: 0, summaryRank: 0),
        HabitSpec(id: uuid(2), name: "Eau", kind: .goal, target: 2000, period: .day, colorKey: HabitColor.ciel.rawValue,
                  measure: .amount, unit: "ml", entryMode: .add, presets: [250, 500, 1000], sortIndex: 1, summaryRank: 1),
        HabitSpec(id: uuid(3), name: "Café froid", kind: .limit, target: 1, period: .day, colorKey: HabitColor.bleu.rawValue,
                  sortIndex: 2),
        HabitSpec(id: uuid(4), name: "Croissant", kind: .limit, target: 1, period: .week, colorKey: HabitColor.mandarine.rawValue,
                  sortIndex: 3),
        HabitSpec(id: uuid(5), name: "Sport", kind: .goal, target: 3, period: .week, colorKey: HabitColor.menthe.rawValue,
                  sortIndex: 4, summaryRank: 2),
        HabitSpec(id: uuid(6), name: "Fast-food", kind: .limit, target: 1, period: .month, colorKey: HabitColor.violet.rawValue,
                  sortIndex: 5),
    ]

    private static func uuid(_ n: Int) -> UUID {
        UUID(uuidString: String(format: "6A1C0000-0000-4000-8000-%012d", n))!
    }

    private static let seededKey = "didSeedDefaultHabits"

    /// Crée les habitudes par défaut au tout premier lancement, une seule fois.
    @MainActor
    static func seedIfNeeded(in context: ModelContext, defaults: UserDefaults = SharedDefaults.store) {
        guard !defaults.bool(forKey: seededKey) else { return }
        defaults.set(true, forKey: seededKey)
        let existing = (try? context.fetchCount(FetchDescriptor<Habit>())) ?? 0
        guard existing == 0 else { return }
        for spec in specs { context.insert(Habit(spec)) }
        try? context.save()
    }
}
