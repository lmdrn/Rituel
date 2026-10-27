import SwiftUI

/// Frise de la semaine : une mini-marguerite par jour, remplie selon les habitudes quotidiennes tenues.
struct WeekDaisyStrip: View {
    @Binding var selected: Date
    let today: Date
    let habits: [HabitSpec]
    let log: EntryLog

    @Namespace private var selection
    private let calendar = RituelCalendar.current
    private let weekdays = ["lundi", "mardi", "mercredi", "jeudi", "vendredi", "samedi", "dimanche"]

    var body: some View {
        let monday = calendar.monday(of: selected)
        let nextMonday = calendar.adding(days: 7, to: monday)

        VStack(spacing: 6) {
            HStack {
                Button { move(-7) } label: { Image(systemName: "chevron.left").frame(width: 44, height: 44) }
                    .accessibilityLabel("Semaine précédente")
                Spacer()
                Text(verbatim: selected == today ? "Tu notes pour aujourd'hui" : "Tu notes pour \(calendar.longDate(selected))")
                    .font(.rituel(.semibold, size: 14, relativeTo: .subheadline))
                    .foregroundStyle(.ink2)
                    .contentTransition(.opacity)
                Spacer()
                Button { move(7) } label: { Image(systemName: "chevron.right").frame(width: 44, height: 44) }
                    .disabled(nextMonday > today)
                    .accessibilityLabel("Semaine suivante")
            }
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(.accentText)

            HStack(spacing: 2) {
                ForEach(0..<7, id: \.self) { i in
                    let d = calendar.adding(days: i, to: monday)
                    let fill = SummaryEngine.dayFill(habits, log: log, day: d, today: today)
                    let isSelected = d == selected
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { selected = d }
                    } label: {
                        VStack(spacing: 4) {
                            Text(verbatim: RituelCalendar.weekdayLetters[i])
                                .font(.rituel(.bold, size: 12, relativeTo: .caption))
                                .foregroundStyle(isSelected ? Color.accentText : Color.ink2)
                            Daisy(filled: fill.petals, tint: .accent, heartLit: fill.heartLit, delay: Double(i) * 0.04)
                                .frame(width: 30, height: 30)
                            Text(verbatim: "\(calendar.dayOfMonth(d))")
                                .font(.rituel(.bold, size: 13, relativeTo: .caption))
                                .monospacedDigit()
                                .foregroundStyle(isSelected ? Color.accentText : Color.ink)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 7)
                        .background {
                            if isSelected {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(.accentSoft)
                                    .matchedGeometryEffect(id: "day", in: selection)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .disabled(d > today)
                    .opacity(d > today ? 0.45 : 1)
                    .accessibilityLabel(Text(verbatim: "\(weekdays[i]) \(calendar.dayOfMonth(d))"))
                    .accessibilityValue(Text(verbatim: d > today ? "à venir" : "\(fill.petals) pétales sur 7"))
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
        }
        .sensoryFeedback(.selection, trigger: selected)
    }

    private func move(_ days: Int) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            selected = min(calendar.adding(days: days, to: selected), today)
        }
    }
}
