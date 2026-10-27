import SwiftUI
import WidgetKit

/// Petit widget : une habitude au choix, sa marguerite, son total, son statut et un gros bouton de saisie.
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
            VStack(alignment: .leading, spacing: 4) {
                WidgetHabitName(habit: habit)
                HStack(alignment: .center) {
                    WidgetDaisy(habit: habit).frame(width: 50, height: 50)
                    Spacer(minLength: 4)
                    QuickButton(habit: habit, size: 52)
                }
                .frame(maxHeight: .infinity)
                WidgetValue(habit: habit, size: 20)
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
