import HealthKit
import SwiftData

/// Remplit l'habitude Sommeil avec le sommeil réel lu dans Santé (phases de sommeil, pas le temps au lit).
@MainActor
enum SleepImporter {
    private static let store = HKHealthStore()
    private static let sleepType = HKCategoryType(.sleepAnalysis)

    static var isEnabled: Bool {
        SharedDefaults.store.bool(forKey: SharedDefaults.healthSleepImportKey)
    }

    /// Lecture seule. Santé ne dit jamais si la lecture a été refusée : on importe simplement ce qui est visible.
    static func requestAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        try? await store.requestAuthorization(toShare: [], read: [sleepType])
    }

    /// Importe la nuit qui s'est terminée ce matin, sauf si le sommeil du jour a été noté à la main.
    static func importLastNight(into context: ModelContext, now: Date = .now) async {
        guard isEnabled, HKHealthStore.isHealthDataAvailable() else { return }
        let calendar = RituelCalendar.current
        let habits = ((try? context.fetch(FetchDescriptor<Habit>())) ?? []).map(\.spec)
        guard let sleep = DefaultHabits.sleepHabit(in: habits) else { return }

        let night = SleepMath.lastNight(endingOn: now, calendar: calendar)
        let predicate = HKQuery.predicateForSamples(withStart: night.start, end: night.end)
        let descriptor = HKSampleQueryDescriptor(predicates: [.categorySample(type: sleepType, predicate: predicate)], sortDescriptors: [])
        guard let samples = try? await descriptor.result(for: store) else { return }

        let asleep = samples.filter { sample in
            HKCategoryValueSleepAnalysis(rawValue: sample.value).map(HKCategoryValueSleepAnalysis.allAsleepValues.contains) ?? false
        }
        let hours = SleepMath.asleepHours(asleep.map { DateInterval(start: $0.startDate, end: $0.endDate) }, within: night)
        guard hours > 0 else { return }
        EntryWriter(context: context, calendar: calendar).importValue(hours, habitID: sleep.id, day: now, source: Entry.healthSource)
    }
}
