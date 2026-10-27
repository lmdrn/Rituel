import SwiftUI

/// Frise de la semaine : 7 jours, flèches pour changer de semaine, jours futurs grisés.
struct WeekStrip: View {
    @Binding var selected: Date
    let today: Date
    let log: EntryLog

    private let calendar = RituelCalendar.current

    var body: some View {
        let monday = calendar.monday(of: selected)
        let nextMonday = calendar.adding(days: 7, to: monday)

        VStack(spacing: 8) {
            HStack {
                ChevronButton(direction: -1, label: "Semaine précédente") { moveWeek(-7) }
                Spacer()
                Text(selected == today ? "Tu notes pour aujourd'hui" : "Tu notes pour \(calendar.longDate(selected))")
                    .font(.rituelCallout)
                    .foregroundStyle(.ink2)
                    .multilineTextAlignment(.center)
                Spacer()
                ChevronButton(direction: 1, label: "Semaine suivante") { moveWeek(7) }
                    .disabled(nextMonday > today)
            }

            HStack(spacing: 6) {
                ForEach(0..<7, id: \.self) { i in
                    let d = calendar.adding(days: i, to: monday)
                    DayButton(
                        letter: RituelCalendar.weekdayLetters[i],
                        number: calendar.dayOfMonth(d),
                        isSelected: d == selected,
                        isToday: d == today,
                        hasEntries: log.hasEntries(on: d),
                        accessibilityName: calendar.longDate(d)
                    ) {
                        selected = d
                    }
                    .disabled(d > today)
                }
            }
        }
        .sensoryFeedback(.selection, trigger: selected)
    }

    private func moveWeek(_ days: Int) {
        selected = min(calendar.adding(days: days, to: selected), today)
    }
}

private struct DayButton: View {
    let letter: String
    let number: Int
    let isSelected: Bool
    let isToday: Bool
    let hasEntries: Bool
    let accessibilityName: String
    let action: () -> Void

    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text(verbatim: letter)
                    .font(.rituel(isToday ? .bold : .regular, size: 11, relativeTo: .caption2))
                    .tracking(0.66)
                    .foregroundStyle(isSelected ? Color.accentInk : (isToday ? Color.accentText : Color.ink2))
                Text(verbatim: "\(number)")
                    .font(.rituel(.semibold, size: 16, relativeTo: .body))
                    .monospacedDigit()
                    .foregroundStyle(isSelected ? Color.accentInk : Color.ink)
                Circle()
                    .fill(hasEntries ? (isSelected ? Color.sun : Color.ink3) : .clear)
                    .frame(width: 5, height: 5)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 8)
            .padding(.bottom, 7)
            .background {
                if isSelected {
                    Pebble(shape: RoundedRectangle(cornerRadius: 14, style: .continuous), base: .accent, lifted: false)
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .opacity(isEnabled ? 1 : 0.35)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(verbatim: accessibilityName))
        .accessibilityValue(hasEntries ? Text("saisies notées") : Text(verbatim: ""))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

struct ChevronButton: View {
    let direction: Int
    let label: LocalizedStringKey
    let action: () -> Void

    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        Button(action: action) {
            Image(systemName: direction < 0 ? "chevron.left" : "chevron.right")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.ink2)
                .frame(width: 34, height: 34)
                .contentShape(Circle())
                .opacity(isEnabled ? 1 : 0.3)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}
