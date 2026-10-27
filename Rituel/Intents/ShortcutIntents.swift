import AppIntents
import Foundation

enum RituelIntentError: Error, CustomLocalizedStringResourceConvertible {
    case habitNotFound
    case noWaterHabit

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .habitNotFound: "Je ne trouve pas cette habitude dans Rituel."
        case .noWaterHabit: "Il n'y a pas d'habitude d'eau en millilitres dans Rituel."
        }
    }
}

/// « Noter une habitude » : +1, ou une quantité, pour aujourd'hui.
struct LogHabitShortcutIntent: AppIntent {
    static let title: LocalizedStringResource = "Noter une habitude"
    static let description = IntentDescription("Note une habitude pour aujourd'hui dans Rituel.")

    @Parameter(title: "Habitude")
    var habit: HabitEntity

    @Parameter(title: "Quantité", description: "Pour une quantité, la valeur à noter. Sans valeur : le choix rapide habituel.")
    var amount: Double?

    static var parameterSummary: some ParameterSummary {
        Summary("Noter \(\.$habit)") {
            \.$amount
        }
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let current = WidgetDataLoader.load().habits.first(where: { $0.id == habit.id }) else {
            throw RituelIntentError.habitNotFound
        }
        let spec = current.spec
        let action: EntryAction = switch (spec.measure, spec.entryMode) {
        case (.count, _): .increment
        case (.amount, .add): .add(amount ?? current.quick.action.amount ?? 1)
        case (.amount, .set): .replace(amount ?? current.quick.action.amount ?? spec.target)
        }
        EntryWriter(context: RituelStore.shared.mainContext).apply(action, habitID: spec.id, day: .now)
        return .result(dialog: "\(Self.confirmation(for: spec.id))")
    }

    @MainActor
    static func confirmation(for habitID: UUID) -> String {
        guard let h = WidgetDataLoader.load().habits.first(where: { $0.id == habitID }) else { return "C'est noté." }
        return "C'est noté : \(h.spec.name), \(h.totalText) sur \(h.targetText). \(h.status.label)."
    }
}

/// « Ajouter de l'eau » : ajoute une quantité à l'habitude Eau.
struct AddWaterIntent: AppIntent {
    static let title: LocalizedStringResource = "Ajouter de l'eau"
    static let description = IntentDescription("Ajoute un verre d'eau à ton habitude Eau dans Rituel.")

    @Parameter(title: "Quantité (ml)", default: 250)
    var amount: Double

    static var parameterSummary: some ParameterSummary {
        Summary("Ajouter \(\.$amount) ml d'eau")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let water = DefaultHabits.waterHabit(in: WidgetDataLoader.load().habits.map(\.spec)) else {
            throw RituelIntentError.noWaterHabit
        }
        EntryWriter(context: RituelStore.shared.mainContext).apply(.add(max(0, amount)), habitID: water.id, day: .now)
        return .result(dialog: "\(LogHabitShortcutIntent.confirmation(for: water.id))")
    }
}

struct RituelShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: LogHabitShortcutIntent(),
            phrases: [
                "Noter \(\.$habit) dans \(.applicationName)",
                "Noter une habitude dans \(.applicationName)",
            ],
            shortTitle: "Noter une habitude",
            systemImageName: "checkmark.circle"
        )
        AppShortcut(
            intent: AddWaterIntent(),
            phrases: [
                "Ajouter de l'eau dans \(.applicationName)",
                "J'ai bu de l'eau dans \(.applicationName)",
            ],
            shortTitle: "Ajouter de l'eau",
            systemImageName: "drop"
        )
    }
}
