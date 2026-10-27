import Combine
import SwiftData
import SwiftUI

/// Onglet « Aujourd'hui » : salutation, frise de la semaine, cartes groupées par période.
struct TodayView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var today = RituelCalendar.current.day(.now)
    @State private var selected = RituelCalendar.current.day(.now)

    var body: some View {
        TodayContent(selected: $selected, today: today)
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

    @Environment(\.modelContext) private var context
    @AppStorage(SharedDefaults.firstNameKey, store: SharedDefaults.store) private var firstName = ""
    @Query(sort: \Habit.sortIndex) private var habits: [Habit]
    @Query private var entries: [Entry]

    private let calendar = RituelCalendar.current

    init(selected: Binding<Date>, today: Date) {
        _selected = selected
        self.today = today
        // Seules les entrées utiles à l'écran : la semaine et le mois du jour sélectionné.
        let cal = RituelCalendar.current
        let week = cal.range(.week, containing: selected.wrappedValue)
        let month = cal.range(.month, containing: selected.wrappedValue)
        let start = min(week.first, month.first)
        let end = cal.adding(days: 1, to: max(week.last, month.last))
        _entries = Query(filter: #Predicate<Entry> { $0.day >= start && $0.day < end })
    }

    var body: some View {
        let specs = habits.map(\.spec)
        let log = EntryLog(entries, calendar: calendar)
        let over = HabitEngine.overLimitCount(specs, log: log, day: selected)

        ScrollView {
            LazyVStack(alignment: .leading, spacing: Metrics.sectionSpacing, pinnedViews: [.sectionHeaders]) {
                TodayHero(
                    date: today,
                    greeting: HabitEngine.greeting(name: firstName, hour: calendar.hour(.now)),
                    lede: HabitEngine.lede(overLimits: over, habitCount: specs.count)
                )
                .padding(.horizontal, Metrics.gutter)

                Section {
                    ForEach(HabitPeriod.allCases, id: \.self) { period in
                        let group = specs.filter { $0.period == period }
                        if !group.isEmpty {
                            PeriodGroup(period: period, habits: group, log: log, selected: selected, today: today, onAction: write)
                                .padding(.horizontal, Metrics.gutter)
                        }
                    }
                    if specs.isEmpty {
                        Text("Aucune habitude pour l'instant.")
                            .font(.rituelBody)
                            .foregroundStyle(.ink)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 14)
                            .padding(.horizontal, 16)
                            .background(.accentSoft, in: RoundedRectangle(cornerRadius: Metrics.cardRadius, style: .continuous))
                            .padding(.horizontal, Metrics.gutter)
                    }
                } header: {
                    WeekStrip(selected: $selected, today: today, log: log)
                        .padding(.horizontal, Metrics.gutter)
                        .padding(.vertical, 8)
                        .background { PinnedBackground() }
                }
            }
            .padding(.top, 16)
            .padding(.bottom, 120)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
    }

    private func write(_ action: EntryAction, _ habit: HabitSpec) {
        EntryWriter(context: context, calendar: calendar).apply(action, habitID: habit.id, day: selected)
    }
}

/// Fond de la frise : transparent au repos pour laisser voir les vagues, opaque une fois collée en haut
/// (il remonte alors sous la barre d'état pour que les cartes n'y passent pas).
private struct PinnedBackground: View {
    var body: some View {
        GeometryReader { geo in
            let top = geo.frame(in: .scrollView).minY
            Color.canvas
                .padding(.top, -120)
                .opacity(min(1, max(0, 1 - top / 40)))
        }
    }
}

private struct TodayHero: View {
    let date: Date
    let greeting: String
    let lede: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            BrandHeader(date: date)
                .padding(.bottom, 14)
            Text(RituelCalendar.current.longDate(date))
                .eyebrow()
            Text(greeting)
                .font(.rituelLargeTitle)
                .foregroundStyle(.ink)
                .accessibilityAddTraits(.isHeader)
            Text(lede)
                .font(.rituelBody)
                .foregroundStyle(.ink2)
                .frame(maxWidth: 340, alignment: .leading)
                .padding(.top, 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(alignment: .topTrailing) {
            BreathingBlob()
                .offset(x: 6, y: 30)
        }
    }
}

private struct PeriodGroup: View {
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
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(title)
                    .font(.rituelTitle)
                    .foregroundStyle(.ink)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                Text(subtitle)
                    .font(.rituelCallout)
                    .foregroundStyle(.ink3)
            }
            ForEach(habits) { habit in
                HabitCard(habit: habit, log: log, selected: selected, today: today) { onAction($0, habit) }
            }
        }
    }
}

#Preview("Aujourd'hui") {
    TodayView()
        .background(.canvas)
        .modelContainer(PreviewData.container)
}

#Preview("Sombre, grand texte") {
    TodayView()
        .background(.canvas)
        .modelContainer(PreviewData.container)
        .preferredColorScheme(.dark)
        .dynamicTypeSize(.xxLarge)
}
