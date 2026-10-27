import SwiftUI

/// Carte d'une habitude : nom, règle, statut, bouton de saisie et visualisation de la période.
struct HabitCard: View {
    let habit: HabitSpec
    let log: EntryLog
    let selected: Date
    let today: Date
    let onAction: (EntryAction) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var feedback = 0
    @State private var pulse = 0

    private var total: Double { log.total(habit, periodContaining: selected) }
    private var dayValue: Double { log.value(habit.id, on: selected) }
    private var dayWord: String { selected == today ? "aujourd'hui" : "ce jour" }
    private var tint: Color { habit.color.color }

    var body: some View {
        let status = HabitEngine.status(habit, total: total)

        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 14) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Circle().fill(tint).frame(width: 10, height: 10)
                        Text(habit.name)
                            .font(.rituelHeadline)
                            .foregroundStyle(.ink)
                    }
                    Text(HabitEngine.ruleText(habit))
                        .font(.rituelCallout)
                        .foregroundStyle(.ink2)
                    StatusChip(status: status)
                        .padding(.top, 6)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .combine)

                if habit.isAmount { amountCounter } else { countCounter(status) }
            }

            if habit.isAmount {
                PresetsRow(habit: habit, dayValue: dayValue, tint: tint, perform: perform)
            }

            if habit.period == .day {
                MiniWeek(habit: habit, log: log, selected: selected, today: today)
            } else {
                ProgressView(display: HabitEngine.progress(habit, total: total), tint: tint)
            }
        }
        .padding(16)
        .background {
            // Léger halo de la couleur de l'habitude en haut à droite.
            RadialGradient(colors: [tint.opacity(0.22), tint.opacity(0)], center: .topTrailing, startRadius: 0, endRadius: 220)
                .clipShape(RoundedRectangle(cornerRadius: Metrics.cardRadius, style: .continuous))
        }
        .cardStyle()
        .sensoryFeedback(.impact(weight: .light), trigger: feedback)
    }

    private func perform(_ action: EntryAction) {
        onAction(action)
        feedback += 1
        if action != .clear && action != .decrement && !reduceMotion { pulse += 1 }
    }

    // MARK: Compteurs

    private func countCounter(_ status: HabitStatus) -> some View {
        VStack(spacing: 6) {
            Button { perform(.increment) } label: {
                CounterFace(big: QuantityFormat.number(total), of: QuantityFormat.number(habit.target), size: Metrics.tapSize, bigSize: 22, tint: tint)
            }
            .buttonStyle(PressScaleStyle())
            .pulse(pulse)
            .accessibilityLabel(Text(verbatim: "\(habit.name), \(QuantityFormat.number(total)) sur \(QuantityFormat.number(habit.target)), \(status.label.lowercased())"))
            .accessibilityHint(Text("Noter \(dayWord)"))

            HStack(spacing: 6) {
                if dayValue > 0 {
                    Button { perform(.decrement) } label: {
                        Text(verbatim: "−")
                            .font(.system(size: 15))
                            .foregroundStyle(.ink2)
                            .frame(width: 24, height: 24)
                            .background { Pebble(shape: Circle(), base: .surface2, lifted: false) }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Retirer une fois")
                    Text(verbatim: "\(QuantityFormat.number(dayValue)) \(dayWord)")
                        .monospacedDigit()
                } else {
                    Text(habit.kind == .limit ? "Touche si oui" : "Touche quand c'est fait")
                }
            }
            .font(.rituel(.regular, size: 12, relativeTo: .caption))
            .foregroundStyle(.ink2)
            .frame(minHeight: 24)
            .fixedSize()
        }
    }

    private var amountCounter: some View {
        VStack(spacing: 6) {
            CounterFace(
                big: QuantityFormat.value(total, for: habit, short: true),
                of: QuantityFormat.value(habit.target, for: habit, short: true),
                size: Metrics.tapSizeAmount, bigSize: 17, tint: tint
            )
            .pulse(pulse)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(verbatim: "\(QuantityFormat.value(total, for: habit)) sur \(QuantityFormat.value(habit.target, for: habit))"))

            Group {
                if habit.period != .day && dayValue > 0 {
                    Text(verbatim: "\(QuantityFormat.value(dayValue, for: habit, short: true)) \(dayWord)")
                } else {
                    Text(verbatim: dayWord)
                }
            }
            .font(.rituel(.regular, size: 12, relativeTo: .caption))
            .foregroundStyle(.ink2)
            .frame(minHeight: 24)
            .fixedSize()
        }
    }
}

/// Rond de saisie : « total / cible ».
private struct CounterFace: View {
    let big: String
    let of: String
    let size: CGFloat
    let bigSize: CGFloat
    let tint: Color

    @ScaledMetric(relativeTo: .body) private var scale: CGFloat = 1

    var body: some View {
        let side = size * min(scale, 1.35)
        ZStack {
            Pebble(shape: Circle(), base: .surface, tint: tint, tintOpacity: 0.45)
            Circle().strokeBorder(tint.opacity(0.5), lineWidth: 1.5)
            VStack(spacing: 3) {
                Text(verbatim: big)
                    .font(.rituel(.displayText, size: bigSize, relativeTo: .title3))
                    .foregroundStyle(.ink)
                Text(verbatim: "/ \(of)")
                    .font(.rituelSmall)
                    .foregroundStyle(.ink2)
            }
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .padding(.horizontal, 6)
        }
        .frame(width: side, height: side)
    }
}

/// Petit rebond quand on vient de noter.
private struct Pulse: ViewModifier {
    let trigger: Int

    func body(content: Content) -> some View {
        content.keyframeAnimator(initialValue: 1.0, trigger: trigger) { view, scale in
            view.scaleEffect(scale)
        } keyframes: { _ in
            CubicKeyframe(1.1, duration: 0.18)
            CubicKeyframe(1.0, duration: 0.27)
        }
    }
}

private extension View {
    func pulse(_ trigger: Int) -> some View { modifier(Pulse(trigger: trigger)) }
}

struct PressScaleStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct StatusChip: View {
    let status: HabitStatus

    private var colors: (fg: Color, bg: Color) {
        switch status.tone {
        case .ok, .done: (.ok, .okSoft)
        case .edge: (.edge, .edgeSoft)
        case .over: (.over, .overSoft)
        case .progress: (.ink2, .surface2)
        }
    }

    var body: some View {
        HStack(spacing: 6) {
            Circle().frame(width: 6, height: 6)
            Text(verbatim: status.label)
        }
        .font(.rituelChip)
        .foregroundStyle(colors.fg)
        .padding(.horizontal, 9)
        .padding(.vertical, 4)
        .background(colors.bg, in: Capsule())
    }
}
