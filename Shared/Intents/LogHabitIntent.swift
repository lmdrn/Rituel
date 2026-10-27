import AppIntents
import Foundation

/// Saisie rapide depuis un bouton de widget, pour aujourd'hui.
struct LogHabitIntent: AppIntent {
    static let title: LocalizedStringResource = "Noter une habitude depuis un widget"
    static let isDiscoverable = false

    @Parameter(title: "Habitude")
    var habitID: String

    /// `increment`, `add` ou `set`.
    @Parameter(title: "Action")
    var kind: String

    @Parameter(title: "Valeur")
    var value: Double

    init() {}

    init(habitID: UUID, action: EntryAction) {
        self.habitID = habitID.uuidString
        switch action {
        case .add(let v):
            kind = "add"
            value = v
        case .set(let v):
            kind = "set"
            value = v
        default:
            kind = "increment"
            value = 1
        }
    }

    var entryAction: EntryAction {
        switch kind {
        case "add": .add(value)
        case "set": .set(value)
        default: .increment
        }
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        guard let id = UUID(uuidString: habitID) else { return .result() }
        // L'écrivain recharge aussi les timelines de tous les widgets.
        EntryWriter(context: RituelStore.shared.mainContext).apply(entryAction, habitID: id, day: .now)
        return .result()
    }
}
