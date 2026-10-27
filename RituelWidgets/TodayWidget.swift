import SwiftUI
import WidgetKit

/// Moyen : 4 habitudes avec leur bouton. Grand : toutes les habitudes et le score d'équilibre de la semaine.
struct TodayWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "fr.rituel.today", provider: TodayProvider()) { entry in
            TodayWidgetView(entry: entry)
                .containerBackground(for: .widget) { WidgetBackdrop() }
        }
        .configurationDisplayName("Ma journée")
        .description("Tes habitudes du jour, à noter d'un geste.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

struct TodayWidgetView: View {
    let entry: RituelEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        if entry.data.habits.isEmpty {
            WidgetEmptyState()
        } else if family == .systemLarge {
            large
        } else {
            medium
        }
    }

    private var medium: some View {
        let habits = Array(entry.data.habits.prefix(4))
        return Grid(horizontalSpacing: 8, verticalSpacing: 8) {
            ForEach(0..<2, id: \.self) { row in
                GridRow {
                    ForEach(0..<2, id: \.self) { column in
                        let i = row * 2 + column
                        if i < habits.count { CompactTile(habit: habits[i]) } else { Color.clear }
                    }
                }
            }
        }
    }

    private var large: some View {
        let calendar = RituelCalendar.current
        let habits = Array(entry.data.habits.prefix(7))
        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(verbatim: calendar.longDate(entry.data.today))
                        .font(.rituelEyebrow)
                        .textCase(.uppercase)
                        .foregroundStyle(.ink3)
                    Text("Ma journée")
                        .font(.rituelTitle)
                        .foregroundStyle(.ink)
                }
                Spacer()
                HStack(alignment: .firstTextBaseline, spacing: 1) {
                    Text(verbatim: "\(entry.data.score)")
                        .font(.rituel(.displayLight, size: 30, relativeTo: .title))
                    Text(verbatim: "%")
                        .font(.rituel(.displayLight, size: 14, relativeTo: .caption))
                }
                .monospacedDigit()
                .foregroundStyle(.accentText)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background { Pebble(shape: Capsule(), lifted: false) }
                .accessibilityLabel(Text(verbatim: "Équilibre de la semaine, \(entry.data.score) %"))
            }
            VStack(spacing: 6) {
                ForEach(habits) { habit in
                    LargeRow(habit: habit)
                }
            }
            Spacer(minLength: 0)
        }
    }
}

/// Tuile du widget moyen.
private struct CompactTile: View {
    let habit: WidgetHabit

    var body: some View {
        HStack(spacing: 6) {
            VStack(alignment: .leading, spacing: 2) {
                WidgetHabitName(habit: habit, font: .rituel(.semibold, size: 13, relativeTo: .subheadline))
                WidgetValue(habit: habit, size: 17)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            QuickButton(habit: habit, size: 38, fontSize: 12)
        }
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .claySurface(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

/// Ligne du grand widget.
private struct LargeRow: View {
    let habit: WidgetHabit

    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 1) {
                WidgetHabitName(habit: habit)
                Text(verbatim: habit.status.label)
                    .font(.rituel(.regular, size: 11, relativeTo: .caption2))
                    .foregroundStyle(habit.status.tone == .progress ? Color.ink2 : habit.status.tone.colors.fg)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            WidgetValue(habit: habit, size: 15)
                .fixedSize()
            QuickButton(habit: habit, size: 34, fontSize: 11)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .claySurface(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

#Preview("Moyen", as: .systemMedium) {
    TodayWidget()
} timeline: {
    RituelEntry(date: .now, data: .sample)
}

#Preview("Grand", as: .systemLarge) {
    TodayWidget()
} timeline: {
    RituelEntry(date: .now, data: .sample)
}
