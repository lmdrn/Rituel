import Foundation

enum HabitKind: String, Codable, CaseIterable, Sendable {
    /// « Pas plus de ».
    case limit
    /// « Au moins ».
    case goal
}

enum HabitPeriod: String, Codable, CaseIterable, Sendable {
    case day, week, month

    var word: String {
        switch self {
        case .day: "jour"
        case .week: "semaine"
        case .month: "mois"
        }
    }
}

enum HabitMeasure: String, Codable, CaseIterable, Sendable {
    /// Des fois : je coche.
    case count
    /// Une quantité : heures, ml, min…
    case amount
}

enum EntryMode: String, Codable, CaseIterable, Sendable {
    /// Valeur du jour (sommeil).
    case set
    /// J'additionne (eau).
    case add
}

/// Copie immuable d'une habitude, utilisée par le moteur, les vues et le widget.
struct HabitSpec: Identifiable, Hashable, Sendable {
    static let maxNameLength = 40
    static let maxPresets = 8

    var id: UUID = UUID()
    var name: String = ""
    var kind: HabitKind = .limit
    var target: Double = 1
    var period: HabitPeriod = .week
    var colorKey: String = HabitColor.citron.rawValue
    var measure: HabitMeasure = .count
    var unit: String?
    var entryMode: EntryMode = .set
    var presets: [Double] = []
    var sortIndex: Int = 0
    /// Rappel quotidien, en minutes depuis minuit.
    var reminderMinutes: Int?

    var isAmount: Bool { measure == .amount }
    var trimmedUnit: String { (unit ?? "").trimmingCharacters(in: .whitespaces) }
    var color: HabitColor { HabitColor(key: colorKey) }

    /// Choix rapides affichés : ceux de l'habitude, sinon ceux de l'unité.
    var effectivePresets: [Double] {
        presets.isEmpty ? Self.defaultPresets(for: trimmedUnit) : Array(presets.prefix(Self.maxPresets))
    }

    static func defaultPresets(for unit: String) -> [Double] {
        switch unit {
        case "h": [6, 6.5, 7, 7.5, 8, 9]
        case "ml": [250, 500, 1000]
        case "min": [10, 20, 30, 45, 60]
        case "km": [2, 5, 8, 10]
        case "pas": [2000, 5000, 8000, 10000]
        default: [1, 2, 5]
        }
    }

    /// « 6  6,5 7;8 » → [6, 6.5, 7, 8]. Ignore ce qui n'est pas un nombre positif, 8 valeurs au plus.
    static func parsePresets(_ text: String) -> [Double] {
        text.split(whereSeparator: { $0.isWhitespace || $0 == ";" })
            .compactMap { Double($0.replacingOccurrences(of: ",", with: ".")) }
            .filter { $0.isFinite && $0 > 0 }
            .prefix(maxPresets)
            .map { $0 }
    }
}
