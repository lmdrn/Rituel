import AppIntents
import Foundation

/// Une habitude telle que la voient les widgets configurables, Raccourcis et Siri.
struct HabitEntity: AppEntity, Identifiable {
    let id: UUID
    let name: String
    let isAmount: Bool

    init(spec: HabitSpec) {
        id = spec.id
        name = spec.name
        isAmount = spec.isAmount
    }

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Habitude"
    static let defaultQuery = HabitEntityQuery()

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }
}

struct HabitEntityQuery: EntityQuery {
    func entities(for identifiers: [UUID]) async throws -> [HabitEntity] {
        WidgetDataLoader.habitEntities().filter { identifiers.contains($0.id) }
    }

    func suggestedEntities() async throws -> [HabitEntity] {
        WidgetDataLoader.habitEntities()
    }
}
