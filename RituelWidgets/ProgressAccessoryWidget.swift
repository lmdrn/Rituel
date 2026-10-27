import SwiftUI
import WidgetKit

/// Écran verrouillé : la progression d'une habitude au choix (ex. eau 1,3L / 2L).
struct ProgressAccessoryWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: "fr.rituel.progress", intent: SelectHabitIntent.self, provider: HabitProvider()) { entry in
            ProgressAccessoryView(entry: entry)
                .containerBackground(for: .widget) { Color.clear }
        }
        .configurationDisplayName("Progression")
        .description("Où tu en es pour une habitude.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular])
    }
}

struct ProgressAccessoryView: View {
    let entry: RituelEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        if let habit = entry.data.habit(entry.habitID, preferAmount: true) {
            switch family {
            case .accessoryCircular: circular(habit)
            default: rectangular(habit)
            }
        } else {
            Image(systemName: "leaf")
        }
    }

    private func circular(_ habit: WidgetHabit) -> some View {
        Gauge(value: habit.fraction) {
            Text(habit.spec.name)
        } currentValueLabel: {
            Text(verbatim: habit.totalText)
                .font(.rituel(.semibold, size: 13, relativeTo: .caption))
                .minimumScaleFactor(0.5)
        }
        .gaugeStyle(.accessoryCircularCapacity)
        .widgetAccentable()
        .accessibilityLabel(Text(verbatim: "\(habit.spec.name), \(habit.totalText) sur \(habit.targetText)"))
    }

    private func rectangular(_ habit: WidgetHabit) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(habit.spec.name)
                .font(.rituel(.bold, size: 14, relativeTo: .headline))
                .widgetAccentable()
            Text(verbatim: "\(habit.totalText) / \(habit.targetText)")
                .font(.rituel(.regular, size: 13, relativeTo: .body))
                .monospacedDigit()
            Gauge(value: habit.fraction) { EmptyView() }
                .gaugeStyle(.accessoryLinearCapacity)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

#Preview("Cercle", as: .accessoryCircular) {
    ProgressAccessoryWidget()
} timeline: {
    RituelEntry(date: .now, data: .sample)
}

#Preview("Rectangle", as: .accessoryRectangular) {
    ProgressAccessoryWidget()
} timeline: {
    RituelEntry(date: .now, data: .sample)
}
