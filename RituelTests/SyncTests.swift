import Testing
import Foundation
import SwiftData
@testable import Rituel

struct SyncTests {
    @Test func redundantKeepsThePreferredItemPerKey() {
        let items = [("a", 3), ("b", 1), ("a", 1), ("a", 2)]
        // Pour « a », on garde la plus petite valeur (index 2).
        #expect(Deduplication.redundant(items, key: \.0, prefer: { $0.1 < $1.1 }) == [0, 3])
        #expect(Deduplication.redundant([("x", 1)], key: \.0, prefer: { $0.1 < $1.1 }).isEmpty)
    }

    @MainActor
    @Test func duplicateDefaultsAndEntriesAreRemoved() throws {
        let container = try RituelStore.makeContainer(inMemory: true)
        let context = container.mainContext
        let sport = DefaultHabits.specs[4]
        let older = Habit(sport, createdAt: Date(timeIntervalSince1970: 100))
        let newer = Habit(sport, createdAt: Date(timeIntervalSince1970: 200))
        context.insert(newer)
        context.insert(older)
        context.insert(Habit(DefaultHabits.specs[0]))
        let d = day(2026, 10, 26)
        context.insert(Entry(habitID: sport.id, day: d, value: 1, updatedAt: Date(timeIntervalSince1970: 100)))
        context.insert(Entry(habitID: sport.id, day: d, value: 2, updatedAt: Date(timeIntervalSince1970: 300)))
        try context.save()

        HabitWriter(context: context).removeSyncDuplicates()

        let habits = try context.fetch(FetchDescriptor<Habit>())
        #expect(habits.count == 2)
        #expect(habits.first { $0.id == sport.id }?.createdAt == Date(timeIntervalSince1970: 100))
        let entries = try context.fetch(FetchDescriptor<Entry>())
        #expect(entries.count == 1)
        #expect(entries.first?.value == 2)
    }
}
