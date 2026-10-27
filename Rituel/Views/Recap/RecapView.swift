import SwiftData
import SwiftUI

/// Onglet « Récap » : score d'équilibre, ce qui est tenu, en cours, à travailler, grille jour par jour.
struct RecapView: View {
    @State private var weekStart = RituelCalendar.current.monday(of: .now)

    var body: some View {
        RecapContent(weekStart: $weekStart, today: RituelCalendar.current.day(.now))
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
                HeroCard(eyebrow: "Récap de la semaine", title: recap.title)

                HStack {
                    ChevronButton(direction: -1, label: "Semaine précédente") { moveWeek(-7) }
                    Spacer()
                    Text(verbatim: "Du \(calendar.shortDate(weekStart)) au \(calendar.shortDate(end))" + (end >= today ? " · en cours" : ""))
                        .font(.rituelCallout)
                        .monospacedDigit()
                        .foregroundStyle(.ink2)
                    Spacer()
                    ChevronButton(direction: 1, label: "Semaine suivante") { moveWeek(7) }
                        .disabled(calendar.adding(days: 7, to: weekStart) > today)
                }

                ScoreCard(recap: recap)

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
            .padding(.top, 16)
            .padding(.bottom, 120)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
        .sensoryFeedback(.selection, trigger: weekStart)
    }

    private func moveWeek(_ days: Int) {
        let next = calendar.adding(days: days, to: weekStart)
        if next <= today { weekStart = next }
    }
}

// MARK: Score

private struct ScoreCard: View {
    let recap: WeekRecap

    var body: some View {
        let total = recap.rows.count, kept = recap.kept.count
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 18) {
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(verbatim: "\(recap.score)")
                        .font(.rituelScore)
                    Text(verbatim: "%")
                        .font(.rituel(.title, size: 26, relativeTo: .title))
                }
                .monospacedDigit()
                .foregroundStyle(.accentText)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Équilibre").eyebrow()
                    Text(verbatim: "\(kept) sur \(total) \(HabitEngine.plural(Double(total), "habitude")) \(HabitEngine.plural(Double(kept), "tenue"))")
                        .font(.rituelBodyStrong)
                        .foregroundStyle(.ink)
                    FlowLayout(spacing: 6) {
                        if kept > 0 {
                            StatusChip(status: HabitStatus(tone: .ok, label: "\(kept) \(HabitEngine.plural(Double(kept), "tenue"))"))
                        }
                        if !recap.inProgress.isEmpty {
                            StatusChip(status: HabitStatus(tone: .progress, label: "\(recap.inProgress.count) en cours"))
                        }
                        if !recap.toWork.isEmpty {
                            StatusChip(status: HabitStatus(tone: .over, label: "\(recap.toWork.count) à travailler"))
                        }
                    }
                    .padding(.top, 4)
                }
            }

            ScoreDots(score: recap.score)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
        .accessibilityElement(children: .combine)
    }
}

/// 20 petits points : remplis selon le score, les derniers en jaune soleil.
private struct ScoreDots: View {
    let score: Int

    var body: some View {
        let on = Int((Double(score) / 5).rounded())
        HStack(spacing: 3) {
            ForEach(0..<20, id: \.self) { i in
                Group {
                    if i < on {
                        Pebble(shape: Capsule(), base: i >= 14 ? .sun : .accent, lifted: false, glows: true)
                    } else {
                        Well(shape: Capsule())
                    }
                }
                .frame(height: 10)
            }
        }
        .accessibilityHidden(true)
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
                        .font(.rituel(.regular, size: 14, relativeTo: .subheadline))
                        .foregroundStyle(.ink3)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 14)
                        .padding(.horizontal, 16)
                }
                ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                    if index > 0 { Rectangle().fill(Color.line).frame(height: 1) }
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
            Daisy(filled: 7, tint: row.habit.color.color, heartLit: row.state == .kept)
                .frame(width: 20, height: 20)
                .padding(.top, 1)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(row.habit.name)
                    .font(.rituelBodyStrong)
                    .foregroundStyle(.ink)
                Text(verbatim: row.detail)
                    .font(.rituelCallout)
                    .foregroundStyle(.ink2)
                    .fixedSize(horizontal: false, vertical: true)
                if showTip, let tip = row.tip {
                    Text(verbatim: tip)
                        .font(.rituelCallout)
                        .foregroundStyle(.ink)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 10)
                        .background(.surface2, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .padding(.top, 6)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Text(verbatim: row.value)
                .font(.rituelCallout)
                .monospacedDigit()
                .foregroundStyle(.ink2)
                .fixedSize()
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
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
        Grid(horizontalSpacing: 4, verticalSpacing: 4) {
            GridRow {
                Color.clear.gridCellUnsizedAxes([.horizontal, .vertical])
                ForEach(0..<7, id: \.self) { i in
                    Text(verbatim: RituelCalendar.weekdayLetters[i])
                        .font(.rituel(.semibold, size: 11, relativeTo: .caption2))
                        .foregroundStyle(.ink3)
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
                        .truncationMode(.tail)
                        .frame(maxWidth: 110, alignment: .leading)
                        .gridColumnAlignment(.leading)
                    ForEach(days, id: \.self) { d in
                        let v = log.value(habit.id, on: d)
                        cell(RecapEngine.heatCell(habit, value: v, day: d, today: today),
                             text: d > today || v == 0 ? "" : QuantityFormat.value(v, for: habit, short: true),
                             tint: habit.color.color)
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(verbatim: summary(habit, days: days)))
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .cardStyle()
    }

    private func cell(_ state: HeatCellState, text: String, tint: Color) -> some View {
        let shape = RoundedRectangle(cornerRadius: 7, style: .continuous)
        let (fg, bg): (Color, Color) = switch state {
        case .ok: (.ok, .okSoft)
        case .over: (.over, .overSoft)
        case .hit: (.ink, tint.opacity(0.45))
        case .empty: (.ink2, .surface2)
        case .future: (.ink3, .clear)
        }
        return Text(verbatim: text)
            .font(.rituel(.semibold, size: 10, relativeTo: .caption2))
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .foregroundStyle(fg)
            .frame(maxWidth: .infinity, minHeight: 26)
            .background { if state != .future { Well(shape: shape, color: bg) } }
            .overlay {
                if state == .future {
                    shape.strokeBorder(Color.line, style: StrokeStyle(lineWidth: 1, dash: [3, 2]))
                }
            }
    }

    private func summary(_ habit: HabitSpec, days: [Date]) -> String {
        let cal = log.calendar
        let parts = days.filter { $0 <= today }.compactMap { d -> String? in
            let v = log.value(habit.id, on: d)
            guard v > 0 else { return nil }
            let weekday = cal.longDate(d).components(separatedBy: " ").first ?? ""
            return "\(weekday) \(QuantityFormat.value(v, for: habit))"
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
            Text("Un mot pour ta semaine").eyebrow()
            if let note {
                Text(verbatim: note)
                    .font(.rituelNote)
                    .lineSpacing(5)
                    .foregroundStyle(.ink)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text(failed ? "Le mot n'a pas pu s'écrire cette fois. Tu peux réessayer." : "Quelques lignes bienveillantes écrites à partir de ton récap, directement sur ton iPhone.")
                    .font(.rituel(.regular, size: 14, relativeTo: .subheadline))
                    .foregroundStyle(.ink2)
            }
            Button(writing ? "Écriture…" : (note == nil ? "Écrire mon mot" : "Un autre mot")) {
                Task { await write() }
            }
            .buttonStyle(PillButtonStyle(kind: .soft))
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
            note = try await WeeklyNoteWriter.write(prompt: prompt)
            failed = false
        } catch {
            failed = true
        }
    }
}

#Preview("Récap") {
    RecapView()
        .background(.canvas)
        .modelContainer(PreviewData.container)
}

#Preview("Sombre") {
    RecapView()
        .background(.canvas)
        .modelContainer(PreviewData.container)
        .preferredColorScheme(.dark)
}
