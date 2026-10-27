import HealthKit
import SwiftData

/// Remplit les habitudes reliées à Santé : sommeil réel, séances de sport, eau, pas, pleine conscience.
/// Garmin Connect, Strava et l'Apple Watch écrivent dans Santé ; Rituel ne fait que lire.
/// Une saisie faite à la main n'est jamais écrasée.
@MainActor
enum HealthImporter {
    private static let store = HKHealthStore()
    /// Jours relus à chaque import : la semaine écoulée, pour les habitudes à la semaine.
    private static let daysBack = 7

    static func readTypes(for sources: Set<HealthSource>) -> Set<HKObjectType> {
        Set(sources.map { source -> HKObjectType in
            switch source {
            case .sleep: HKCategoryType(.sleepAnalysis)
            case .workouts: HKObjectType.workoutType()
            case .water: HKQuantityType(.dietaryWater)
            case .steps: HKQuantityType(.stepCount)
            case .mindful: HKCategoryType(.mindfulSession)
            }
        })
    }

    /// Lecture seule. Santé ne dit jamais si la lecture a été refusée : on importe simplement ce qui est visible.
    static func requestAuthorization(for sources: Set<HealthSource>) async {
        guard HKHealthStore.isHealthDataAvailable(), !sources.isEmpty else { return }
        try? await store.requestAuthorization(toShare: [], read: readTypes(for: sources))
    }

    /// L'ancien interrupteur global « Sommeil depuis Santé » devient la source de l'habitude Sommeil.
    static func migrateLegacySleepSetting(in context: ModelContext) {
        let defaults = SharedDefaults.store
        guard defaults.bool(forKey: SharedDefaults.healthSleepImportKey) else { return }
        defaults.removeObject(forKey: SharedDefaults.healthSleepImportKey)
        let habits = (try? context.fetch(FetchDescriptor<Habit>())) ?? []
        if let sleep = DefaultHabits.sleepHabit(in: habits.map(\.spec)), let habit = habits.first(where: { $0.id == sleep.id }) {
            habit.healthSourceRaw = HealthSource.sleep.rawValue
            try? context.save()
        }
    }

    static func importAll(into context: ModelContext, now: Date = .now) async {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        let calendar = RituelCalendar.current
        let habits = ((try? context.fetch(FetchDescriptor<Habit>())) ?? []).map(\.spec).filter { $0.healthSource != nil }
        guard !habits.isEmpty else { return }
        let writer = EntryWriter(context: context, calendar: calendar)
        let today = calendar.day(now)
        let days = (0..<daysBack).map { calendar.adding(days: -$0, to: today) }
        let window = DateInterval(start: days.last ?? today, end: calendar.adding(days: 1, to: today))

        for habit in habits {
            guard let source = habit.healthSource, source.fits(habit) else { continue }
            let perDay: [Date: Double]
            switch source {
            case .sleep:
                perDay = [today: await sleepHours(endingOn: now, calendar: calendar)]
            case .workouts:
                perDay = HealthMath.workoutsPerDay(await workouts(in: window), minMinutes: habit.healthMinMinutes,
                                                   kind: habit.healthWorkoutKind, calendar: calendar)
            case .water:
                perDay = await dailySums(.dietaryWater, unit: .literUnit(with: .milli), in: window, calendar: calendar)
            case .steps:
                perDay = await dailySums(.stepCount, unit: .count(), in: window, calendar: calendar)
            case .mindful:
                perDay = HealthMath.sumPerDay(await mindfulMinutes(in: window), calendar: calendar)
            }
            let importedDays = source == .sleep ? [today] : days
            for day in importedDays {
                writer.importValue(perDay[day] ?? 0, habitID: habit.id, day: day, source: Entry.healthSource, now: now)
            }
        }
    }

    // MARK: Lectures

    private static func sleepHours(endingOn now: Date, calendar: RituelCalendar) async -> Double {
        let night = SleepMath.lastNight(endingOn: now, calendar: calendar)
        let predicate = HKQuery.predicateForSamples(withStart: night.start, end: night.end)
        let descriptor = HKSampleQueryDescriptor(predicates: [.categorySample(type: HKCategoryType(.sleepAnalysis), predicate: predicate)],
                                                 sortDescriptors: [])
        guard let samples = try? await descriptor.result(for: store) else { return 0 }
        let asleep = samples.filter { sample in
            HKCategoryValueSleepAnalysis(rawValue: sample.value).map(HKCategoryValueSleepAnalysis.allAsleepValues.contains) ?? false
        }
        return SleepMath.asleepHours(asleep.map { DateInterval(start: $0.startDate, end: $0.endDate) }, within: night)
    }

    private static func workouts(in window: DateInterval) async -> [HealthMath.Workout] {
        let predicate = HKQuery.predicateForSamples(withStart: window.start, end: window.end)
        let descriptor = HKSampleQueryDescriptor(predicates: [.workout(predicate)], sortDescriptors: [])
        guard let samples = try? await descriptor.result(for: store) else { return [] }
        return samples.map { HealthMath.Workout(start: $0.startDate, duration: $0.duration, kind: kind(of: $0.workoutActivityType)) }
    }

    private static func kind(of type: HKWorkoutActivityType) -> WorkoutKind? {
        switch type {
        case .running: .running
        case .cycling: .cycling
        case .walking, .hiking: .walking
        case .swimming: .swimming
        case .traditionalStrengthTraining, .functionalStrengthTraining, .coreTraining: .strength
        case .yoga, .pilates: .yoga
        default: nil
        }
    }

    /// Sommes par jour dédoublonnées entre sources (montre et iPhone comptent les mêmes pas).
    private static func dailySums(_ id: HKQuantityTypeIdentifier, unit: HKUnit, in window: DateInterval,
                                  calendar: RituelCalendar) async -> [Date: Double] {
        let type = HKQuantityType(id)
        let descriptor = HKStatisticsCollectionQueryDescriptor(
            predicate: .quantitySample(type: type, predicate: HKQuery.predicateForSamples(withStart: window.start, end: window.end)),
            options: .cumulativeSum, anchorDate: window.start, intervalComponents: DateComponents(day: 1))
        guard let collection = try? await descriptor.result(for: store) else { return [:] }
        var result: [Date: Double] = [:]
        collection.enumerateStatistics(from: window.start, to: window.end) { statistics, _ in
            if let sum = statistics.sumQuantity() {
                result[calendar.day(statistics.startDate)] = sum.doubleValue(for: unit).rounded()
            }
        }
        return result
    }

    private static func mindfulMinutes(in window: DateInterval) async -> [(date: Date, value: Double)] {
        let predicate = HKQuery.predicateForSamples(withStart: window.start, end: window.end)
        let descriptor = HKSampleQueryDescriptor(predicates: [.categorySample(type: HKCategoryType(.mindfulSession), predicate: predicate)],
                                                 sortDescriptors: [])
        guard let samples = try? await descriptor.result(for: store) else { return [] }
        return samples.map { (date: $0.startDate, value: $0.endDate.timeIntervalSince($0.startDate) / 60) }
    }
}
