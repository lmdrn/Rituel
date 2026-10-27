import Foundation

/// Bouton de saisie rapide d'un widget : +1, le premier ajout (+250) ou la valeur du jour la plus courante (8h).
struct QuickAction: Equatable, Sendable {
    let action: EntryAction
    let label: String
}

/// Une habitude telle qu'affichée par les widgets, calculée pour un jour donné.
struct WidgetHabit: Identifiable, Sendable {
    var id: UUID { spec.id }
    let spec: HabitSpec
    /// Total de la période qui contient le jour.
    let total: Double
    let dayValue: Double
    let status: HabitStatus
    let quick: QuickAction
    /// Progression vers la cible, entre 0 et 1.
    let fraction: Double

    var totalText: String { QuantityFormat.value(total, for: spec, short: true) }
    var targetText: String { QuantityFormat.value(spec.target, for: spec, short: true) }
}

struct WidgetData: Sendable {
    let today: Date
    let habits: [WidgetHabit]
    /// Score d'équilibre de la semaine en cours.
    let score: Int

    static let recentDays = 30

    static func build(specs: [HabitSpec], log: EntryLog, today rawToday: Date) -> WidgetData {
        let cal = log.calendar
        let today = cal.day(rawToday)
        let habits = specs.map { spec in
            let total = log.total(spec, periodContaining: today)
            let recent = (1...recentDays).map { log.value(spec.id, on: cal.adding(days: -$0, to: today)) }.filter { $0 > 0 }
            let fraction = spec.target > 0 ? min(1, total / spec.target) : (total > 0 ? 1 : 0)
            return WidgetHabit(spec: spec, total: total, dayValue: log.value(spec.id, on: today),
                               status: HabitEngine.status(spec, total: total),
                               quick: HabitEngine.quickAction(spec, recentDayValues: recent), fraction: fraction)
        }
        let score = RecapEngine.recap(specs, weekStart: today, log: log, today: today).score
        return WidgetData(today: today, habits: habits, score: score)
    }

    /// Habitude choisie dans la configuration, sinon une habitude par défaut.
    func habit(_ id: UUID?, preferAmount: Bool = false) -> WidgetHabit? {
        if let id, let match = habits.first(where: { $0.id == id }) { return match }
        if preferAmount, let amount = habits.first(where: { $0.spec.isAmount }) { return amount }
        return habits.first
    }
}

extension HabitEngine {
    static func quickAction(_ habit: HabitSpec, recentDayValues: [Double]) -> QuickAction {
        guard habit.isAmount else { return QuickAction(action: .increment, label: "+1") }
        let presets = habit.effectivePresets
        switch habit.entryMode {
        case .add:
            let v = presets.first ?? 1
            return QuickAction(action: .add(v), label: "+" + QuantityFormat.value(v, for: habit, short: true))
        case .set:
            // La valeur la plus souvent notée parmi les choix rapides, sinon celle qui est la plus proche de la cible.
            let r2 = QuantityFormat.r2
            let counts = recentDayValues.reduce(into: [Double: Int]()) { counts, v in
                if presets.contains(where: { r2($0) == r2(v) }) { counts[r2(v), default: 0] += 1 }
            }
            let frequent = counts.max { a, b in a.value == b.value ? a.key < b.key : a.value < b.value }?.key
            let v = frequent ?? presets.min { abs($0 - habit.target) < abs($1 - habit.target) } ?? habit.target
            return QuickAction(action: .set(v), label: QuantityFormat.value(v, for: habit, short: true))
        }
    }
}
