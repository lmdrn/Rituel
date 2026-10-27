import AppIntents
import SwiftUI
import WidgetKit

/// Fond commun des widgets : sable, avec une vague douce.
struct WidgetBackdrop: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [.surfaceHigh, .canvas], startPoint: .top, endPoint: .bottom)
            Wave(phase: 0.6, amplitude: 0.1, baseline: 0.2)
                .fill(Color.blush.opacity(0.35))
        }
    }
}

/// Bouton galet de saisie rapide, qui note directement depuis le widget.
struct QuickButton: View {
    let habit: WidgetHabit
    var size: CGFloat = 54
    var fontSize: CGFloat = 15

    var body: some View {
        Button(intent: LogHabitIntent(habitID: habit.id, action: habit.quick.action)) {
            Text(verbatim: habit.quick.label)
                .font(.rituel(.bold, size: fontSize, relativeTo: .body))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .foregroundStyle(.ink)
                .padding(.horizontal, 4)
                .frame(width: size, height: size)
                .background { Pebble(shape: Circle(), base: .surface, tint: habit.spec.color.color, tintOpacity: 0.55) }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(verbatim: "Noter \(habit.spec.name), \(habit.quick.label)"))
    }
}

struct WidgetHabitName: View {
    let habit: WidgetHabit
    var font: Font = .rituel(.semibold, size: 14, relativeTo: .subheadline)

    var body: some View {
        HStack(spacing: 6) {
            Circle().fill(habit.spec.color.color).frame(width: 8, height: 8).widgetAccentable()
            Text(habit.spec.name)
                .font(font)
                .foregroundStyle(.ink)
                .lineLimit(1)
        }
    }
}

/// « 1,3L / 2L »
struct WidgetValue: View {
    let habit: WidgetHabit
    var size: CGFloat = 26

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 3) {
            Text(verbatim: habit.totalText)
                .font(.rituel(.displayText, size: size, relativeTo: .title))
                .foregroundStyle(.ink)
                .contentTransition(.numericText())
            Text(verbatim: "/ \(habit.targetText)")
                .font(.rituel(.regular, size: max(11, size * 0.45), relativeTo: .caption))
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
        case .ok, .done: (.ok, .okSoft)
        case .edge: (.edge, .edgeSoft)
        case .over: (.over, .overSoft)
        case .progress: (.ink2, .surface2)
        }
    }
}

struct WidgetChip: View {
    let status: HabitStatus

    var body: some View {
        Text(verbatim: status.label)
            .font(.rituel(.semibold, size: 11, relativeTo: .caption2))
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .foregroundStyle(status.tone.colors.fg)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background { Well(shape: Capsule(), color: status.tone.colors.bg) }
    }
}
