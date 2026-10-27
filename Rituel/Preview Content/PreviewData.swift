import Foundation
import SwiftData

/// Données d'exemple pour les previews : habitudes par défaut et une semaine en cours bien remplie.
@MainActor
enum PreviewData {
    static let container: ModelContainer = {
        let container = try! RituelStore.makeContainer(inMemory: true)
        let context = container.mainContext
        for spec in DefaultHabits.specs { context.insert(Habit(spec)) }

        let cal = RituelCalendar.current
        let today = cal.day(.now)
        let monday = cal.monday(of: today)
        let ids = DefaultHabits.specs.map(\.id)
        let sample: [(Int, Int, Double)] = [
            // (habitude, jour depuis lundi, valeur)
            (0, 0, 7.5), (0, 1, 8), (0, 2, 6.5), (0, 3, 8), (0, 4, 7),
            (1, 0, 2000), (1, 1, 1500), (1, 2, 2250), (1, 3, 1000), (1, 4, 750),
            (2, 0, 1), (2, 2, 2), (2, 4, 1),
            (3, 1, 1),
            (4, 0, 1), (4, 3, 1),
            (5, 2, 1),
        ]
        for (habit, offset, value) in sample {
            let d = cal.adding(days: offset, to: monday)
            if d <= today { context.insert(Entry(habitID: ids[habit], day: d, value: value)) }
        }
        try? context.save()
        return container
    }()
}
