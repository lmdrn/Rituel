import Charts
import SwiftUI

/// Carte d'une habitude, inspirée de Forme : nom, grand chiffre, statut, graphique de la semaine,
/// un bouton principal et un menu pour le reste.
struct HabitTile: View {
    let habit: HabitSpec
    let log: EntryLog
    let selected: Date
    let today: Date
    let onAction: (EntryAction) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var logged = 0
    @State private var bloomed = 0
    @State private var askingValue = false
    @State private var valueText = ""

    private var total: Double { log.total(habit, periodContaining: selected) }
    private var dayValue: Double { log.value(habit.id, on: selected) }
    private var tint: Color { habit.color.color }
    private var dayWord: String { selected == today ? "aujourd'hui" : "ce jour" }

    var body: some View {
        let status = HabitEngine.status(habit, total: total)
        VStack(alignment: .leading, spacing: 14) {
            header
            HStack(alignment: .bottom, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    (Text(verbatim: QuantityFormat.value(total, for: habit, short: true))
                        + Text(verbatim: " / \(QuantityFormat.value(habit.target, for: habit, short: true))")
                            .font(.rituel(.title, size: 18, relativeTo: .title3))
                            .foregroundStyle(.ink2))
                        .font(.rituel(.title, size: 36, relativeTo: .largeTitle))
                        .monospacedDigit()
                        .foregroundStyle(.ink)
                        .contentTransition(.numericText(value: total))
                        .animation(.snappy, value: total)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    StatusLine(status: status)
                }
                .accessibilityElement(children: .combine)
                Spacer(minLength: 0)
                WeekBars(habit: habit, log: log, selected: selected, today: today)
                    .frame(width: 150, height: 76)
            }
            actions
        }
        .padding(16)
        .cardStyle()
        .overlay { GoldenGlint(trigger: bloomed) }
        .sensoryFeedback(.impact(weight: .light, intensity: 0.6), trigger: logged)
        .sensoryFeedback(.success, trigger: bloomed)
        .alert(habit.entryMode == .add ? "Ajouter une quantité" : "Valeur du jour", isPresented: $askingValue) {
            TextField(habit.trimmedUnit.isEmpty ? "Valeur" : habit.trimmedUnit, text: $valueText)
                .keyboardType(.decimalPad)
            Button("Annuler", role: .cancel) {}
            Button("Noter") {
                guard let v = Double(valueText.replacingOccurrences(of: ",", with: ".")), v > 0 else { return }
                perform(habit.entryMode == .add ? .add(v) : .replace(v))
            }
        }
    }

    // MARK: En-tête

    private var header: some View {
        HStack(spacing: 8) {
            Daisy(habit: habit, total: total)
                .frame(width: 22, height: 22)
                .accessibilityHidden(true)
            Text(habit.name)
                .font(.rituel(.title, size: 17, relativeTo: .headline))
                .foregroundStyle(.ink)
                .accessibilityAddTraits(.isHeader)
            if habit.healthSource != nil {
                Image(systemName: "heart.fill")
                    .font(.caption)
                    .foregroundStyle(.over)
                    .accessibilityLabel("Rempli depuis Santé")
            }
            Spacer(minLength: 8)
            Text(verbatim: HabitEngine.ruleText(habit))
                .font(.rituelCallout)
                .foregroundStyle(.ink2)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
    }

    // MARK: Actions

    @ViewBuilder
    private var actions: some View {
        HStack(spacing: 8) {
            primaryAction
                .overlay { PetalBurst(trigger: logged, tint: tint) }
            secondaryAction
        }
    }

    @ViewBuilder
    private var primaryAction: some View {
        switch (habit.measure, habit.entryMode) {
        case (.count, _):
            Button { perform(.increment) } label: { Label("+1", systemImage: "plus").labelStyle(.titleOnly).frame(maxWidth: .infinity) }
                .buttonStyle(CapsuleButtonStyle())
                .accessibilityLabel(Text("Noter \(habit.name) \(dayWord)"))
        case (.amount, .add):
            let v = habit.effectivePresets.first ?? 1
            Button { perform(.add(v)) } label: {
                Text(verbatim: "+ " + QuantityFormat.value(v, for: habit)).frame(maxWidth: .infinity)
            }
            .buttonStyle(CapsuleButtonStyle())
        case (.amount, .set):
            if dayValue > 0 {
                Menu { presetItems } label: {
                    Label { Text(verbatim: "Noté : " + QuantityFormat.value(dayValue, for: habit, short: true)) } icon: {
                        Image(systemName: "checkmark").symbolEffect(.bounce, value: dayValue)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(CapsuleButtonStyle(prominent: false))
            } else {
                let v = quickValue
                Button { perform(.set(v)) } label: {
                    Text(verbatim: "Noter " + QuantityFormat.value(v, for: habit, short: true)).frame(maxWidth: .infinity)
                }
                .buttonStyle(CapsuleButtonStyle())
            }
        }
    }

    @ViewBuilder
    private var secondaryAction: some View {
        if habit.isAmount {
            Menu {
                presetItems
                Button("Autre valeur…", systemImage: "number") {
                    valueText = ""
                    askingValue = true
                }
                if dayValue > 0 {
                    Divider()
                    Button(habit.entryMode == .add ? "Remettre la journée à zéro" : "Effacer la valeur", systemImage: "arrow.uturn.backward",
                           role: .destructive) { perform(.clear) }
                }
            } label: {
                Image(systemName: "ellipsis").frame(width: 20)
            }
            .buttonStyle(CapsuleButtonStyle(prominent: false))
            .accessibilityLabel(Text("Autres valeurs pour \(habit.name)"))
        } else {
            Button { perform(.decrement) } label: { Image(systemName: "minus").frame(width: 20) }
                .buttonStyle(CapsuleButtonStyle(prominent: false))
                .disabled(dayValue == 0)
                .accessibilityLabel("Retirer une fois")
        }
    }

    @ViewBuilder
    private var presetItems: some View {
        ForEach(habit.effectivePresets, id: \.self) { v in
            if habit.entryMode == .add {
                Button("+ " + QuantityFormat.value(v, for: habit)) { perform(.add(v)) }
            } else {
                Button {
                    perform(.replace(v))
                } label: {
                    if QuantityFormat.r2(dayValue) == QuantityFormat.r2(v) {
                        Label(QuantityFormat.value(v, for: habit), systemImage: "checkmark")
                    } else {
                        Text(verbatim: QuantityFormat.value(v, for: habit))
                    }
                }
            }
        }
    }

    /// Valeur du jour la plus souvent notée (sommeil), sinon celle qui est proche de la cible.
    private var quickValue: Double {
        let cal = log.calendar
        let recent = (1...WidgetData.recentDays).map { log.value(habit.id, on: cal.adding(days: -$0, to: selected)) }.filter { $0 > 0 }
        return HabitEngine.quickAction(habit, recentDayValues: recent).action.amount ?? habit.target
    }

    private func perform(_ action: EntryAction) {
        let wasDone = HabitEngine.status(habit, total: total).tone == .done
        let delta = HabitEngine.newValue(for: action, current: dayValue) - dayValue
        onAction(action)
        if delta > 0 { logged += 1 }
        if !wasDone && HabitEngine.status(habit, total: total + delta).tone == .done { bloomed += 1 }
    }
}

/// Statut en texte coloré, avec un symbole pour ne pas dépendre de la couleur seule.
struct StatusLine: View {
    let status: HabitStatus

    var body: some View {
        HStack(spacing: 4) {
            if let symbol = status.tone.symbol {
                Image(systemName: symbol)
                    .font(.system(size: 12, weight: .bold))
                    .symbolEffect(.bounce, value: status.tone)
            }
            Text(verbatim: status.label)
                .contentTransition(.opacity)
        }
        .font(.rituel(.semibold, size: 14, relativeTo: .subheadline))
        .foregroundStyle(status.tone.color)
        .animation(.easeOut(duration: 0.25), value: status.label)
    }
}

/// Barres de la semaine (Swift Charts) : couleur de l'habitude, jour choisi en pervenche, ligne d'objectif ou de limite.
private struct WeekBars: View {
    let habit: HabitSpec
    let log: EntryLog
    let selected: Date
    let today: Date

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var grown = false

    private struct Point: Identifiable {
        let id: Int
        let value: Double?
        let color: Color
    }

    var body: some View {
        let cal = log.calendar
        let monday = cal.monday(of: selected)
        let goal: Double? = habit.period == .day ? habit.target : nil
        let points = (0..<7).map { i -> Point in
            let d = cal.adding(days: i, to: monday)
            guard d <= today else { return Point(id: i, value: nil, color: .surface2) }
            let v = log.value(habit.id, on: d)
            let over = habit.kind == .limit && habit.period == .day && QuantityFormat.r2(v) > QuantityFormat.r2(habit.target)
            return Point(id: i, value: v, color: over ? .over : (d == selected ? .accent : habit.color.color))
        }
        let top = max((goal ?? 0) * 1.25, (points.compactMap(\.value).max() ?? 0) * 1.1, 1)
        let show = grown || reduceMotion

        Chart {
            ForEach(points) { p in
                BarMark(x: .value("Jour", p.id), y: .value("Valeur", show ? (p.value.map { max($0, top * 0.04) } ?? top * 0.04) : 0),
                        width: .fixed(10))
                    .foregroundStyle(p.color)
                    .clipShape(Capsule())
            }
            if let goal {
                RuleMark(y: .value(habit.kind == .limit ? "Limite" : "Objectif", goal))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
                    .foregroundStyle(habit.kind == .limit ? Color.edge : Color.ink2.opacity(0.6))
            }
        }
        .chartYScale(domain: 0...top)
        .chartXScale(domain: -0.6...6.6)
        .chartYAxis(.hidden)
        .chartXAxis {
            AxisMarks(values: Array(0..<7)) { value in
                AxisValueLabel {
                    if let i = value.as(Int.self) {
                        Text(verbatim: RituelCalendar.weekdayLetters[i]).font(.rituel(.regular, size: 10, relativeTo: .caption2))
                    }
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: accessibilitySummary(points)))
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.15)) { grown = true }
        }
    }

    private func accessibilitySummary(_ points: [Point]) -> String {
        let days = ["lundi", "mardi", "mercredi", "jeudi", "vendredi", "samedi", "dimanche"]
        let parts = points.compactMap { p in p.value.map { "\(days[p.id]) \(QuantityFormat.value($0, for: habit))" } }
        return "Semaine : " + (parts.isEmpty ? "rien de noté" : parts.joined(separator: ", "))
    }
}

/// Quelques pétales qui s'envolent du bouton quand on note.
private struct PetalBurst: View {
    let trigger: Int
    let tint: Color

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            ForEach(0..<6, id: \.self) { i in
                let angle = Double(i) / 6 * .pi - .pi
                Capsule()
                    .fill(i.isMultiple(of: 2) ? tint : Color.accent)
                    .frame(width: 6, height: 12)
                    .keyframeAnimator(initialValue: BurstFrame(), trigger: trigger) { view, frame in
                        view
                            .rotationEffect(.radians(angle + .pi / 2))
                            .offset(x: cos(angle) * frame.distance, y: sin(angle) * frame.distance - frame.lift)
                            .scaleEffect(frame.scale)
                            .opacity(frame.opacity)
                    } keyframes: { _ in
                        KeyframeTrack(\.distance) { CubicKeyframe(34 + Double(i % 3) * 8, duration: 0.55) }
                        KeyframeTrack(\.lift) { CubicKeyframe(10, duration: 0.55) }
                        KeyframeTrack(\.scale) {
                            CubicKeyframe(1, duration: 0.15)
                            CubicKeyframe(0.6, duration: 0.4)
                        }
                        KeyframeTrack(\.opacity) {
                            CubicKeyframe(1, duration: 0.1)
                            LinearKeyframe(1, duration: 0.2)
                            CubicKeyframe(0, duration: 0.3)
                        }
                    }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .opacity(reduceMotion || trigger == 0 ? 0 : 1)
    }

    private struct BurstFrame {
        var distance: Double = 0
        var lift: Double = 0
        var scale: Double = 0.4
        var opacity: Double = 0
    }
}

/// Reflet doré qui balaie la carte quand l'objectif vient d'être atteint.
private struct GoldenGlint: View {
    let trigger: Int
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geo in
            LinearGradient(colors: [Color.sun.opacity(0), Color.sun.opacity(0.35), Color.sun.opacity(0)],
                           startPoint: .leading, endPoint: .trailing)
                .frame(width: geo.size.width * 0.5)
                .rotationEffect(.degrees(18))
                .keyframeAnimator(initialValue: -geo.size.width * 0.7, trigger: trigger) { view, x in
                    view.offset(x: x)
                } keyframes: { _ in
                    LinearKeyframe(-geo.size.width * 0.7, duration: 0.01)
                    CubicKeyframe(geo.size.width * 1.2, duration: 0.9)
                }
        }
        .clipShape(RoundedRectangle(cornerRadius: Metrics.cardRadius, style: .continuous))
        .opacity(reduceMotion || trigger == 0 ? 0 : 1)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
