import Foundation

/// Une saisie, détachée de SwiftData pour que le moteur reste pur et testable.
struct EntryRecord: Sendable {
    var habitID: UUID
    var day: Date
    var value: Double
    var updatedAt: Date = .distantPast
}

/// Valeurs par habitude et par jour.
struct EntryLog: Sendable {
    private var values: [UUID: [Date: Double]] = [:]
    let calendar: RituelCalendar

    init(_ records: [EntryRecord] = [], calendar: RituelCalendar) {
        self.calendar = calendar
        // La synchro iCloud peut créer deux entrées pour le même jour : on garde la plus récente.
        var latest: [UUID: [Date: EntryRecord]] = [:]
        for r in records {
            let d = calendar.day(r.day)
            if let existing = latest[r.habitID]?[d], existing.updatedAt > r.updatedAt { continue }
            latest[r.habitID, default: [:]][d] = r
        }
        for (id, byDay) in latest {
            values[id] = byDay.compactMapValues { $0.value > 0 ? $0.value : nil }
        }
    }

    func value(_ habitID: UUID, on day: Date) -> Double {
        values[habitID]?[calendar.day(day)] ?? 0
    }

    func total(_ habitID: UUID, in range: DayRange) -> Double {
        guard let byDay = values[habitID] else { return 0 }
        return byDay.reduce(0) { sum, item in
            item.key >= range.first && item.key <= range.last ? sum + item.value : sum
        }
    }

    func total(_ habit: HabitSpec, periodContaining day: Date) -> Double {
        total(habit.id, in: calendar.range(habit.period, containing: day))
    }

    func hasEntries(on day: Date) -> Bool {
        let d = calendar.day(day)
        return values.values.contains { ($0[d] ?? 0) > 0 }
    }
}
