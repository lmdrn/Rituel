import Foundation
import SwiftData
import WidgetKit

enum SharedDefaults {
    /// Réglages partagés entre l'app et le widget.
    static var store: UserDefaults { UserDefaults(suiteName: AppConfig.appGroup) ?? .standard }

    static let firstNameKey = "firstName"
    static let healthSleepImportKey = "healthSleepImport"
    static let remindersEnabledKey = "remindersEnabled"
}

/// Crée, modifie, réordonne et supprime les habitudes.
@MainActor
struct HabitWriter {
    let context: ModelContext

    func save(_ spec: HabitSpec) {
        let id = spec.id
        let existing = try? context.fetch(FetchDescriptor<Habit>(predicate: #Predicate { $0.id == id })).first
        if let existing {
            existing.update(from: spec)
        } else {
            context.insert(Habit(spec))
        }
        commit()
    }

    /// Supprime l'habitude et toutes ses saisies, puis resserre l'ordre.
    func delete(_ habitID: UUID) {
        let optionalID: UUID? = habitID
        let entries = (try? context.fetch(FetchDescriptor<Entry>(predicate: #Predicate { $0.habitID == optionalID }))) ?? []
        entries.forEach(context.delete)
        var habits = allHabits()
        habits.filter { $0.id == habitID }.forEach(context.delete)
        habits.removeAll { $0.id == habitID }
        renumber(habits)
        commit()
    }

    /// Applique un nouvel ordre (identifiants dans l'ordre voulu).
    func reorder(_ orderedIDs: [UUID]) {
        let byID = Dictionary(allHabits().map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
        renumber(orderedIDs.compactMap { byID[$0] })
        commit()
    }

    /// Après une synchro iCloud : deux appareils ont pu créer les mêmes habitudes par défaut, ou noter le même jour.
    /// On garde l'habitude la plus ancienne et l'entrée la plus récente.
    func removeSyncDuplicates() {
        let habits = allHabits()
        let extraHabits = Deduplication.redundant(habits, key: \.id) { $0.createdAt < $1.createdAt }
        let entries = (try? context.fetch(FetchDescriptor<Entry>())) ?? []
        let extraEntries = Deduplication.redundant(entries, key: { EntryKey(habitID: $0.habitID, day: $0.day) }) {
            $0.updatedAt > $1.updatedAt
        }
        guard !extraHabits.isEmpty || !extraEntries.isEmpty else { return }
        extraHabits.forEach { context.delete(habits[$0]) }
        extraEntries.forEach { context.delete(entries[$0]) }
        let removed = Set(extraHabits)
        renumber(habits.indices.filter { !removed.contains($0) }.map { habits[$0] })
        commit()
    }

    private struct EntryKey: Hashable {
        let habitID: UUID?
        let day: Date
    }

    private func allHabits() -> [Habit] {
        (try? context.fetch(FetchDescriptor<Habit>(sortBy: [SortDescriptor(\.sortIndex)]))) ?? []
    }

    private func renumber(_ habits: [Habit]) {
        for (index, habit) in habits.enumerated() where habit.sortIndex != index {
            habit.sortIndex = index
        }
    }

    private func commit() {
        try? context.save()
        WidgetCenter.shared.reloadAllTimelines()
    }
}

enum RituelStore {
    static let schema = Schema([Habit.self, Entry.self])

    /// Seule l'app synchronise avec iCloud. Le widget ouvre la même base locale, sans CloudKit,
    /// pour qu'un seul processus fasse la synchro.
    static let syncsWithCloud = Bundle.main.bundleURL.pathExtension == "app"

    /// Conteneur unique du processus (app ou widget). Les deux ouvrent la même base dans l'App Group.
    static let shared: ModelContainer = {
        if syncsWithCloud, let container = try? makeContainer(cloudKit: true) { return container }
        // Sans iCloud configuré (pas de Team ID, simulateur), on garde la base locale.
        do {
            return try makeContainer()
        } catch {
            fatalError("Impossible d'ouvrir la base Rituel : \(error)")
        }
    }()

    /// Base SwiftData dans l'App Group, lue et écrite par l'app et le widget.
    static func makeContainer(inMemory: Bool = false, cloudKit: Bool = false) throws -> ModelContainer {
        let configuration = inMemory
            ? ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
            : ModelConfiguration(schema: schema, url: storeURL,
                                 cloudKitDatabase: cloudKit ? .private(AppConfig.cloudKitContainer) : .none)
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    static var storeURL: URL {
        if let group = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: AppConfig.appGroup) {
            return group.appending(path: "Rituel.store")
        }
        let support = URL.applicationSupportDirectory
        try? FileManager.default.createDirectory(at: support, withIntermediateDirectories: true)
        return support.appending(path: "Rituel.store")
    }
}

/// Écrit les saisies : une entrée par habitude et par jour, supprimée quand la valeur retombe à 0.
@MainActor
struct EntryWriter {
    let context: ModelContext
    var calendar: RituelCalendar = .current

    /// Applique l'action et renvoie la nouvelle valeur du jour.
    @discardableResult
    func apply(_ action: EntryAction, habitID: UUID, day: Date, now: Date = .now) -> Double {
        let start = calendar.day(day)
        guard start <= calendar.day(now) else { return 0 }
        let existing = entries(habitID: habitID, day: start)
        let current = existing.max(by: { $0.updatedAt < $1.updatedAt })?.value ?? 0
        let value = HabitEngine.newValue(for: action, current: current)

        // Supprimer puis recréer plutôt que modifier : l'app et le widget gardent chacun des objets en mémoire,
        // et une nouvelle ligne est toujours relue correctement par l'autre processus.
        existing.forEach(context.delete)
        if value > 0 { context.insert(Entry(habitID: habitID, day: start, value: value, updatedAt: now)) }
        didChange()
        return value
    }

    /// Valeur importée (Santé) : n'écrase jamais une saisie faite à la main. Renvoie `true` si elle a été écrite.
    @discardableResult
    func importValue(_ value: Double, habitID: UUID, day: Date, source: String, now: Date = .now) -> Bool {
        let start = calendar.day(day)
        let existing = entries(habitID: habitID, day: start)
        guard !existing.contains(where: { $0.source == nil }) else { return false }
        if let current = existing.first, QuantityFormat.r2(current.value) == QuantityFormat.r2(value) { return false }
        existing.forEach(context.delete)
        if value > 0 { context.insert(Entry(habitID: habitID, day: start, value: value, updatedAt: now, source: source)) }
        didChange()
        return true
    }

    private func didChange() {
        try? context.save()
        WidgetCenter.shared.reloadAllTimelines()
        Task { await ReminderScheduler.sync() }
    }

    func entries(habitID: UUID, day start: Date) -> [Entry] {
        let end = calendar.adding(days: 1, to: start)
        let id: UUID? = habitID
        let descriptor = FetchDescriptor<Entry>(predicate: #Predicate {
            $0.habitID == id && $0.day >= start && $0.day < end
        })
        return (try? context.fetch(descriptor)) ?? []
    }
}
