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

/// Donnée de l'app Santé qui peut remplir une habitude. Garmin Connect, Strava ou l'Apple Watch y écrivent ;
/// Rituel ne lit que Santé, sans compte ni serveur.
enum HealthSource: String, Codable, CaseIterable, Identifiable, Sendable {
    /// Sommeil réel (phases de sommeil), en heures, valeur du jour.
    case sleep
    /// Nombre de séances de sport du jour.
    case workouts
    /// Eau bue, en ml.
    case water
    /// Nombre de pas.
    case steps
    /// Minutes de pleine conscience.
    case mindful

    var id: Self { self }

    var title: String {
        switch self {
        case .sleep: "Sommeil"
        case .workouts: "Séances de sport"
        case .water: "Eau"
        case .steps: "Pas"
        case .mindful: "Pleine conscience"
        }
    }

    /// Ce que l'habitude doit mesurer pour recevoir cette donnée.
    var measure: HabitMeasure { self == .workouts ? .count : .amount }
    var unit: String? {
        switch self {
        case .sleep: "h"
        case .workouts: nil
        case .water: "ml"
        case .steps: "pas"
        case .mindful: "min"
        }
    }
    var entryMode: EntryMode { self == .sleep ? .set : .add }

    /// Source qui correspond naturellement à une habitude (pour la proposer dans la feuille).
    static func suggested(for habit: HabitSpec) -> HealthSource? {
        allCases.first { $0.fits(habit) && ($0 != .workouts || habit.name.lowercased().contains("sport")) }
    }

    func fits(_ habit: HabitSpec) -> Bool {
        habit.measure == measure && (unit == nil || habit.trimmedUnit == unit)
    }
}

/// Types de séances proposés pour filtrer le sport.
enum WorkoutKind: String, Codable, CaseIterable, Identifiable, Sendable {
    case running, cycling, walking, swimming, strength, yoga

    var id: Self { self }

    var title: String {
        switch self {
        case .running: "Course"
        case .cycling: "Vélo"
        case .walking: "Marche"
        case .swimming: "Natation"
        case .strength: "Renforcement"
        case .yoga: "Yoga"
        }
    }
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
    /// Place dans le résumé d'Aujourd'hui (0, 1, 2), ou `nil` si l'habitude n'y figure pas.
    var summaryRank: Int?
    /// Donnée Santé qui remplit l'habitude automatiquement, ou `nil` pour une saisie à la main seulement.
    var healthSource: HealthSource?
    /// Pour les séances de sport : durée minimale en minutes (0 = toutes) et type d'activité (`nil` = tous).
    var healthMinMinutes: Int = 0
    var healthWorkoutKind: WorkoutKind?

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
