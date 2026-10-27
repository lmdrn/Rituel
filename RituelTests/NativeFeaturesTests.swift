import Testing
import Foundation
@testable import Rituel

struct ReminderPlannerTests {
    var eau: HabitSpec { var h = Sample.eau; h.reminderMinutes = 15 * 60; return h }
    var sport: HabitSpec { var h = Sample.sport; h.reminderMinutes = 18 * 60; return h }
    var cafe: HabitSpec { var h = Sample.cafe; h.reminderMinutes = 10 * 60; return h }

    @Test func plansTheNextSevenDaysAfterNow() {
        let now = day(2026, 10, 28, hour: 16) // après 15 h : pas de rappel aujourd'hui
        let plan = ReminderPlanner.plan([eau], log: log([]), now: now)
        #expect(plan.count == 6)
        #expect(plan.first?.fireDate == paris.calendar.date(bySettingHour: 15, minute: 0, second: 0, of: day(2026, 10, 29)))
        #expect(plan.first?.body == "As-tu bu ton eau ?")
        #expect(plan.first?.title == "Eau")
    }

    @Test func noReminderOnceTheDailyGoalIsMet() {
        let now = day(2026, 10, 28, hour: 9)
        let plan = ReminderPlanner.plan([eau], log: log([(Sample.eau, day(2026, 10, 28), 2000)]), now: now)
        #expect(plan.count == 6)
        #expect(plan.allSatisfy { $0.fireDate > day(2026, 10, 29) })
    }

    @Test func weeklyGoalMetSkipsTheRestOfTheWeek() {
        let now = day(2026, 10, 28, hour: 9)
        let l = log([(Sample.sport, day(2026, 10, 26), 3)])
        let plan = ReminderPlanner.plan([sport], log: l, now: now)
        #expect(plan.allSatisfy { $0.fireDate >= day(2026, 11, 2) })
    }

    @Test func limitsAreStillReminded() {
        let now = day(2026, 10, 28, hour: 9)
        let plan = ReminderPlanner.plan([cafe], log: log([(Sample.cafe, day(2026, 10, 28), 3)]), now: now)
        #expect(plan.count == 7)
    }

    @Test func habitsWithoutReminderAreIgnoredAndThePlanIsCapped() {
        #expect(ReminderPlanner.plan([Sample.eau], log: log([]), now: day(2026, 10, 28)).isEmpty)
        let many = (0..<12).map { i -> HabitSpec in var h = HabitSpec(name: "H\(i)"); h.reminderMinutes = 20 * 60; return h }
        #expect(ReminderPlanner.plan(many, log: log([]), now: day(2026, 10, 28)).count == ReminderPlanner.maxPending)
    }

    @Test func actionTitles() {
        #expect(ReminderPlanner.actionTitle(for: Sample.eau, quick: QuickAction(action: .add(250), label: "+250")) == "+250 ml")
        #expect(ReminderPlanner.actionTitle(for: Sample.sport, quick: QuickAction(action: .increment, label: "+1")) == "Fait")
        #expect(ReminderPlanner.actionTitle(for: Sample.sommeil, quick: QuickAction(action: .set(8), label: "8h")) == "8h")
    }
}

struct SleepImportTests {
    @Test func overlappingPhasesAreMergedAndRounded() {
        let night = SleepMath.lastNight(endingOn: day(2026, 10, 28), calendar: paris)
        #expect(night.start == day(2026, 10, 27, hour: 18))
        #expect(night.end == day(2026, 10, 28, hour: 14))
        let watch = DateInterval(start: day(2026, 10, 27, hour: 23), end: day(2026, 10, 28, hour: 3))
        let phone = DateInterval(start: day(2026, 10, 28, hour: 2), end: day(2026, 10, 28, hour: 6).addingTimeInterval(20 * 60))
        // 23 h → 6 h 20 = 7 h 20, arrondi au quart d'heure : 7 h 15.
        #expect(SleepMath.asleepHours([watch, phone], within: night) == 7.25)
    }

    @Test func samplesOutsideTheNightAreIgnored() {
        let night = SleepMath.lastNight(endingOn: day(2026, 10, 28), calendar: paris)
        let nap = DateInterval(start: day(2026, 10, 28, hour: 15), end: day(2026, 10, 28, hour: 16))
        #expect(SleepMath.asleepHours([nap], within: night) == 0)
    }

    @Test func sleepAndWaterHabitsAreFound() {
        #expect(DefaultHabits.sleepHabit(in: DefaultHabits.specs)?.name == "Sommeil")
        #expect(DefaultHabits.waterHabit(in: DefaultHabits.specs)?.name == "Eau")
        let custom = HabitSpec(name: "Nuit", kind: .goal, target: 7, period: .day, measure: .amount, unit: "h", entryMode: .set)
        #expect(DefaultHabits.sleepHabit(in: [Sample.sport, custom])?.name == "Nuit")
        #expect(DefaultHabits.waterHabit(in: [Sample.sport]) == nil)
    }

    @Test func replaceSetsTheValueWithoutToggling() {
        #expect(HabitEngine.newValue(for: .replace(7.5), current: 7.5) == 7.5)
        #expect(HabitEngine.newValue(for: .replace(-1), current: 3) == 0)
    }
}
