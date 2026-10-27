import AppIntents
import SwiftUI
import WidgetKit

/// Fond commun des widgets : lavande très clair avec un halo pervenche, et une marguerite en filigrane.
struct WidgetBackdrop: View {
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Color.surface
            RadialGradient(colors: [Color.accent.opacity(0.08), .clear], center: .topTrailing, startRadius: 0, endRadius: 200)
            DaisyPetals()
                .fill(Color.accent.opacity(0.06))
                .frame(width: 140, height: 140)
                .offset(x: 46, y: 46)
        }
    }
}

/// Marguerite de progression d'une habitude dans un widget.
struct WidgetDaisy: View {
    let habit: WidgetHabit

    var body: some View {
        Daisy(habit: habit.spec, total: habit.total, blooms: false)
            .widgetAccentable()
            .accessibilityHidden(true)
    }
}

/// Bouton gelée pervenche de saisie rapide, qui note directement depuis le widget.
struct QuickButton: View {
    let habit: WidgetHabit
    var size: CGFloat = 54
    var fontSize: CGFloat = 15

    var body: some View {
        Button(intent: LogHabitIntent(habitID: habit.id, action: habit.quick.action)) {
            Text(verbatim: habit.quick.label)
                .font(.rituel(.title, size: fontSize, relativeTo: .body))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .foregroundStyle(.accentInk)
                .padding(.horizontal, 4)
                .frame(width: size, height: size)
                .background(Color.accent, in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(verbatim: "Noter \(habit.spec.name), \(habit.quick.label)"))
    }
}

struct WidgetHabitName: View {
    let habit: WidgetHabit
    var font: Font = .rituel(.title, size: 15, relativeTo: .subheadline)

    var body: some View {
        Text(habit.spec.name)
            .font(font)
            .foregroundStyle(.ink)
            .lineLimit(1)
    }
}

/// « 1,3L / 2L »
struct WidgetValue: View {
    let habit: WidgetHabit
    var size: CGFloat = 26

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 3) {
            Text(verbatim: habit.totalText)
                .font(.rituel(.title, size: size, relativeTo: .title))
                .foregroundStyle(.ink)
                .contentTransition(.numericText())
            Text(verbatim: "/ \(habit.targetText)")
                .font(.rituel(.semibold, size: max(11, size * 0.45), relativeTo: .caption))
                .foregroundStyle(.ink2)
        }
        .monospacedDigit()
        .lineLimit(1)
        .minimumScaleFactor(0.6)
        .invalidatableContent()
    }
}

struct WidgetEmptyState: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            BrandMark(size: 26)
            Spacer()
            Text("Ouvre Rituel pour créer tes habitudes.")
                .font(.rituelCallout)
                .foregroundStyle(.ink2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

extension StatusTone {
    var colors: (fg: Color, bg: Color) {
        switch self {
        case .ok: (.ok, .okSoft)
        case .done: (.sunText, .edgeSoft)
        case .edge: (.edge, .edgeSoft)
        case .over: (.over, .overSoft)
        case .progress: (.accentText, .accentSoft)
        }
    }
}

struct WidgetChip: View {
    let status: HabitStatus

    var body: some View {
        Text(verbatim: status.label)
            .font(.rituel(.bold, size: 11, relativeTo: .caption2))
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .foregroundStyle(status.tone.colors.fg)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(status.tone.colors.bg, in: Capsule())
    }
}
