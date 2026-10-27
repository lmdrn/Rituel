import Foundation
import SwiftData

// Compatible CloudKit : chaque propriété a une valeur par défaut ou est optionnelle, aucune contrainte `unique`.
// Les énumérations sont stockées en texte pour rester lisibles et faciles à faire évoluer.
@Model
final class Habit {
    var id: UUID = UUID()
    var name: String = ""
    var kindRaw: String = HabitKind.limit.rawValue
    var target: Double = 1
    var periodRaw: String = HabitPeriod.week.rawValue
    var colorKey: String = HabitColor.citron.rawValue
    var measureRaw: String = HabitMeasure.count.rawValue
    var unit: String?
    var entryModeRaw: String = EntryMode.set.rawValue
    var presets: [Double] = []
    var sortIndex: Int = 0
    /// Rappel quotidien, en minutes depuis minuit.
    var reminderMinutes: Int?
    /// Place dans le résumé d'Aujourd'hui (0, 1, 2), ou `nil`.
    var summaryRank: Int?
    var healthSourceRaw: String?
    var healthMinMinutes: Int = 0
    var healthWorkoutKindRaw: String?
    var createdAt: Date = Date.now

    init(_ spec: HabitSpec, createdAt: Date = .now) {
        self.createdAt = createdAt
        update(from: spec)
        id = spec.id
    }

    var spec: HabitSpec {
        HabitSpec(
            id: id,
            name: name,
            kind: HabitKind(rawValue: kindRaw) ?? .limit,
            target: target,
            period: HabitPeriod(rawValue: periodRaw) ?? .week,
            colorKey: colorKey,
            measure: HabitMeasure(rawValue: measureRaw) ?? .count,
            unit: unit,
            entryMode: EntryMode(rawValue: entryModeRaw) ?? .set,
            presets: presets,
            sortIndex: sortIndex,
            reminderMinutes: reminderMinutes,
            summaryRank: summaryRank,
            healthSource: healthSourceRaw.flatMap(HealthSource.init(rawValue:)),
            healthMinMinutes: healthMinMinutes,
            healthWorkoutKind: healthWorkoutKindRaw.flatMap(WorkoutKind.init(rawValue:))
        )
    }

    /// Recopie tout sauf l'identifiant et la date de création.
    func update(from spec: HabitSpec) {
        name = String(spec.name.prefix(HabitSpec.maxNameLength))
        kindRaw = spec.kind.rawValue
        target = spec.target
        periodRaw = spec.period.rawValue
        colorKey = spec.colorKey
        measureRaw = spec.measure.rawValue
        unit = spec.unit
        entryModeRaw = spec.entryMode.rawValue
        presets = Array(spec.presets.prefix(HabitSpec.maxPresets))
        sortIndex = spec.sortIndex
        reminderMinutes = spec.reminderMinutes
        summaryRank = spec.summaryRank
        healthSourceRaw = spec.healthSource?.rawValue
        healthMinMinutes = spec.healthMinMinutes
        healthWorkoutKindRaw = spec.healthWorkoutKind?.rawValue
    }
}
