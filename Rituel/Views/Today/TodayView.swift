import Combine
import SwiftData
import SwiftUI

/// Onglet « Aujourd'hui » : salutation, frise de la semaine, résumé, cartes groupées par période.
struct TodayView: View {
    var onCreateHabit: () -> Void = {}

    @Environment(\.scenePhase) private var scenePhase
    @State private var today = RituelCalendar.current.day(.now)
    @State private var selected = RituelCalendar.current.day(.now)

    var body: some View {
        NavigationStack {
            TodayContent(selected: $selected, today: today, onCreateHabit: onCreateHabit)
                .navigationTitle("Aujourd'hui")
                .background(.canvas)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { refreshDay() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged).receive(on: RunLoop.main)) { _ in
            refreshDay()
        }
    }

    /// Passe au jour suivant si l'app reste ouverte après minuit.
    private func refreshDay() {
        let now = RituelCalendar.current.day(.now)
        guard now != today else { return }
        if selected == today { selected = now }
        today = now
    }
}

private struct TodayContent: View {
    @Binding var selected: Date
    let today: Date
    let onCreateHabit: () -> Void

    @Environment(\.modelContext) private var context
    @AppStorage(SharedDefaults.firstNameKey, store: SharedDefaults.store) private var firstName = ""
    @Query(sort: \Habit.sortIndex) private var habits: [Habit]
    @Query private var entries: [Entry]

    private let calendar = RituelCalendar.current

    init(selected: Binding<Date>, today: Date, onCreateHabit: @escaping () -> Void) {
        _selected = selected
        self.today = today
        self.onCreateHabit = onCreateHabit
        // La semaine et le mois du jour choisi, plus 30 jours pour la valeur habituelle des choix rapides.
        let cal = RituelCalendar.current
        let week = cal.range(.week, containing: selected.wrappedValue)
        let month = cal.range(.month, containing: selected.wrappedValue)
        let start = min(week.first, month.first, cal.adding(days: -WidgetData.recentDays, to: selected.wrappedValue))
        let end = cal.adding(days: 1, to: max(week.last, month.last))
        _entries = Query(filter: #Predicate<Entry> { $0.day >= start && $0.day < end })
    }

    var body: some View {
        let specs = habits.map(\.spec)
        let log = EntryLog(entries, calendar: calendar)
        let over = HabitEngine.overLimitCount(specs, log: log, day: selected)

        ScrollView {
            VStack(alignment: .leading, spacing: Metrics.sectionSpacing) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(verbatim: calendar.longDate(today))
                        .font(.rituel(.bold, size: 13, relativeTo: .footnote))
                        .textCase(.uppercase)
                        .foregroundStyle(.ink2)
                    Text(verbatim: "\(HabitEngine.greeting(name: firstName, hour: calendar.hour(.now))). \(HabitEngine.lede(overLimits: over, habitCount: specs.count))")
                        .font(.rituelBody)
                        .foregroundStyle(.ink2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                WeekDaisyStrip(selected: $selected, today: today, habits: specs, log: log)

                if specs.isEmpty {
                    emptyState
                } else {
                    SummaryCard(habits: specs, log: log, selected: selected, today: today)
                    ForEach(HabitPeriod.allCases, id: \.self) { period in
                        let group = specs.filter { $0.period == period }
                        if !group.isEmpty {
                            PeriodSection(period: period, habits: group, log: log, selected: selected, today: today, onAction: write)
                        }
                    }
                }
            }
            .padding(.horizontal, Metrics.gutter)
            .padding(.bottom, 24)
            .frame(maxWidth: 600)
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Aucune habitude pour l'instant.")
                .font(.rituelBody)
                .foregroundStyle(.ink)
            Button("Créer une habitude", action: onCreateHabit)
                .buttonStyle(CapsuleButtonStyle())
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private func write(_ action: EntryAction, _ habit: HabitSpec) {
        EntryWriter(context: context, calendar: calendar).apply(action, habitID: habit.id, day: selected)
    }
}

private struct PeriodSection: View {
    let period: HabitPeriod
    let habits: [HabitSpec]
    let log: EntryLog
    let selected: Date
    let today: Date
    let onAction: (EntryAction, HabitSpec) -> Void

    private var title: LocalizedStringKey {
        switch period {
        case .day: "Par jour"
        case .week: "Par semaine"
        case .month: "Par mois"
        }
    }

    private var subtitle: String {
        let cal = RituelCalendar.current
        switch period {
        case .day: return selected == today ? "aujourd'hui" : cal.longDate(selected)
        case .week: return "semaine du \(cal.shortDate(cal.monday(of: selected)))"
        case .month: return cal.monthName(selected)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(.rituelTitle)
                    .foregroundStyle(.ink)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                Text(verbatim: subtitle)
                    .font(.rituelCallout)
                    .foregroundStyle(.ink2)
            }
            ForEach(habits) { habit in
                HabitTile(habit: habit, log: log, selected: selected, today: today) { onAction($0, habit) }
            }
        }
    }
}

#Preview("Aujourd'hui") {
    TodayView()
        .modelContainer(PreviewData.container)
}

#Preview("Sombre, grand texte") {
    TodayView()
        .modelContainer(PreviewData.container)
        .preferredColorScheme(.dark)
        .dynamicTypeSize(.xxLarge)
}
