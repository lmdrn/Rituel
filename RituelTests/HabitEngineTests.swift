import Testing
import Foundation
@testable import Rituel

struct FormattingTests {
    @Test func hours() {
        #expect(QuantityFormat.value(7.5, for: Sample.sommeil) == "7h30")
        #expect(QuantityFormat.value(8, for: Sample.sommeil) == "8h")
        #expect(QuantityFormat.value(7.25, for: Sample.sommeil) == "7h15")
        #expect(QuantityFormat.value(7.999, for: Sample.sommeil) == "8h")
    }

    @Test func millilitres() {
        #expect(QuantityFormat.value(1500, for: Sample.eau) == "1,5L")
        #expect(QuantityFormat.value(2000, for: Sample.eau) == "2L")
        #expect(QuantityFormat.value(750, for: Sample.eau, short: true) == "750")
        #expect(QuantityFormat.value(750, for: Sample.eau) == "750\u{00A0}ml")
    }

    @Test func minutesAndOthers() {
        #expect(QuantityFormat.value(75, for: Sample.marche, short: true) == "1h15")
        #expect(QuantityFormat.value(60, for: Sample.marche, short: true) == "1h")
        #expect(QuantityFormat.value(45, for: Sample.marche) == "45\u{00A0}min")
        let km = HabitSpec(measure: .amount, unit: "km")
        #expect(QuantityFormat.value(2.5, for: km) == "2,5\u{00A0}km")
        #expect(QuantityFormat.value(2.5, for: km, short: true) == "2,5km")
        #expect(QuantityFormat.value(3, for: Sample.sport) == "3")
    }

    @Test func decimalComma() {
        #expect(QuantityFormat.number(0.1 + 0.2) == "0,3")
        #expect(QuantityFormat.number(6.25) == "6,25")
        #expect(QuantityFormat.number(2000) == "2000")
    }
}

struct StatusTests {
    @Test func limitStatuses() {
        let twice = HabitSpec(kind: .limit, target: 3, period: .week)
        #expect(HabitEngine.status(twice, total: 1) == HabitStatus(tone: .ok, label: "Encore 2 possibles"))
        #expect(HabitEngine.status(Sample.croissant, total: 0) == HabitStatus(tone: .ok, label: "Encore 1 possible"))
        #expect(HabitEngine.status(Sample.croissant, total: 1) == HabitStatus(tone: .edge, label: "Limite atteinte"))
        #expect(HabitEngine.status(Sample.cafe, total: 2) == HabitStatus(tone: .over, label: "Dépassé de 1"))
    }

    @Test func zeroLimit() {
        let none = HabitSpec(kind: .limit, target: 0, period: .week)
        #expect(HabitEngine.status(none, total: 0) == HabitStatus(tone: .ok, label: "Rien noté, bravo"))
        #expect(HabitEngine.status(none, total: 1).tone == .over)
    }

    @Test func goalStatuses() {
        #expect(HabitEngine.status(Sample.sport, total: 1) == HabitStatus(tone: .progress, label: "Encore 2 fois"))
        #expect(HabitEngine.status(Sample.sport, total: 3) == HabitStatus(tone: .done, label: "Objectif atteint"))
        #expect(HabitEngine.status(Sample.sport, total: 4) == HabitStatus(tone: .done, label: "Objectif dépassé, +1"))
        #expect(HabitEngine.status(Sample.sommeil, total: 6.5).label == "Encore 1h30")
        #expect(HabitEngine.status(Sample.eau, total: 1250).label == "Encore 750\u{00A0}ml")
        #expect(HabitEngine.status(Sample.eau, total: 0.1 + 0.2 + 1999.7).tone == .done)
    }

    @Test func ruleTexts() {
        #expect(HabitEngine.ruleText(Sample.croissant) == "Pas plus de 1 par semaine")
        #expect(HabitEngine.ruleText(Sample.sommeil) == "Au moins 8h par jour")
        #expect(HabitEngine.ruleText(Sample.eau) == "Au moins 2L par jour")
        #expect(HabitEngine.ruleText(Sample.sport) == "Au moins 3 fois par semaine")
        #expect(HabitEngine.previewText(Sample.sommeil) == "Sommeil : au moins 8h par jour.")
        #expect(HabitEngine.previewText(Sample.croissant) == "Pas plus de 1 croissant par semaine.")
    }
}

struct EntryTests {
    @Test func countEntries() {
        #expect(HabitEngine.newValue(for: .increment, current: 1) == 2)
        #expect(HabitEngine.newValue(for: .decrement, current: 1) == 0)
        #expect(HabitEngine.newValue(for: .decrement, current: 0) == 0)
    }

    @Test func setTogglesTheSameValue() {
        #expect(HabitEngine.newValue(for: .set(7.5), current: 0) == 7.5)
        #expect(HabitEngine.newValue(for: .set(7.5), current: 7) == 7.5)
        #expect(HabitEngine.newValue(for: .set(7.5), current: 7.5) == 0)
        #expect(HabitEngine.newValue(for: .clear, current: 7.5) == 0)
    }

    @Test func addAccumulates() {
        #expect(HabitEngine.newValue(for: .add(250), current: 500) == 750)
        #expect(HabitEngine.newValue(for: .add(0.1), current: 0.2) == 0.3)
    }

    @Test func totalsSumThePeriod() {
        let l = log([(Sample.sport, day(2026, 10, 26), 1), (Sample.sport, day(2026, 10, 28), 2), (Sample.sport, day(2026, 11, 2), 1)])
        #expect(l.total(Sample.sport, periodContaining: day(2026, 10, 30)) == 3)
        #expect(l.value(Sample.sport.id, on: day(2026, 10, 28, hour: 14)) == 2)
        #expect(l.hasEntries(on: day(2026, 10, 26)))
        #expect(!l.hasEntries(on: day(2026, 10, 27)))
    }

    @Test func duplicateEntriesKeepTheLatest() {
        let id = Sample.sommeil.id
        let l = EntryLog([
            EntryRecord(habitID: id, day: day(2026, 10, 26), value: 7, updatedAt: Date(timeIntervalSince1970: 100)),
            EntryRecord(habitID: id, day: day(2026, 10, 26), value: 8, updatedAt: Date(timeIntervalSince1970: 200)),
        ], calendar: paris)
        #expect(l.value(id, on: day(2026, 10, 26)) == 8)
    }

    @Test func presetsParsing() {
        #expect(HabitSpec.parsePresets("6  6,5 7;7.5 x -1") == [6, 6.5, 7, 7.5])
        #expect(HabitSpec.parsePresets("1 2 3 4 5 6 7 8 9 10").count == 8)
        #expect(HabitSpec(measure: .amount, unit: "km").effectivePresets == [2, 5, 8, 10])
    }
}

struct GreetingTests {
    @Test func greeting() {
        #expect(HabitEngine.greeting(name: "Léa", hour: 9) == "Bonjour Léa")
        #expect(HabitEngine.greeting(name: "Léa", hour: 18) == "Bonsoir Léa")
        #expect(HabitEngine.greeting(name: " ", hour: 3) == "Bonsoir")
        #expect(HabitEngine.greeting(name: "", hour: 12) == "Bonjour")
    }

    @Test func ledeDependsOnLimitsOver() {
        #expect(HabitEngine.lede(overLimits: 0, habitCount: 6) == "Tout est en équilibre. Continue à ton rythme.")
        #expect(HabitEngine.lede(overLimits: 1, habitCount: 6).hasPrefix("Une limite a été dépassée."))
        #expect(HabitEngine.lede(overLimits: 3, habitCount: 6).hasPrefix("3 limites ont été dépassées."))
        let l = log([(Sample.cafe, day(2026, 10, 27), 2), (Sample.croissant, day(2026, 10, 26), 2), (Sample.sport, day(2026, 10, 27), 9)])
        #expect(HabitEngine.overLimitCount(DefaultHabits.specs, log: l, day: day(2026, 10, 27)) == 2)
        #expect(HabitEngine.overLimitCount(DefaultHabits.specs, log: l, day: day(2026, 10, 28)) == 1)
    }
}

struct DisplayTests {
    @Test func dayCells() {
        let today = day(2026, 10, 28)
        #expect(HabitEngine.dayCell(Sample.cafe, value: 2, day: day(2026, 10, 27), today: today) == .over)
        #expect(HabitEngine.dayCell(Sample.cafe, value: 1, day: today, today: today) == .ok)
        #expect(HabitEngine.dayCell(Sample.sommeil, value: 6, day: today, today: today) == .neutral)
        #expect(HabitEngine.dayCell(Sample.sommeil, value: 6, day: day(2026, 10, 27), today: today) == .over)
        #expect(HabitEngine.dayCell(Sample.sommeil, value: 0, day: day(2026, 10, 29), today: today) == .future)
    }

    @Test func pipsAndBars() {
        #expect(HabitEngine.progress(Sample.sport, total: 1) == .pips([.on, .empty, .empty]))
        #expect(HabitEngine.progress(Sample.sport, total: 5) == .pips([.on, .on, .on, .bonus, .bonus]))
        #expect(HabitEngine.progress(Sample.croissant, total: 3) == .pips([.on, .over, .over]))
        #expect(HabitEngine.progress(HabitSpec(kind: .goal, target: 20), total: 5) == .bar(fraction: 0.25, over: false))
        #expect(HabitEngine.progress(Sample.eau, total: 3000) == .bar(fraction: 1, over: false))
    }
}
