import Foundation

enum StatusTone: Sendable {
    /// Vert : marge restante sur une limite.
    case ok
    /// Ambre : limite atteinte.
    case edge
    /// Corail : limite dépassée.
    case over
    /// Vert : objectif atteint.
    case done
    /// Neutre : objectif en cours.
    case progress
}

struct HabitStatus: Equatable, Sendable {
    let tone: StatusTone
    let label: String
}

enum EntryAction: Equatable, Sendable {
    case increment
    case decrement
    /// Fixe la valeur du jour ; retaper la même valeur l'efface.
    case set(Double)
    case add(Double)
    /// Fixe la valeur du jour sans bascule (Siri, import Santé).
    case replace(Double)
    case clear

    /// La valeur portée par l'action, s'il y en a une.
    var amount: Double? {
        switch self {
        case .set(let v), .add(let v), .replace(let v): v
        case .increment, .decrement, .clear: nil
        }
    }
}

/// État d'une case de la mini-frise d'une habitude quotidienne.
enum DayCellState: Sendable {
    case ok, over, neutral, future
}

enum PipState: Sendable {
    case empty, on, over, bonus
}

enum ProgressDisplay: Equatable, Sendable {
    case pips([PipState])
    case bar(fraction: Double, over: Bool)
}

/// Règles métier de Rituel (section 3 du brief). Aucune dépendance à SwiftData ni à SwiftUI.
enum HabitEngine {
    static func plural(_ n: Double, _ singular: String, _ pluralForm: String? = nil) -> String {
        n > 1 ? (pluralForm ?? singular + "s") : singular
    }

    // MARK: Statut d'une carte

    static func status(_ habit: HabitSpec, total: Double) -> HabitStatus {
        let c = QuantityFormat.r2(total), t = QuantityFormat.r2(habit.target)
        let q = { (v: Double) in QuantityFormat.quantity(QuantityFormat.r2(v), for: habit) }
        switch habit.kind {
        case .limit:
            if c > t { return HabitStatus(tone: .over, label: "Dépassé de \(q(c - t))") }
            if t == 0 { return HabitStatus(tone: .ok, label: "Rien noté, bravo") }
            if c == t { return HabitStatus(tone: .edge, label: "Limite atteinte") }
            let left = t - c
            let word = habit.isAmount ? "possible" : plural(left, "possible")
            return HabitStatus(tone: .ok, label: "Encore \(q(left)) \(word)")
        case .goal:
            if c > t { return HabitStatus(tone: .done, label: "Objectif dépassé, +\(q(c - t))") }
            if c == t { return HabitStatus(tone: .done, label: "Objectif atteint") }
            return HabitStatus(tone: .progress, label: "Encore \(QuantityFormat.quantityWithUnit(QuantityFormat.r2(t - c), for: habit))")
        }
    }

    // MARK: Textes

    /// « Pas plus de 1 par semaine », « Au moins 8h par jour ».
    static func ruleText(_ habit: HabitSpec) -> String {
        let p = habit.period.word
        switch habit.kind {
        case .limit:
            if habit.target == 0 { return "Aucun par \(p)" }
            return "Pas plus de \(QuantityFormat.quantity(habit.target, for: habit)) par \(p)"
        case .goal:
            if habit.isAmount { return "Au moins \(QuantityFormat.value(habit.target, for: habit)) par \(p)" }
            return "Au moins \(QuantityFormat.number(habit.target)) fois par \(p)"
        }
    }

    /// Aperçu en phrase de la feuille d'édition : « Sommeil : au moins 8h par jour. »
    static func previewText(_ habit: HabitSpec) -> String {
        let trimmed = habit.name.trimmingCharacters(in: .whitespaces)
        let name = trimmed.isEmpty ? "cette habitude" : trimmed
        let p = habit.period.word
        if habit.isAmount {
            let v = QuantityFormat.value(habit.target, for: habit)
            return "\(name) : \(habit.kind == .limit ? "pas plus de" : "au moins") \(v) par \(p)."
        }
        let t = QuantityFormat.number(habit.target)
        switch habit.kind {
        case .limit:
            return (habit.target == 0 ? "Aucun·e \(name.lowercased())" : "Pas plus de \(t) \(name.lowercased())") + " par \(p)."
        case .goal:
            return "\(name) au moins \(t) fois par \(p)."
        }
    }

    // MARK: Saisie

    static func newValue(for action: EntryAction, current: Double) -> Double {
        switch action {
        case .increment: current + 1
        case .decrement: max(0, current - 1)
        case .set(let v): QuantityFormat.r2(current) == QuantityFormat.r2(v) ? 0 : v
        case .add(let v): QuantityFormat.r2(current + v)
        case .replace(let v): max(0, v)
        case .clear: 0
        }
    }

    // MARK: Accueil

    static func greeting(name: String, hour: Int) -> String {
        let hello = hour < 5 || hour >= 18 ? "Bonsoir" : "Bonjour"
        let n = name.trimmingCharacters(in: .whitespaces)
        return n.isEmpty ? hello : "\(hello) \(n)"
    }

    static func lede(overLimits: Int, habitCount: Int) -> String {
        if habitCount == 0 { return "Ajoute une première habitude pour commencer." }
        switch overLimits {
        case 0: return "Tout est en équilibre. Continue à ton rythme."
        case 1: return "Une limite a été dépassée. Ce n'est qu'un moment, la suite reste à écrire."
        default: return "\(overLimits) limites ont été dépassées. Respire, on regarde ça calmement dans le récap."
        }
    }

    /// Limites dépassées sur les périodes qui contiennent `day`.
    static func overLimitCount(_ habits: [HabitSpec], log: EntryLog, day: Date) -> Int {
        habits.filter {
            $0.kind == .limit && QuantityFormat.r2(log.total($0, periodContaining: day)) > QuantityFormat.r2($0.target)
        }.count
    }

    // MARK: Visualisations

    static func isDayKept(_ habit: HabitSpec, value: Double) -> Bool {
        let c = QuantityFormat.r2(value), t = QuantityFormat.r2(habit.target)
        return habit.kind == .limit ? c <= t : c >= t
    }

    static func dayCell(_ habit: HabitSpec, value: Double, day: Date, today: Date) -> DayCellState {
        if day > today { return .future }
        if isDayKept(habit, value: value) { return .ok }
        // Un objectif du jour pas encore atteint aujourd'hui n'est pas raté.
        if habit.kind == .goal && day == today { return .neutral }
        return .over
    }

    /// Pilules (une par unité de la cible) ou barre si la cible dépasse 12 ou pour une quantité.
    static func progress(_ habit: HabitSpec, total: Double) -> ProgressDisplay {
        let c = QuantityFormat.r2(total), t = QuantityFormat.r2(habit.target)
        if habit.isAmount {
            let fraction = t > 0 ? min(1, c / t) : (c > 0 ? 1 : 0)
            return .bar(fraction: fraction, over: habit.kind == .limit && c > t)
        }
        switch habit.kind {
        case .limit:
            if max(t, c) > 12 { return .bar(fraction: min(1, c / max(t, 1)), over: c > t) }
            let n = Int(max(t, c))
            return .pips((0..<n).map { i in
                Double(i) < c ? (Double(i) < t ? .on : .over) : .empty
            })
        case .goal:
            if t > 12 { return .bar(fraction: min(1, c / t), over: false) }
            let base: [PipState] = (0..<Int(t)).map { Double($0) < c ? .on : .empty }
            let bonus = max(0, min(Int(c), Int(t) + 4) - Int(t))
            return .pips(base + Array(repeating: .bonus, count: bonus))
        }
    }
}
