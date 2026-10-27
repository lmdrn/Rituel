import Testing
import Foundation
@testable import Rituel

struct CalendarTests {
    @Test func weekStartsOnMonday() {
        #expect(paris.monday(of: day(2026, 11, 1)) == day(2026, 10, 26)) // dimanche
        #expect(paris.monday(of: day(2026, 10, 26)) == day(2026, 10, 26)) // lundi
        #expect(paris.monday(of: day(2026, 10, 28, hour: 23)) == day(2026, 10, 26))
    }

    @Test func weekCanSpanTwoMonths() {
        let week = paris.range(.week, containing: day(2026, 10, 30))
        #expect(week == DayRange(first: day(2026, 10, 26), last: day(2026, 11, 1)))
        let month = paris.range(.month, containing: day(2026, 10, 30))
        #expect(month == DayRange(first: day(2026, 10, 1), last: day(2026, 10, 31)))
    }

    @Test func monthIsTheCivilMonth() {
        #expect(paris.range(.month, containing: day(2028, 2, 10)).last == day(2028, 2, 29))
        #expect(paris.range(.month, containing: day(2026, 2, 10)).last == day(2026, 2, 28))
        #expect(paris.range(.day, containing: day(2026, 3, 3, hour: 15)) == DayRange(first: day(2026, 3, 3), last: day(2026, 3, 3)))
    }

    @Test func winterTimeChangeKeepsSevenMidnights() {
        // Passage à l'heure d'hiver le dimanche 25 octobre 2026 à Paris : ce jour dure 25 h.
        let week = paris.range(.week, containing: day(2026, 10, 25))
        #expect(week == DayRange(first: day(2026, 10, 19), last: day(2026, 10, 25)))
        let days = paris.days(in: week)
        #expect(days.count == 7)
        #expect(days.allSatisfy { paris.calendar.component(.hour, from: $0) == 0 })
        #expect(paris.adding(days: 1, to: day(2026, 10, 25)) == day(2026, 10, 26))
        #expect(paris.dayCount(from: day(2026, 10, 19), to: day(2026, 10, 25)) == 7)
    }

    @Test func entryOnTheTimeChangeDayCountsInItsWeek() {
        let l = log([(Sample.sport, day(2026, 10, 25, hour: 20), 1), (Sample.sport, day(2026, 10, 26), 1)])
        #expect(l.total(Sample.sport, periodContaining: day(2026, 10, 22)) == 1)
        #expect(l.total(Sample.sport, periodContaining: day(2026, 10, 26)) == 1)
    }

    @Test func isoWeekNumber() {
        #expect(paris.isoWeek(day(2026, 10, 27)) == 44)
        #expect(paris.isoWeek(day(2027, 1, 1)) == 53)
    }

    @Test func frenchDates() {
        #expect(paris.longDate(day(2026, 10, 26)) == "lundi 26 octobre")
        #expect(paris.shortDate(day(2026, 10, 26)) == "26 oct.")
        #expect(paris.monthName(day(2026, 10, 26)) == "octobre")
    }
}
