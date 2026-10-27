import Testing
import Foundation
@testable import Rituel

struct PresentationTests {
    @Test func featuredFollowsTheChosenOrder() {
        var cafe = Sample.cafe; cafe.summaryRank = 0
        var eau = Sample.eau; eau.summaryRank = 1
        var sommeil = Sample.sommeil; sommeil.summaryRank = nil
        #expect(SummaryEngine.featured([sommeil, eau, cafe]).map(\.name) == ["Café froid", "Eau"])
    }

    @Test func featuredFallsBackToGoalsThenLimits() {
        let plain = DefaultHabits.specs.map { h -> HabitSpec in var h = h; h.summaryRank = nil; return h }
        #expect(SummaryEngine.featured(plain).map(\.name) == ["Sommeil", "Eau", "Sport"])
        #expect(SummaryEngine.featured([Sample.cafe, Sample.croissant]).map(\.name) == ["Café froid", "Croissant"])
    }

    @Test func togglingKeepsAtMostThree() {
        let a = UUID(), b = UUID(), c = UUID(), d = UUID()
        #expect(SummaryEngine.toggling(d, in: [a, b, c]) == [a, b, c])
        #expect(SummaryEngine.toggling(b, in: [a, b, c]) == [a, c])
        #expect(SummaryEngine.toggling(d, in: [a, c]) == [a, c, d])
    }

    @Test func goalDaisyFillsTowardsTheTarget() {
        #expect(SummaryEngine.daisyFill(Sample.eau, total: 1250) == DaisyFill(petals: 4, color: .habit, heartLit: false))
        #expect(SummaryEngine.daisyFill(Sample.eau, total: 2500) == DaisyFill(petals: 7, color: .habit, heartLit: true))
    }

    @Test func limitDaisyShowsWhatIsLeft() {
        let three = HabitSpec(kind: .limit, target: 3, period: .week)
        #expect(SummaryEngine.daisyFill(three, total: 0) == DaisyFill(petals: 7, color: .habit, heartLit: true))
        #expect(SummaryEngine.daisyFill(three, total: 1) == DaisyFill(petals: 5, color: .habit, heartLit: true))
        #expect(SummaryEngine.daisyFill(three, total: 3) == DaisyFill(petals: 0, color: .habit, heartLit: true))
        #expect(SummaryEngine.daisyFill(three, total: 4) == DaisyFill(petals: 7, color: .over, heartLit: false))
    }

    @Test func workoutsAreCountedPerDayWithFilters() {
        let w = [
            HealthMath.Workout(start: day(2026, 10, 26, hour: 7), duration: 30 * 60, kind: .running),
            HealthMath.Workout(start: day(2026, 10, 26, hour: 18), duration: 10 * 60, kind: .running),
            HealthMath.Workout(start: day(2026, 10, 27, hour: 7), duration: 45 * 60, kind: .yoga),
        ]
        #expect(HealthMath.workoutsPerDay(w, minMinutes: 0, kind: nil, calendar: paris) == [day(2026, 10, 26): 2, day(2026, 10, 27): 1])
        #expect(HealthMath.workoutsPerDay(w, minMinutes: 20, kind: nil, calendar: paris) == [day(2026, 10, 26): 1, day(2026, 10, 27): 1])
        #expect(HealthMath.workoutsPerDay(w, minMinutes: 0, kind: .yoga, calendar: paris) == [day(2026, 10, 27): 1])
    }

    @Test func samplesAreSummedPerDay() {
        let s: [(date: Date, value: Double)] = [(day(2026, 10, 26, hour: 9), 3200.4), (day(2026, 10, 26, hour: 20), 6900), (day(2026, 10, 27, hour: 8), 500)]
        #expect(HealthMath.sumPerDay(s, calendar: paris) == [day(2026, 10, 26): 10100, day(2026, 10, 27): 500])
    }

    @Test func healthSourcesMatchHabits() {
        #expect(HealthSource.sleep.fits(Sample.sommeil))
        #expect(HealthSource.water.fits(Sample.eau))
        #expect(!HealthSource.water.fits(Sample.sommeil))
        #expect(HealthSource.workouts.fits(Sample.sport))
        #expect(HealthSource.suggested(for: Sample.sport) == .workouts)
        #expect(HealthSource.suggested(for: Sample.cafe) == nil)
        #expect(HabitSpec.templates.first?.healthSource == .steps)
    }
}

struct SummaryLineTests {
    @Test func dayFillCountsDailyHabitsKept() {
        let today = day(2026, 10, 28)
        let l = log([(Sample.sommeil, day(2026, 10, 27), 8), (Sample.eau, day(2026, 10, 27), 500)])
        let daily = [Sample.sommeil, Sample.eau, Sample.cafe]
        // Sommeil tenu, café tenu (0 ≤ 1), eau ratée : 2 sur 3.
        #expect(SummaryEngine.dayFill(daily, log: l, day: day(2026, 10, 27), today: today) == DaisyFill(petals: 5, color: .habit, heartLit: false))
        #expect(SummaryEngine.dayFill(daily, log: l, day: day(2026, 10, 29), today: today).petals == 0)
    }

    @Test func limitsLine() {
        let l = log([(Sample.cafe, day(2026, 10, 28), 1)])
        let line = SummaryEngine.limitsLine(DefaultHabits.specs, log: l, day: day(2026, 10, 28))
        #expect(line?.text == "1 atteinte, aucune dépassée")
        #expect(line?.tone == .edge)
        #expect(SummaryEngine.limitsLine([Sample.sport], log: l, day: day(2026, 10, 28)) == nil)
    }
}
