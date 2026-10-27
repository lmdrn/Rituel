import Testing
import Foundation
@testable import Rituel

struct RecapTests {
    let monday = day(2026, 10, 26)
    let wednesday = day(2026, 10, 28)

    @Test func dailyGoalIgnoresTodayUntilReached() throws {
        // Mercredi, sommeil : lundi 8h (ok), mardi 7h (raté), mercredi rien encore.
        let l = log([(Sample.sommeil, monday, 8), (Sample.sommeil, day(2026, 10, 27), 7)])
        let row = try #require(RecapEngine.evaluate(Sample.sommeil, weekStart: monday, log: l, today: wednesday))
        #expect(row.state == .work)
        #expect(row.value == "1/2 jours")
        #expect(row.score == 0.5)
        #expect(row.detail == "Manqué 1 jour sur 2. Moyenne 5h par jour.")
        #expect(row.tip.map(RecapEngine.goalTips.contains) == true)
    }

    @Test func dailyGoalCountsTodayOnceReached() throws {
        let l = log([(Sample.sommeil, monday, 8), (Sample.sommeil, day(2026, 10, 27), 8.5), (Sample.sommeil, wednesday, 8)])
        let row = try #require(RecapEngine.evaluate(Sample.sommeil, weekStart: monday, log: l, today: wednesday))
        #expect(row.state == .kept)
        #expect(row.value == "3/3 jours")
        #expect(row.detail == "Atteint chaque jour. Moyenne 8h10 par jour.")
        #expect(row.tip == nil)
    }

    @Test func dailyLimit() throws {
        let l = log([(Sample.cafe, day(2026, 10, 27), 2)])
        let row = try #require(RecapEngine.evaluate(Sample.cafe, weekStart: monday, log: l, today: wednesday))
        #expect(row.state == .work)
        #expect(row.detail == "Dépassé 1 jour sur 3.")
        #expect(abs(row.score - 2.0 / 3) < 0.0001)
        let clean = try #require(RecapEngine.evaluate(Sample.cafe, weekStart: monday, log: log([]), today: wednesday))
        #expect(clean.detail == "Respecté chaque jour.")
    }

    @Test func nothingToEvaluateOnMondayMorning() throws {
        let row = try #require(RecapEngine.evaluate(Sample.sommeil, weekStart: monday, log: log([]), today: monday))
        #expect(row.state == .progress)
        #expect(row.score == 1)
    }

    @Test func weeklyGoalInProgressThenMissed() throws {
        let l = log([(Sample.sport, monday, 1)])
        let ongoing = try #require(RecapEngine.evaluate(Sample.sport, weekStart: monday, log: l, today: wednesday))
        #expect(ongoing.state == .progress)
        #expect(ongoing.detail == "Encore 2 fois d'ici dimanche.")
        let finished = try #require(RecapEngine.evaluate(Sample.sport, weekStart: monday, log: l, today: day(2026, 11, 3)))
        #expect(finished.state == .work)
        #expect(finished.value == "1/3")
        #expect(finished.detail == "Il manquait 2 fois.")
    }

    @Test func weeklyLimit() throws {
        let over = try #require(RecapEngine.evaluate(Sample.croissant, weekStart: monday, log: log([(Sample.croissant, monday, 2)]), today: wednesday))
        #expect(over.state == .work)
        #expect(over.score == 0.5)
        let exact = try #require(RecapEngine.evaluate(Sample.croissant, weekStart: monday, log: log([(Sample.croissant, monday, 1)]), today: wednesday))
        #expect(exact.detail == "Pile la limite, c'est tenu.")
    }

    @Test func monthlyGoalOnTrack() throws {
        // Le 15 octobre (15/31 du mois), 4 lectures visées : rythme attendu = 1. Deux lectures : en bonne voie.
        let today = day(2026, 10, 15)
        let l = log([(Sample.lecture, day(2026, 10, 3), 1), (Sample.lecture, day(2026, 10, 13), 1)])
        let row = try #require(RecapEngine.evaluate(Sample.lecture, weekStart: day(2026, 10, 12), log: l, today: today))
        #expect(row.state == .progress)
        #expect(row.detail == "En bonne voie pour octobre.")
        let late = try #require(RecapEngine.evaluate(Sample.lecture, weekStart: day(2026, 10, 19), log: log([]), today: day(2026, 10, 25)))
        #expect(late.state == .work)
    }

    @Test func monthlyLimitLooksAtTheMonthOfTheWeek() throws {
        // Semaine du 26 oct. au 1er nov., évaluée après coup : le mois regardé est novembre (jusqu'au 1er).
        let l = log([(Sample.fastFood, day(2026, 10, 27), 2)])
        let row = try #require(RecapEngine.evaluate(Sample.fastFood, weekStart: monday, log: l, today: day(2026, 11, 10)))
        #expect(row.state == .kept)
        #expect(row.detail == "Bien parti pour novembre.")
        let inOctober = try #require(RecapEngine.evaluate(Sample.fastFood, weekStart: monday, log: l, today: wednesday))
        #expect(inOctober.state == .work)
        #expect(inOctober.detail == "Dépassé de 1 en octobre.")
    }

    @Test func futureWeekIsNotEvaluated() {
        #expect(RecapEngine.evaluate(Sample.sport, weekStart: day(2026, 11, 2), log: log([]), today: wednesday) == nil)
    }

    @Test func scoreAndTitle() {
        let l = log([(Sample.cafe, day(2026, 10, 27), 2), (Sample.sport, monday, 3)])
        let recap = RecapEngine.recap([Sample.cafe, Sample.sport, Sample.croissant], weekStart: wednesday, log: l, today: wednesday)
        #expect(recap.weekStart == monday)
        // (2/3 + 1 + 1) / 3 = 0,889 → 89 %
        #expect(recap.score == 89)
        #expect(recap.title == "Une semaine douce et tenue")
        #expect(recap.kept.count == 2)
        #expect(recap.toWork.count == 1)
        #expect(RecapEngine.title(score: 60) == "Une belle semaine, avec de la marge")
        #expect(RecapEngine.title(score: 35) == "Une semaine en demi-teinte")
        #expect(RecapEngine.title(score: 34) == "On repart en douceur")
    }

    @Test func tipIsStableForAHabitAndAWeek() {
        let a = RecapEngine.tip(for: Sample.sport, weekStart: monday, calendar: paris)
        #expect(a == RecapEngine.tip(for: Sample.sport, weekStart: monday, calendar: paris))
        #expect(RecapEngine.goalTips.contains(a))
        #expect(RecapEngine.limitTips.contains(RecapEngine.tip(for: Sample.cafe, weekStart: monday, calendar: paris)))
    }
}
