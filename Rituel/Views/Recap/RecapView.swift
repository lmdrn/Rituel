import SwiftData
import SwiftUI

/// Onglet « Récap » : grande marguerite du score d'équilibre, ce qui est tenu, en cours, à travailler.
struct RecapView: View {
    @State private var weekStart = RituelCalendar.current.monday(of: .now)

    var body: some View {
        NavigationStack {
            RecapContent(weekStart: $weekStart, today: RituelCalendar.current.day(.now))
                .navigationTitle("Récap")
                .background(.canvas)
        }
    }
}

private struct RecapContent: View {
    @Binding var weekStart: Date
    let today: Date

    @AppStorage(SharedDefaults.firstNameKey, store: SharedDefaults.store) private var firstName = ""
    @Query(sort: \Habit.sortIndex) private var habits: [Habit]
    @Query private var entries: [Entry]

    private let calendar = RituelCalendar.current

    init(weekStart: Binding<Date>, today: Date) {
        _weekStart = weekStart
        self.today = today
        // Le mois évalué est celui du dernier jour de la semaine : on charge depuis le début du mois du lundi.
        let cal = RituelCalendar.current
        let start = cal.range(.month, containing: weekStart.wrappedValue).first
        let end = cal.adding(days: 7, to: weekStart.wrappedValue)
        _entries = Query(filter: #Predicate<Entry> { $0.day >= start && $0.day < end })
    }

    var body: some View {
        let specs = habits.map(\.spec)
        let log = EntryLog(entries, calendar: calendar)
        let recap = RecapEngine.recap(specs, weekStart: weekStart, log: log, today: today)
        let end = calendar.adding(days: 6, to: weekStart)

        ScrollView {
            VStack(alignment: .leading, spacing: Metrics.sectionSpacing) {
                HStack {
                    Button { moveWeek(-7) } label: { Image(systemName: "chevron.left").frame(width: 44, height: 44) }
                        .accessibilityLabel("Semaine précédente")
                    Spacer()
                    Text(verbatim: "Du \(calendar.shortDate(weekStart)) au \(calendar.shortDate(end))" + (end >= today ? " · en cours" : ""))
                        .font(.rituel(.semibold, size: 15, relativeTo: .subheadline))
                        .monospacedDigit()
                        .foregroundStyle(.ink2)
                        .contentTransition(.numericText())
                    Spacer()
                    Button { moveWeek(7) } label: { Image(systemName: "chevron.right").frame(width: 44, height: 44) }
                        .disabled(calendar.adding(days: 7, to: weekStart) > today)
                        .accessibilityLabel("Semaine suivante")
                }
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.accentText)

                ScoreCard(recap: recap)
                    .id(weekStart)

                RecapSection(title: "Ce que tu as tenu", rows: recap.kept, empty: "Rien de tenu pour l'instant, et c'est ok.")
                if !recap.inProgress.isEmpty {
                    RecapSection(title: "En cours", rows: recap.inProgress, empty: nil)
                }
                RecapSection(title: "Où progresser", rows: recap.toWork, empty: "Rien à rattraper cette semaine.", showTips: true)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Jour par jour")
                        .font(.rituelTitle)
                        .foregroundStyle(.ink)
                        .accessibilityAddTraits(.isHeader)
                    HeatGrid(habits: specs, log: log, weekStart: weekStart, today: today)
                }

                if WeeklyNoteWriter.isAvailable, !recap.rows.isEmpty {
                    WeeklyNoteCard(prompt: RecapEngine.notePrompt(recap, name: firstName, calendar: calendar))
                        .id(weekStart)
                }
            }
            .padding(.horizontal, Metrics.gutter)
            .padding(.bottom, 24)
            .frame(maxWidth: 600)
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
        .sensoryFeedback(.selection, trigger: weekStart)
    }

    private func moveWeek(_ days: Int) {
        let next = calendar.adding(days: days, to: weekStart)
        guard next <= today else { return }
        withAnimation(.snappy) { weekStart = next }
    }
}

// MARK: Score

private struct ScoreCard: View {
    let recap: WeekRecap

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown = 0.0

    var body: some View {
        let score = recap.score
        VStack(spacing: 16) {
            Daisy(filled: Int((Double(score) / 100 * 7).rounded()), tint: .accent, heartLit: score >= 85, delay: 0.1)
                .frame(width: 180, height: 180)
                .padding(.top, 6)
            VStack(spacing: 4) {
                CountingPercent(value: shown)
                    .font(.rituel(.title, size: 56, relativeTo: .largeTitle))
                    .foregroundStyle(.accentText)
                Text(verbatim: recap.title)
                    .font(.rituel(.title, size: 20, relativeTo: .title3))
                    .foregroundStyle(.ink)
                    .multilineTextAlignment(.center)
            }
            Divider()
            HStack(spacing: 0) {
                stat(recap.kept.count, HabitEngine.plural(Double(recap.kept.count), "tenue"), .ok)
                Divider().frame(height: 40)
                stat(recap.inProgress.count, "en cours", .accentText)
                Divider().frame(height: 40)
                stat(recap.toWork.count, "à travailler", .over)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .cardStyle()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: "Équilibre \(score) %. \(recap.title). \(recap.kept.count) tenues, \(recap.inProgress.count) en cours, \(recap.toWork.count) à travailler."))
        .onAppear {
            if reduceMotion { shown = Double(score); return }
            withAnimation(.easeOut(duration: 1.1).delay(0.2)) { shown = Double(score) }
        }
    }

    private func stat(_ n: Int, _ label: String, _ color: Color) -> some View {
        VStack(spacing: 2) {
            Text(verbatim: "\(n)")
                .font(.rituel(.title, size: 28, relativeTo: .title))
                .foregroundStyle(color)
            Text(verbatim: label)
                .font(.rituelCallout)
                .foregroundStyle(.ink2)
        }
        .frame(maxWidth: .infinity)
    }
}

/// Pourcentage dont les chiffres défilent de 0 au score.
private struct CountingPercent: View {
    var value: Double

    var body: some View {
        (Text(verbatim: "\(Int(value.rounded()))") + Text(verbatim: " %").font(.rituel(.title, size: 26, relativeTo: .title)))
            .monospacedDigit()
            .contentTransition(.numericText(value: value))
    }
}

// MARK: Listes

private struct RecapSection: View {
    let title: LocalizedStringKey
    let rows: [RecapRow]
    let empty: LocalizedStringKey?
    var showTips = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.rituelTitle)
                .foregroundStyle(.ink)
                .accessibilityAddTraits(.isHeader)
            VStack(spacing: 0) {
                if rows.isEmpty, let empty {
                    Text(empty)
                        .font(.rituelBody)
                        .foregroundStyle(.ink2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                }
                ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                    if index > 0 { Divider().padding(.leading, 58) }
                    RecapRowView(row: row, showTip: showTips)
                }
            }
            .cardStyle()
        }
    }
}

private struct RecapRowView: View {
    let row: RecapRow
    let showTip: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            HabitIcon(color: row.habit.color.color)
            VStack(alignment: .leading, spacing: 3) {
                HStack(alignment: .firstTextBaseline) {
                    Text(row.habit.name)
                        .font(.rituel(.semibold, size: 17, relativeTo: .body))
                        .foregroundStyle(.ink)
                    Spacer()
                    Text(verbatim: row.value)
                        .font(.rituel(.regular, size: 15, relativeTo: .subheadline))
                        .monospacedDigit()
                        .foregroundStyle(.ink2)
                }
                Text(verbatim: row.detail)
                    .font(.rituel(.regular, size: 14, relativeTo: .subheadline))
                    .foregroundStyle(.ink2)
                    .fixedSize(horizontal: false, vertical: true)
                if showTip, let tip = row.tip {
                    (Text("Conseil · ").fontWeight(.bold).foregroundStyle(.sunText) + Text(verbatim: tip).foregroundStyle(.ink))
                        .font(.rituel(.regular, size: 14, relativeTo: .subheadline))
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 4)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .accessibilityElement(children: .combine)
    }
}

// MARK: Grille

private struct HeatGrid: View {
    let habits: [HabitSpec]
    let log: EntryLog
    let weekStart: Date
    let today: Date

    var body: some View {
        let cal = log.calendar
        let days = (0..<7).map { cal.adding(days: $0, to: weekStart) }
        Grid(horizontalSpacing: 5, verticalSpacing: 6) {
            GridRow {
                Color.clear.gridCellUnsizedAxes([.horizontal, .vertical])
                ForEach(0..<7, id: \.self) { i in
                    Text(verbatim: RituelCalendar.weekdayLetters[i])
                        .font(.rituel(.bold, size: 11, relativeTo: .caption2))
                        .foregroundStyle(.ink2)
                        .frame(maxWidth: .infinity)
                }
            }
            .accessibilityHidden(true)

            ForEach(habits) { habit in
                GridRow {
                    Text(habit.name)
                        .font(.rituelCallout)
                        .foregroundStyle(.ink)
                        .lineLimit(1)
                        .frame(maxWidth: 96, alignment: .leading)
                        .gridColumnAlignment(.leading)
                    ForEach(days, id: \.self) { d in
                        let v = log.value(habit.id, on: d)
                        cell(RecapEngine.heatCell(habit, value: v, day: d, today: today),
                             text: d > today || v == 0 ? "" : QuantityFormat.value(v, for: habit, short: true))
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(verbatim: summary(habit, days: days)))
            }
        }
        .padding(16)
        .cardStyle()
    }

    private func cell(_ state: HeatCellState, text: String) -> some View {
        let shape = RoundedRectangle(cornerRadius: 7, style: .continuous)
        let (fg, bg): (Color, Color) = switch state {
        case .ok: (.ok, .okSoft)
        case .over: (.over, .overSoft)
        case .hit: (.ink, .accentSoft)
        case .empty: (.ink2, .canvas)
        case .future: (.ink3, .clear)
        }
        return Text(verbatim: text)
            .font(.rituel(.bold, size: 10, relativeTo: .caption2))
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .foregroundStyle(fg)
            .frame(maxWidth: .infinity, minHeight: 26)
            .background(bg, in: shape)
            .overlay {
                if state == .future { shape.strokeBorder(Color.line, style: StrokeStyle(lineWidth: 1, dash: [3, 2])) }
            }
    }

    private func summary(_ habit: HabitSpec, days: [Date]) -> String {
        let cal = log.calendar
        let parts = days.filter { $0 <= today }.compactMap { d -> String? in
            let v = log.value(habit.id, on: d)
            guard v > 0 else { return nil }
            return "\(cal.longDate(d).components(separatedBy: " ").first ?? "") \(QuantityFormat.value(v, for: habit))"
        }
        return "\(habit.name) : " + (parts.isEmpty ? "rien de noté" : parts.joined(separator: ", "))
    }
}

// MARK: Un mot pour ta semaine

private struct WeeklyNoteCard: View {
    let prompt: String

    @State private var note: String?
    @State private var writing = false
    @State private var failed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Un mot pour ta semaine")
                .font(.rituelCardTitle)
                .foregroundStyle(.ink)
            if let note {
                Text(verbatim: note)
                    .font(.rituelNote)
                    .lineSpacing(5)
                    .foregroundStyle(.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            } else {
                Text(failed ? "Le mot n'a pas pu s'écrire cette fois. Tu peux réessayer." : "Quelques lignes bienveillantes écrites à partir de ton récap, directement sur ton iPhone.")
                    .font(.rituelBody)
                    .foregroundStyle(.ink2)
            }
            Button {
                Task { await write() }
            } label: {
                if writing {
                    ProgressView().frame(maxWidth: .infinity)
                } else {
                    Text(note == nil ? "Écrire mon mot" : "Un autre mot").frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(CapsuleButtonStyle(prominent: false))
            .disabled(writing)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private func write() async {
        writing = true
        defer { writing = false }
        do {
            let text = try await WeeklyNoteWriter.write(prompt: prompt)
            withAnimation(.easeOut(duration: 0.4)) { note = text }
            failed = false
        } catch {
            failed = true
        }
    }
}

#Preview("Récap") {
    RecapView()
        .modelContainer(PreviewData.container)
}
