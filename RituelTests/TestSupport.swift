import Foundation
@testable import Rituel

/// Calendrier de test figé sur Paris, pour que les tests ne dépendent pas du fuseau de la machine.
let paris = RituelCalendar(timeZone: TimeZone(identifier: "Europe/Paris")!)

func day(_ y: Int, _ m: Int, _ d: Int, hour: Int = 0) -> Date {
    paris.calendar.date(from: DateComponents(year: y, month: m, day: d, hour: hour))!
}

func log(_ items: [(HabitSpec, Date, Double)]) -> EntryLog {
    EntryLog(items.map { EntryRecord(habitID: $0.0.id, day: $0.1, value: $0.2) }, calendar: paris)
}

enum Sample {
    static let sommeil = DefaultHabits.specs[0]
    static let eau = DefaultHabits.specs[1]
    static let cafe = DefaultHabits.specs[2]
    static let croissant = DefaultHabits.specs[3]
    static let sport = DefaultHabits.specs[4]
    static let fastFood = DefaultHabits.specs[5]
    static let lecture = HabitSpec(name: "Lecture", kind: .goal, target: 4, period: .month)
    static let marche = HabitSpec(name: "Marche", kind: .goal, target: 30, period: .day, measure: .amount, unit: "min")
}
