import Foundation

/// Une notification de rappel à programmer.
struct PlannedReminder: Equatable, Sendable {
    let id: String
    let habitID: UUID
    let fireDate: Date
    let title: String
    let body: String
    let categoryID: String
}

/// Prévoit les rappels des prochains jours. On programme des rappels ponctuels plutôt qu'un rappel qui se répète,
/// pour ne pas relancer une habitude dont l'objectif est déjà atteint.
enum ReminderPlanner {
    static let idPrefix = "rituel.reminder."
    static let categoryPrefix = "rituel.habit."
    static let logActionID = "rituel.log"
    /// iOS garde au plus 64 notifications en attente.
    static let maxPending = 60

    static func categoryID(for habitID: UUID) -> String { categoryPrefix + habitID.uuidString }

    static func body(for habit: HabitSpec) -> String {
        switch (habit.kind, habit.trimmedUnit) {
        case (.goal, "ml"): "As-tu bu ton eau ?"
        case (.goal, "h"): "As-tu noté ta nuit ?"
        case (.goal, _): "Un petit moment pour \(habit.name.lowercased()) aujourd'hui ?"
        case (.limit, _): "Comment ça se passe avec \(habit.name.lowercased()) aujourd'hui ? Note-le si besoin."
        }
    }

    /// Titre du bouton d'action de la notification : « Fait », « +250 ml », « 8h ».
    static func actionTitle(for habit: HabitSpec, quick: QuickAction) -> String {
        guard habit.isAmount, let v = quick.action.amount else { return "Fait" }
        let text = QuantityFormat.value(v, for: habit).replacingOccurrences(of: QuantityFormat.nbsp, with: " ")
        return habit.entryMode == .add ? "+" + text : text
    }

    static func plan(_ habits: [HabitSpec], log: EntryLog, now: Date, days: Int = 7) -> [PlannedReminder] {
        let cal = log.calendar
        let today = cal.day(now)
        var result: [PlannedReminder] = []
        for habit in habits {
            guard let minutes = habit.reminderMinutes else { continue }
            let todayRange = cal.range(habit.period, containing: today)
            let doneForNow = habit.kind == .goal && HabitEngine.status(habit, total: log.total(habit.id, in: todayRange)).tone == .done
            for offset in 0..<days {
                let day = cal.adding(days: offset, to: today)
                // Objectif déjà atteint : pas de rappel jusqu'à la fin de sa période.
                if doneForNow && day <= todayRange.last { continue }
                guard let fire = cal.calendar.date(bySettingHour: minutes / 60, minute: minutes % 60, second: 0, of: day),
                      fire > now else { continue }
                result.append(PlannedReminder(
                    id: idPrefix + habit.id.uuidString + "." + String(Int(day.timeIntervalSince1970)),
                    habitID: habit.id, fireDate: fire, title: habit.name, body: body(for: habit),
                    categoryID: categoryID(for: habit.id)
                ))
            }
        }
        return Array(result.sorted { $0.fireDate < $1.fireDate }.prefix(maxPending))
    }
}

/// Temps de sommeil réel à partir des phases lues dans Santé.
enum SleepMath {
    /// Fusionne les intervalles qui se chevauchent (montre + iPhone), les coupe à la fenêtre, et arrondit au quart d'heure.
    static func asleepHours(_ intervals: [DateInterval], within window: DateInterval) -> Double {
        let clipped = intervals.compactMap { $0.intersection(with: window) }.sorted { $0.start < $1.start }
        var merged: [DateInterval] = []
        for interval in clipped {
            if let last = merged.last, interval.start <= last.end {
                merged[merged.count - 1] = DateInterval(start: last.start, end: max(last.end, interval.end))
            } else {
                merged.append(interval)
            }
        }
        let hours = merged.reduce(0) { $0 + $1.duration } / 3600
        return (hours * 4).rounded() / 4
    }

    /// La nuit qui se termine ce matin : de la veille 18 h à aujourd'hui 14 h.
    static func lastNight(endingOn day: Date, calendar: RituelCalendar) -> DateInterval {
        let d = calendar.day(day)
        let start = calendar.calendar.date(byAdding: .hour, value: 18, to: calendar.adding(days: -1, to: d)) ?? d
        let end = calendar.calendar.date(byAdding: .hour, value: 14, to: d) ?? d
        return DateInterval(start: start, end: end)
    }
}

extension DefaultHabits {
    /// L'habitude que remplit l'import Santé : Sommeil par défaut, sinon la première valeur du jour en heures.
    static func sleepHabit(in habits: [HabitSpec]) -> HabitSpec? {
        let isSleepLike = { (h: HabitSpec) in h.isAmount && h.trimmedUnit == "h" && h.entryMode == .set && h.period == .day }
        return habits.first { $0.id == specs[0].id && isSleepLike($0) } ?? habits.first(where: isSleepLike)
    }

    /// L'habitude que remplit « Ajouter de l'eau » : Eau par défaut, sinon la première quantité en ml qu'on additionne.
    static func waterHabit(in habits: [HabitSpec]) -> HabitSpec? {
        let isWaterLike = { (h: HabitSpec) in h.isAmount && h.trimmedUnit == "ml" && h.entryMode == .add }
        return habits.first { $0.id == specs[1].id && isWaterLike($0) } ?? habits.first(where: isWaterLike)
    }
}
