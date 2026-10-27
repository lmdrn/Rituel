import SwiftUI
import WidgetKit

/// Petit widget : une habitude au choix, son total, son statut et un gros bouton de saisie.
struct HabitWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: "fr.rituel.habit", intent: SelectHabitIntent.self, provider: HabitProvider()) { entry in
            HabitWidgetView(entry: entry)
                .containerBackground(for: .widget) { WidgetBackdrop() }
        }
        .configurationDisplayName("Une habitude")
        .description("Note en un geste l'habitude de ton choix.")
        .supportedFamilies([.systemSmall])
    }
}

struct HabitWidgetView: View {
    let entry: RituelEntry

    var body: some View {
        if let habit = entry.data.habit(entry.habitID) {
            VStack(alignment: .leading, spacing: 6) {
                WidgetHabitName(habit: habit)
                Spacer(minLength: 0)
                HStack(alignment: .bottom, spacing: 6) {
                    WidgetValue(habit: habit, size: 24)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    QuickButton(habit: habit, size: 54)
                }
                WidgetChip(status: habit.status)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        } else {
            WidgetEmptyState()
        }
    }
}

#Preview(as: .systemSmall) {
    HabitWidget()
} timeline: {
    RituelEntry(date: .now, data: .sample, habitID: DefaultHabits.specs[1].id)
    RituelEntry(date: .now, data: .sample, habitID: DefaultHabits.specs[2].id)
}
