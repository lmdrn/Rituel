import Testing
import Foundation
@testable import Rituel

struct HabitDraftTests {
    @Test func newDraftIsAWeeklyLimitInAFreeColor() {
        let draft = HabitDraft(newWithSortIndex: 6, usedColors: ["citron", "soleil"])
        #expect(draft.isNew)
        #expect(draft.spec.kind == .limit)
        #expect(draft.spec.period == .week)
        #expect(draft.spec.target == 1)
        #expect(draft.spec.colorKey == "mandarine")
        #expect(draft.spec.sortIndex == 6)
    }

    @Test func nameIsRequiredAndCapped() {
        var draft = HabitDraft(newWithSortIndex: 0)
        #expect(draft.problem == .missingName)
        #expect(draft.finalized() == nil)
        draft.setName(String(repeating: "a", count: 60))
        #expect(draft.spec.name.count == 40)
        draft.setName("  Méditation ")
        #expect(draft.finalized()?.name == "Méditation")
    }

    @Test func switchingToHoursSuggestsSleep() {
        var draft = HabitDraft(newWithSortIndex: 0)
        draft.setMeasure(.amount)
        #expect(draft.spec.unit == "h")
        #expect(draft.spec.target == 8)
        #expect(draft.spec.kind == .goal)
        #expect(draft.presetsText == "6  6.5  7  7.5  8  9")
    }

    @Test func presetsFollowTheUnitUntilCustomised() {
        var draft = HabitDraft(newWithSortIndex: 0)
        draft.setMeasure(.amount)
        draft.setUnit("ml")
        #expect(draft.spec.presets == [250, 500, 1000])
        #expect(draft.spec.entryMode == .add)
        draft.setPresetsText("100 200")
        draft.setUnit("km")
        #expect(draft.spec.presets == [100, 200])
    }

    @Test func goalCountStaysAboveZero() {
        var draft = HabitDraft(newWithSortIndex: 0)
        draft.stepTarget(by: -1)
        #expect(draft.spec.target == 0)
        draft.setKind(.goal)
        #expect(draft.spec.target == 1)
        #expect(!draft.canDecrement)
        for _ in 0..<120 { draft.stepTarget(by: 1) }
        #expect(draft.spec.target == 99)
    }

    @Test func amountGoalNeedsATarget() {
        var draft = HabitDraft(newWithSortIndex: 0)
        draft.setName("Eau")
        draft.setMeasure(.amount)
        draft.setTargetText("0")
        #expect(draft.problem == .missingTarget)
        draft.setTargetText("1,5")
        #expect(draft.spec.target == 1.5)
        #expect(draft.problem == nil)
    }

    @Test func countHabitDropsQuantityFields() throws {
        var draft = HabitDraft(editing: DefaultHabits.specs[1])
        draft.setMeasure(.count)
        let spec = try #require(draft.finalized())
        #expect(spec.unit == nil)
        #expect(spec.presets.isEmpty)
        #expect(spec.target == 1) // 2000 dépasse 99 : on repart de 1
    }

    @Test func previewSentence() {
        var draft = HabitDraft(newWithSortIndex: 0)
        #expect(draft.previewText == "Pas plus de 1 cette habitude par semaine.")
        draft.setName("Sport")
        draft.setKind(.goal)
        draft.stepTarget(by: 2)
        #expect(draft.previewText == "Sport au moins 3 fois par semaine.")
    }
}
