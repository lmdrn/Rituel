import SwiftUI

/// Carte d'une habitude : une marguerite de progression (qu'on touche pour noter un comptage),
/// le nom, la règle, le statut, puis les choix rapides et la visualisation de la période.
struct HabitCard: View {
    let habit: HabitSpec
    let log: EntryLog
    let selected: Date
    let today: Date
    let onAction: (EntryAction) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var feedback = 0
    @State private var bloomed = 0
    @State private var spin = 0.0
    @State private var pop = 0

    private var total: Double { log.total(habit, periodContaining: selected) }
    private var dayValue: Double { log.value(habit.id, on: selected) }
    private var dayWord: String { selected == today ? "aujourd'hui" : "ce jour" }
    private var tint: Color { habit.color.color }

    var body: some View {
        let status = HabitEngine.status(habit, total: total)
        let done = status.tone == .done
        let filled = Int((min(1, habit.target > 0 ? total / habit.target : (total > 0 ? 1 : 0)) * 7).rounded(.down))

        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 16) {
                daisy(filled: filled, done: done, status: status)

                VStack(alignment: .leading, spacing: 3) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(habit.name)
                            .font(.rituelCardTitle)
                            .foregroundStyle(.ink)
                        Spacer(minLength: 8)
                        Text(verbatim: "\(QuantityFormat.value(total, for: habit, short: true)) / \(QuantityFormat.value(habit.target, for: habit, short: true))")
                            .font(.rituel(.semibold, size: 14, relativeTo: .subheadline))
                            .monospacedDigit()
                            .foregroundStyle(.ink2)
                            .contentTransition(.numericText(value: total))
                    }
                    Text(HabitEngine.ruleText(habit))
                        .font(.rituelCallout)
                        .foregroundStyle(.ink2)
                    StatusChip(status: status)
                        .padding(.top, 5)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .combine)
            }

            if habit.isAmount {
                PresetsRow(habit: habit, dayValue: dayValue, perform: perform)
            } else {
                countControls
            }

            if habit.period == .day {
                MiniWeek(habit: habit, log: log, selected: selected, today: today)
            } else {
                ProgressView(display: HabitEngine.progress(habit, total: total), tint: tint)
            }
        }
        .padding(18)
        .background {
            // Halo très léger de la couleur de l'habitude, en haut à gauche, derrière la fleur.
            RadialGradient(colors: [tint.opacity(0.22), tint.opacity(0)], center: UnitPoint(x: 0.12, y: 0.2), startRadius: 0, endRadius: 200)
                .clipShape(RoundedRectangle(cornerRadius: Metrics.cardRadius, style: .continuous))
        }
        .cardStyle()
        .sensoryFeedback(.impact(weight: .light, intensity: 0.6), trigger: feedback)
        .sensoryFeedback(.success, trigger: bloomed)
    }

    // MARK: Marguerite

    @ViewBuilder
    private func daisy(filled: Int, done: Bool, status: HabitStatus) -> some View {
        let flower = Daisy(filled: filled, tint: tint, heartLit: done)
            .frame(width: Metrics.tapSize, height: Metrics.tapSize)
            .rotationEffect(.degrees(spin))
            .keyframeAnimator(initialValue: 1.0, trigger: pop) { view, scale in
                view.scaleEffect(scale)
            } keyframes: { _ in
                CubicKeyframe(1.12, duration: 0.16)
                SpringKeyframe(1.0, duration: 0.4, spring: .bouncy)
            }
            .animation(.spring(response: 0.45, dampingFraction: 0.6), value: filled)

        if habit.isAmount {
            flower
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(verbatim: "\(QuantityFormat.value(total, for: habit)) sur \(QuantityFormat.value(habit.target, for: habit))"))
        } else {
            // Pour un comptage, la fleur est le bouton rond : un tap = +1.
            Button { perform(.increment) } label: { flower.contentShape(Circle()) }
                .buttonStyle(PressScaleStyle())
                .accessibilityLabel(Text(verbatim: "\(habit.name), \(QuantityFormat.number(total)) sur \(QuantityFormat.number(habit.target)), \(status.label.lowercased())"))
                .accessibilityHint(Text("Noter \(dayWord)"))
        }
    }

    private var countControls: some View {
        HStack(spacing: 10) {
            Button { perform(.increment) } label: {
                Label("+1", systemImage: "plus")
                    .labelStyle(.titleOnly)
                    .font(.rituel(.bold, size: 15, relativeTo: .body))
                    .foregroundStyle(.accentInk)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background { Pebble(shape: Capsule(), base: .accent, lifted: false, glows: true) }
            }
            .buttonStyle(PressScaleStyle())
            .accessibilityLabel(Text("Noter \(habit.name) \(dayWord)"))

            if dayValue > 0 {
                Button { perform(.decrement) } label: {
                    Text(verbatim: "−1")
                        .font(.rituel(.bold, size: 15, relativeTo: .body))
                        .foregroundStyle(.accentText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background { Pebble(shape: Capsule(), base: .accentSoft, lifted: false) }
                }
                .buttonStyle(PressScaleStyle())
                .accessibilityLabel("Retirer une fois")
                .transition(.scale(scale: 0.8).combined(with: .opacity))
            }

            Text(verbatim: dayValue > 0 ? "\(QuantityFormat.number(dayValue)) \(dayWord)" : (habit.kind == .limit ? "Touche si oui" : "Touche quand c'est fait"))
                .font(.rituel(.regular, size: 12, relativeTo: .caption))
                .monospacedDigit()
                .foregroundStyle(.ink2)
                .frame(maxWidth: .infinity)
                .contentTransition(.numericText())
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: dayValue > 0)
    }

    private func perform(_ action: EntryAction) {
        let wasDone = HabitEngine.status(habit, total: total).tone == .done
        onAction(action)
        feedback += 1
        let now = HabitEngine.status(habit, total: total + estimatedDelta(action)).tone == .done
        let justBloomed = !wasDone && now
        if justBloomed { bloomed += 1 }
        guard !reduceMotion, action != .clear, action != .decrement else { return }
        // Chaque saisie fait tourner la fleur d'un pétale ; un objectif atteint, d'un tour complet.
        withAnimation(.spring(response: 0.7, dampingFraction: 0.65)) { spin += justBloomed ? 360 : 360 / 7 }
        pop += 1
    }

    /// Variation attendue du total, pour savoir tout de suite si l'objectif vient d'être atteint.
    private func estimatedDelta(_ action: EntryAction) -> Double {
        HabitEngine.newValue(for: action, current: dayValue) - dayValue
    }
}

/// Le bouton s'enfonce puis rebondit.
struct PressScaleStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.5), value: configuration.isPressed)
    }
}

struct StatusChip: View {
    let status: HabitStatus

    private var colors: (fg: Color, bg: Color) {
        switch status.tone {
        case .ok: (.ok, .okSoft)
        case .done: (.sunText, .edgeSoft)
        case .edge: (.edge, .edgeSoft)
        case .over: (.over, .overSoft)
        case .progress: (.accentText, .accentSoft)
        }
    }

    var body: some View {
        HStack(spacing: 6) {
            Circle().frame(width: 6, height: 6)
            Text(verbatim: status.label)
                .contentTransition(.opacity)
        }
        .font(.rituelChip)
        .foregroundStyle(colors.fg)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background { Well(shape: Capsule(), color: colors.bg) }
        .animation(.easeOut(duration: 0.25), value: status.label)
    }
}
