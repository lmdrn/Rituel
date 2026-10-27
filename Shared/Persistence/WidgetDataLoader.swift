import Foundation
import SwiftData

/// Lit la base partagée et prépare ce qu'affichent les widgets, pour n'importe quel jour.
enum WidgetDataLoader {
    static func load(at date: Date = .now, calendar: RituelCalendar = .current) -> WidgetData {
        let (specs, log) = specsAndLog(at: date, calendar: calendar)
        return WidgetData.build(specs: specs, log: log, today: date)
    }

    /// Les habitudes et assez d'historique pour le score de la semaine, le mois en cours et le choix rapide le plus courant.
    static func specsAndLog(at date: Date = .now, calendar: RituelCalendar = .current) -> ([HabitSpec], EntryLog) {
        let context = ModelContext(RituelStore.shared)
        let habits = (try? context.fetch(FetchDescriptor<Habit>(sortBy: [SortDescriptor(\.sortIndex)]))) ?? []

        let today = calendar.day(date)
        let monday = calendar.monday(of: today)
        let start = min(calendar.adding(days: -WidgetData.recentDays, to: today), monday, calendar.range(.month, containing: today).first)
        let end = calendar.adding(days: 1, to: max(calendar.adding(days: 6, to: monday), calendar.range(.month, containing: today).last))
        let entries = (try? context.fetch(FetchDescriptor<Entry>(predicate: #Predicate { $0.day >= start && $0.day < end }))) ?? []

        return (habits.map(\.spec), EntryLog(entries, calendar: calendar))
    }

    static func habitEntities() -> [HabitEntity] {
        let context = ModelContext(RituelStore.shared)
        let habits = (try? context.fetch(FetchDescriptor<Habit>(sortBy: [SortDescriptor(\.sortIndex)]))) ?? []
        return habits.map { HabitEntity(spec: $0.spec) }
    }
}
