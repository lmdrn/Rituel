import Foundation

/// Remplissage d'une marguerite de progression.
struct DaisyFill: Equatable, Sendable {
    enum Petals: Equatable, Sendable {
        /// Couleur de l'habitude.
        case habit
        /// Corail : limite dépassée.
        case over
    }

    /// Pétales remplis, de 0 à 7.
    let petals: Int
    let color: Petals
    /// Cœur soleil : objectif atteint, ou limite tenue.
    let heartLit: Bool
}

enum SummaryEngine {
    static let maxFeatured = 3

    /// Les habitudes du résumé, dans l'ordre choisi. Sans choix : les trois premiers objectifs, puis les limites.
    static func featured(_ habits: [HabitSpec]) -> [HabitSpec] {
        let chosen = habits.filter { $0.summaryRank != nil }.sorted { ($0.summaryRank ?? 0) < ($1.summaryRank ?? 0) }
        if !chosen.isEmpty { return Array(chosen.prefix(maxFeatured)) }
        let ordered = habits.sorted { $0.sortIndex < $1.sortIndex }
        return Array((ordered.filter { $0.kind == .goal } + ordered.filter { $0.kind == .limit }).prefix(maxFeatured))
    }

    /// Nouveaux rangs après avoir coché ou décoché une habitude (3 au plus, dans l'ordre des coches).
    static func toggling(_ id: UUID, in ranked: [UUID]) -> [UUID] {
        if ranked.contains(id) { return ranked.filter { $0 != id } }
        guard ranked.count < maxFeatured else { return ranked }
        return ranked + [id]
    }

    /// Objectif : les pétales se remplissent vers la cible. Limite : la fleur montre ce qui reste,
    /// pleine quand rien n'est noté, vide à la limite (cœur toujours allumé), corail au-delà.
    static func daisyFill(_ habit: HabitSpec, total: Double) -> DaisyFill {
        let c = QuantityFormat.r2(total), t = QuantityFormat.r2(habit.target)
        switch habit.kind {
        case .goal:
            let fraction = t > 0 ? min(1, c / t) : (c > 0 ? 1 : 0)
            return DaisyFill(petals: Int((fraction * 7).rounded(.down)), color: .habit, heartLit: c >= t)
        case .limit:
            if c > t { return DaisyFill(petals: 7, color: .over, heartLit: false) }
            let left = t > 0 ? (t - c) / t : 1
            return DaisyFill(petals: Int((left * 7).rounded(.up)), color: .habit, heartLit: true)
        }
    }
}

/// Calculs de l'import Santé (au-delà du sommeil) : séances, sommes par jour.
enum HealthMath {
    struct Workout: Sendable {
        let start: Date
        let duration: TimeInterval
        let kind: WorkoutKind?
    }

    /// Nombre de séances par jour qui respectent le type et la durée minimale.
    static func workoutsPerDay(_ workouts: [Workout], minMinutes: Int, kind: WorkoutKind?, calendar: RituelCalendar) -> [Date: Double] {
        workouts
            .filter { $0.duration >= Double(minMinutes) * 60 && (kind == nil || $0.kind == kind) }
            .reduce(into: [:]) { counts, w in counts[calendar.day(w.start), default: 0] += 1 }
    }

    /// Somme des échantillons par jour (eau, pas, minutes), arrondie à l'unité.
    static func sumPerDay(_ samples: [(date: Date, value: Double)], calendar: RituelCalendar) -> [Date: Double] {
        samples
            .reduce(into: [Date: Double]()) { sums, s in sums[calendar.day(s.date), default: 0] += s.value }
            .mapValues { $0.rounded() }
    }
}

extension HabitSpec {
    /// Modèles proposés à la création d'une habitude.
    static var templates: [HabitSpec] {
        [
            HabitSpec(name: "Pas", kind: .goal, target: 10_000, period: .day, colorKey: HabitColor.pomme.rawValue,
                      measure: .amount, unit: "pas", entryMode: .add, presets: [2000, 5000, 8000, 10000], healthSource: .steps),
            HabitSpec(name: "Méditation", kind: .goal, target: 10, period: .day, colorKey: HabitColor.lagon.rawValue,
                      measure: .amount, unit: "min", entryMode: .add, presets: [5, 10, 20], healthSource: .mindful),
            HabitSpec(name: "Lecture", kind: .goal, target: 4, period: .week, colorKey: HabitColor.soleil.rawValue),
        ]
    }
}

extension SummaryEngine {
    /// Marguerite d'un jour dans la frise : part des habitudes quotidiennes tenues ce jour-là.
    static func dayFill(_ habits: [HabitSpec], log: EntryLog, day: Date, today: Date) -> DaisyFill {
        let daily = habits.filter { $0.period == .day }
        guard day <= today, !daily.isEmpty else { return DaisyFill(petals: 0, color: .habit, heartLit: false) }
        let kept = daily.filter { HabitEngine.isDayKept($0, value: log.value($0.id, on: day)) }.count
        return DaisyFill(petals: Int((Double(kept) / Double(daily.count) * 7).rounded()), color: .habit, heartLit: kept == daily.count)
    }

    /// Phrase sur les limites pour le résumé : « 1 atteinte, aucune dépassée ».
    static func limitsLine(_ habits: [HabitSpec], log: EntryLog, day: Date) -> (text: String, tone: StatusTone)? {
        let limits = habits.filter { $0.kind == .limit }
        guard !limits.isEmpty else { return nil }
        let tones = limits.map { HabitEngine.status($0, total: log.total($0, periodContaining: day)).tone }
        let over = tones.filter { $0 == .over }.count, reached = tones.filter { $0 == .edge }.count
        let reachedText = reached == 0 ? "aucune atteinte" : "\(reached) \(HabitEngine.plural(Double(reached), "atteinte"))"
        let overText = over == 0 ? "aucune dépassée" : "\(over) \(HabitEngine.plural(Double(over), "dépassée"))"
        return ("\(reachedText.prefix(1).uppercased())\(reachedText.dropFirst()), \(overText)", over > 0 ? .over : (reached > 0 ? .edge : .ok))
    }
}
