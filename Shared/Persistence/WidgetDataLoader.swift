import Foundation
import SwiftData

/// Lit la base partagée et prépare ce qu'affichent les widgets, pour n'importe quel jour.
enum WidgetDataLoader {
    static func load(at date: Date = .now, calendar: RituelCalendar = .current) -> WidgetData {
        let context = ModelContext(RituelStore.shared)
        let habits = (try? context.fetch(FetchDescriptor<Habit>(sortBy: [SortDescriptor(\.sortIndex)]))) ?? []

        let today = calendar.day(date)
        let monday = calendar.monday(of: today)
        // Assez d'historique pour le score de la semaine, le mois en cours et le choix rapide le plus courant.
        let start = min(calendar.adding(days: -WidgetData.recentDays, to: today), monday, calendar.range(.month, containing: today).first)
        let end = calendar.adding(days: 7, to: monday)
        let entries = (try? context.fetch(FetchDescriptor<Entry>(predicate: #Predicate { $0.day >= start && $0.day < end }))) ?? []

        return WidgetData.build(specs: habits.map(\.spec), log: EntryLog(entries, calendar: calendar), today: today)
    }

    static func habitEntities() -> [HabitEntity] {
        let context = ModelContext(RituelStore.shared)
        let habits = (try? context.fetch(FetchDescriptor<Habit>(sortBy: [SortDescriptor(\.sortIndex)]))) ?? []
        return habits.map { HabitEntity(spec: $0.spec) }
    }
}
