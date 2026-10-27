import Foundation

/// Formatage des quantités en français : virgule décimale, heures en « 7h30 », litres en « 1,5L ».
enum QuantityFormat {
    static let nbsp = "\u{00A0}"

    /// Arrondi au centième, pour comparer et afficher sans artefacts de virgule flottante.
    static func r2(_ value: Double) -> Double {
        (value * 100).rounded() / 100
    }

    /// 7.5 → « 7,5 », 2000 → « 2000 », 1 → « 1 ».
    static func number(_ value: Double) -> String {
        let v = r2(value)
        if v == v.rounded() { return String(Int(v)) }
        var s = String(format: "%.2f", v)
        while s.hasSuffix("0") { s.removeLast() }
        return s.replacingOccurrences(of: ".", with: ",")
    }

    /// Valeur dans l'unité de l'habitude. `short` sert aux petites cases et aux boutons.
    static func value(_ value: Double, for habit: HabitSpec, short: Bool = false) -> String {
        let v = r2(value)
        guard habit.isAmount else { return number(v) }
        let unit = habit.trimmedUnit
        switch unit {
        case "h":
            return hoursMinutes(totalMinutes: Int((v * 60).rounded()))
        case "min" where short && v >= 60:
            return hoursMinutes(totalMinutes: Int(v.rounded()))
        case "ml" where v >= 1000:
            return number((v / 100).rounded() / 10) + "L"
        case "ml" where short:
            return number(v)
        default:
            guard !unit.isEmpty else { return number(v) }
            return number(v) + (short ? "" : nbsp) + unit
        }
    }

    /// Quantité nue pour un comptage, avec unité pour une mesure (« 1 », « 7h30 »).
    static func quantity(_ value: Double, for habit: HabitSpec) -> String {
        habit.isAmount ? self.value(value, for: habit) : number(value)
    }

    /// Comme `quantity`, avec « fois » pour un comptage (« 2 fois »).
    static func quantityWithUnit(_ value: Double, for habit: HabitSpec) -> String {
        habit.isAmount ? self.value(value, for: habit) : number(value) + " fois"
    }

    private static func hoursMinutes(totalMinutes: Int) -> String {
        let h = totalMinutes / 60, m = totalMinutes % 60
        return m == 0 ? "\(h)h" : "\(h)h" + String(format: "%02d", m)
    }
}
