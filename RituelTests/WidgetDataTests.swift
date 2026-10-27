import Testing
import Foundation
@testable import Rituel

struct WidgetDataTests {
    let today = day(2026, 10, 28)

    @Test func countHabitsAddOne() {
        #expect(HabitEngine.quickAction(Sample.sport, recentDayValues: []) == QuickAction(action: .increment, label: "+1"))
    }

    @Test func addHabitsUseTheFirstPreset() {
        #expect(HabitEngine.quickAction(Sample.eau, recentDayValues: [2000]) == QuickAction(action: .add(250), label: "+250"))
    }

    @Test func setHabitsUseTheMostFrequentPreset() {
        let q = HabitEngine.quickAction(Sample.sommeil, recentDayValues: [7, 7.5, 7.5, 8, 6.75])
        #expect(q == QuickAction(action: .set(7.5), label: "7h30"))
    }

    @Test func setHabitsFallBackToTheTarget() {
        #expect(HabitEngine.quickAction(Sample.sommeil, recentDayValues: []).action == .set(8))
    }

    @Test func buildComputesTodayTotalsAndScore() throws {
        let l = log([(Sample.eau, today, 1250), (Sample.sport, day(2026, 10, 26), 1), (Sample.sommeil, day(2026, 10, 20), 7.5)])
        let data = WidgetData.build(specs: [Sample.sommeil, Sample.eau, Sample.sport], log: l, today: day(2026, 10, 28, hour: 15))
        #expect(data.today == today)
        let eau = try #require(data.habit(Sample.eau.id))
        #expect(eau.totalText == "1,3L")
        #expect(eau.targetText == "2L")
        #expect(eau.fraction == 0.625)
        #expect(eau.status.label == "Encore 750\u{00A0}ml")
        #expect(data.habit(Sample.sport.id)?.total == 1)
        #expect(data.habit(Sample.sommeil.id)?.quick.action == .set(7.5))
        #expect(data.score > 0)
    }

    @Test func defaultHabitSelection() {
        let data = WidgetData.build(specs: [Sample.cafe, Sample.eau], log: log([]), today: today)
        #expect(data.habit(nil)?.id == Sample.cafe.id)
        #expect(data.habit(nil, preferAmount: true)?.id == Sample.eau.id)
        #expect(data.habit(UUID())?.id == Sample.cafe.id)
    }
}
