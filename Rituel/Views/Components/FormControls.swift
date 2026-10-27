import SwiftUI

/// Champ de formulaire : libellé au-dessus, contenu dessous.
struct FormField<Content: View>: View {
    let label: LocalizedStringKey
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.rituel(.semibold, size: 13, relativeTo: .subheadline))
                .foregroundStyle(.ink2)
            content
        }
    }
}

/// Champ texte arrondi, bordure pêche quand il a le focus.
struct RituelTextFieldStyle: ViewModifier {
    var isFocused: Bool

    func body(content: Content) -> some View {
        content
            .font(.rituel(.regular, size: 17, relativeTo: .body))
            .foregroundStyle(.ink)
            .tint(.accentText)
            .padding(.vertical, 13)
            .padding(.horizontal, 14)
            .background(.surface, in: RoundedRectangle(cornerRadius: Metrics.fieldRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: Metrics.fieldRadius, style: .continuous)
                    .strokeBorder(isFocused ? Color.accent : Color.line, lineWidth: 1.5)
            }
    }
}

extension View {
    func rituelField(focused: Bool) -> some View { modifier(RituelTextFieldStyle(isFocused: focused)) }
}

/// Contrôle segmenté avec sous-titre (« Limite / pas plus de »).
struct ChoiceSegment<Value: Hashable>: View {
    struct Option {
        let value: Value
        let title: LocalizedStringKey
        var subtitle: LocalizedStringKey? = nil
    }

    let options: [Option]
    @Binding var selection: Value

    var body: some View {
        HStack(spacing: 4) {
            ForEach(options.indices, id: \.self) { i in
                let option = options[i]
                let selected = option.value == selection
                Button {
                    selection = option.value
                } label: {
                    VStack(spacing: 1) {
                        Text(option.title)
                            .font(.rituel(.semibold, size: 14, relativeTo: .subheadline))
                            .foregroundStyle(selected ? Color.ink : Color.ink2)
                        if let subtitle = option.subtitle {
                            Text(subtitle)
                                .font(.rituel(.regular, size: 11, relativeTo: .caption2))
                                .foregroundStyle(.ink3)
                        }
                    }
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 6)
                    .background {
                        if selected { Pebble(shape: RoundedRectangle(cornerRadius: 11, style: .continuous), lifted: false) }
                    }
                    .contentShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selected ? [.isSelected] : [])
            }
        }
        .padding(4)
        .background(.surface2, in: RoundedRectangle(cornerRadius: Metrics.fieldRadius, style: .continuous))
        .animation(.easeOut(duration: 0.15), value: selection)
    }
}

/// Grille des 16 pastilles de couleur.
struct ColorGrid: View {
    @Binding var selection: HabitColor

    @ScaledMetric(relativeTo: .body) private var minSize: CGFloat = 30

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(minimum: minSize), spacing: 10), count: 8), spacing: 10) {
            ForEach(HabitColor.allCases) { color in
                let selected = color == selection
                Button {
                    selection = color
                } label: {
                    Circle()
                        .fill(color.color)
                        .overlay {
                            if selected { Circle().fill(.surface).frame(width: minSize * 0.3, height: minSize * 0.3) }
                        }
                        .padding(3)
                        .overlay { if selected { Circle().strokeBorder(Color.ink, lineWidth: 2) } }
                        .aspectRatio(1, contentMode: .fit)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(verbatim: color.name))
                .accessibilityAddTraits(selected ? [.isSelected] : [])
            }
        }
    }
}

/// − nombre +, pour les cibles en nombre de fois.
struct CountStepper: View {
    let value: String
    let canDecrement: Bool
    let canIncrement: Bool
    let onStep: (Int) -> Void

    var body: some View {
        HStack(spacing: 14) {
            stepButton("−", label: "Moins", enabled: canDecrement) { onStep(-1) }
            Text(verbatim: value)
                .font(.rituel(.displayText, size: 30, relativeTo: .title))
                .monospacedDigit()
                .foregroundStyle(.ink)
                .frame(minWidth: 44)
                .accessibilityHidden(true)
            stepButton("+", label: "Plus", enabled: canIncrement) { onStep(1) }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Combien")
        .accessibilityValue(Text(verbatim: value))
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: if canIncrement { onStep(1) }
            case .decrement: if canDecrement { onStep(-1) }
            @unknown default: break
            }
        }
    }

    private func stepButton(_ symbol: String, label: LocalizedStringKey, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(verbatim: symbol)
                .font(.system(size: 20))
                .foregroundStyle(.ink)
                .frame(width: 44, height: 44)
                .background { Pebble(shape: Circle(), base: .surface2, lifted: false) }
        }
        .buttonStyle(PressScaleStyle())
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.4)
        .accessibilityLabel(label)
    }
}

/// Boutons en pilule : principal (pêche), doux, ou discret (corail).
struct PillButtonStyle: ButtonStyle {
    enum Kind { case primary, soft, ghost }
    var kind: Kind = .primary

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.rituelBodyStrong)
            .foregroundStyle(foreground)
            .padding(.vertical, 12)
            .padding(.horizontal, kind == .ghost ? 8 : 18)
            .background {
                switch kind {
                case .primary: Pebble(shape: Capsule(), base: .accent, lifted: false)
                case .soft: Pebble(shape: Capsule(), base: .surface2, lifted: false)
                case .ghost: Color.clear
                }
            }
            .contentShape(Capsule())
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }

    private var foreground: Color {
        switch kind {
        case .primary: .accentInk
        case .soft: .ink
        case .ghost: .over
        }
    }
}
