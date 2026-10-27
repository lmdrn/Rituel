import Foundation

/// Brouillon de la feuille de création / édition d'une habitude, avec les mêmes réflexes que la version web
/// (presets par défaut selon l'unité, cible cohérente quand on change de type ou de mesure).
struct HabitDraft: Identifiable, Sendable {
    enum Problem: Equatable, Sendable {
        case missingName
        case missingTarget
    }

    static let maxUnitLength = 8
    static let maxCountTarget: Double = 99

    var spec: HabitSpec
    /// Saisie libre des choix rapides (« 6  6.5  7 »).
    private(set) var presetsText: String
    let isNew: Bool

    var id: UUID { spec.id }

    /// Nouvelle habitude : une limite d'une fois par semaine, dans la première couleur libre.
    init(newWithSortIndex sortIndex: Int, usedColors: Set<String> = []) {
        let color = HabitColor.allCases.first { !usedColors.contains($0.rawValue) } ?? .citron
        spec = HabitSpec(kind: .limit, target: 1, period: .week, colorKey: color.rawValue, measure: .count,
                         unit: "h", entryMode: .set, presets: [], sortIndex: sortIndex)
        presetsText = ""
        isNew = true
    }

    init(editing spec: HabitSpec) {
        self.spec = spec
        if spec.isAmount && spec.presets.isEmpty { self.spec.presets = HabitSpec.defaultPresets(for: spec.trimmedUnit) }
        presetsText = Self.text(for: self.spec.presets)
        isNew = false
    }

    // MARK: Modifications

    mutating func setName(_ name: String) {
        spec.name = String(name.prefix(HabitSpec.maxNameLength))
    }

    mutating func setKind(_ kind: HabitKind) {
        spec.kind = kind
        if !spec.isAmount && kind == .goal && spec.target < 1 { spec.target = 1 }
    }

    mutating func setMeasure(_ measure: HabitMeasure) {
        spec.measure = measure
        switch measure {
        case .amount:
            if spec.trimmedUnit.isEmpty { spec.unit = "h" }
            if spec.presets.isEmpty { setPresets(HabitSpec.defaultPresets(for: spec.trimmedUnit)) }
            // Passer aux heures avec une petite cible : on pense au sommeil.
            if spec.trimmedUnit == "h" && spec.target < 4 {
                spec.target = 8
                spec.kind = .goal
            }
        case .count:
            spec.target = max(spec.kind == .goal ? 1 : 0, spec.target.rounded())
            if spec.target > Self.maxCountTarget { spec.target = 1 }
        }
    }

    mutating func setUnit(_ unit: String) {
        let old = spec.trimmedUnit
        spec.unit = String(unit.prefix(Self.maxUnitLength))
        let new = spec.trimmedUnit
        // Les presets suivent l'unité tant qu'on ne les a pas personnalisés.
        let defaults = HabitSpec.defaultPresets(for: new)
        let untouched = presetsText.trimmingCharacters(in: .whitespaces).isEmpty
            || presetsText == Self.text(for: HabitSpec.defaultPresets(for: old))
        if Self.knownUnits.contains(new) && untouched { setPresets(defaults) }
        if new == "ml" { spec.entryMode = .add }
    }

    mutating func setEntryMode(_ mode: EntryMode) {
        spec.entryMode = mode
    }

    mutating func setPresetsText(_ text: String) {
        presetsText = text
        spec.presets = HabitSpec.parsePresets(text)
    }

    /// Cible d'une quantité, saisie avec une virgule ou un point.
    mutating func setTargetText(_ text: String) {
        let v = Double(text.replacingOccurrences(of: ",", with: ".").trimmingCharacters(in: .whitespaces)) ?? 0
        spec.target = v.isFinite && v >= 0 ? v : 0
    }

    var targetText: String {
        QuantityFormat.number(spec.target)
    }

    /// Stepper des comptages : de 1 (objectif) ou 0 (limite) à 99.
    mutating func stepTarget(by delta: Int) {
        let low: Double = spec.kind == .goal ? 1 : 0
        spec.target = min(Self.maxCountTarget, max(low, spec.target.rounded() + Double(delta)))
    }

    var canDecrement: Bool { spec.target > (spec.kind == .goal ? 1 : 0) }
    var canIncrement: Bool { spec.target < Self.maxCountTarget }

    mutating func setPeriod(_ period: HabitPeriod) { spec.period = period }

    // MARK: Santé et modèles

    /// Sources Santé qui correspondent à ce que mesure l'habitude.
    var compatibleHealthSources: [HealthSource] { HealthSource.allCases.filter { $0.fits(spec) } }

    mutating func setHealthSource(_ source: HealthSource?) {
        spec.healthSource = source
        if let source { spec.entryMode = source.entryMode }
    }

    mutating func setHealthMinMinutes(_ minutes: Int) { spec.healthMinMinutes = max(0, min(240, minutes)) }
    mutating func setHealthWorkoutKind(_ kind: WorkoutKind?) { spec.healthWorkoutKind = kind }

    /// Part d'un modèle (« 10 000 pas par jour ») en gardant l'identité et la place de la nouvelle habitude.
    mutating func apply(template: HabitSpec) {
        let id = spec.id, index = spec.sortIndex
        spec = template
        spec.id = id
        spec.sortIndex = index
        presetsText = Self.text(for: template.presets)
    }
    mutating func setColor(_ color: HabitColor) { spec.colorKey = color.rawValue }
    mutating func setReminder(minutes: Int?) { spec.reminderMinutes = minutes }

    // MARK: Validation

    var problem: Problem? {
        if spec.name.trimmingCharacters(in: .whitespaces).isEmpty { return .missingName }
        if spec.isAmount && spec.kind == .goal && !(spec.target > 0) { return .missingTarget }
        return nil
    }

    /// L'habitude prête à enregistrer, ou `nil` si un champ manque.
    func finalized() -> HabitSpec? {
        guard problem == nil else { return nil }
        var s = spec
        s.name = s.name.trimmingCharacters(in: .whitespaces)
        if s.isAmount {
            s.unit = s.trimmedUnit
            if s.presets.isEmpty { s.presets = HabitSpec.defaultPresets(for: s.trimmedUnit) }
        } else {
            s.unit = nil
            s.entryMode = .set
            s.presets = []
            s.target = s.target.rounded()
        }
        // Une source Santé qui ne correspond plus à la mesure (après un changement d'unité) est retirée.
        if let source = s.healthSource, !source.fits(s) { s.healthSource = nil }
        if s.healthSource != .workouts {
            s.healthMinMinutes = 0
            s.healthWorkoutKind = nil
        }
        return s
    }

    var previewText: String { HabitEngine.previewText(spec) }

    // MARK: Aides

    private static let knownUnits: Set<String> = ["h", "ml", "min", "km", "pas"]

    private mutating func setPresets(_ values: [Double]) {
        spec.presets = values
        presetsText = Self.text(for: values)
    }

    private static func text(for presets: [Double]) -> String {
        presets.map { String(QuantityFormat.number($0)).replacingOccurrences(of: ",", with: ".") }.joined(separator: "  ")
    }
}
