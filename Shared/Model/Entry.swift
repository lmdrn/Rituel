import Foundation
import SwiftData

/// Une saisie par habitude et par jour. Une valeur à 0 supprime l'entrée.
@Model
final class Entry {
    var habitID: UUID?
    /// Minuit, fuseau local.
    var day: Date = Date.distantPast
    var value: Double = 0
    /// Départage deux entrées du même jour arrivées par la synchro.
    var updatedAt: Date = Date.now
    /// `nil` pour une saisie à la main, `health` pour un import depuis Santé.
    var source: String?

    static let healthSource = "health"

    init(habitID: UUID, day: Date, value: Double, updatedAt: Date = .now, source: String? = nil) {
        self.habitID = habitID
        self.day = day
        self.value = value
        self.updatedAt = updatedAt
        self.source = source
    }

    var record: EntryRecord? {
        guard let habitID else { return nil }
        return EntryRecord(habitID: habitID, day: day, value: value, updatedAt: updatedAt)
    }
}

extension EntryLog {
    init(_ entries: [Entry], calendar: RituelCalendar) {
        self.init(entries.compactMap(\.record), calendar: calendar)
    }
}
