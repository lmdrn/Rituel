import SwiftUI

/// Choix rapides d'une quantité : valeur du jour (sommeil) ou ajouts (eau).
struct PresetsRow: View {
    let habit: HabitSpec
    let dayValue: Double
    let perform: (EntryAction) -> Void

    var body: some View {
        let presets = habit.effectivePresets
        HStack(spacing: 5) {
            ForEach(Array(presets.enumerated()), id: \.offset) { index, value in
                if habit.entryMode == .add {
                    presetButton("+" + QuantityFormat.value(value, for: habit, short: true), isOn: false) {
                        perform(.add(value))
                    }
                    .accessibilityLabel(Text(verbatim: "Ajouter \(QuantityFormat.value(value, for: habit))"))
                } else {
                    let plus = index == presets.count - 1 && presets.count > 2 ? "+" : ""
                    let isOn = QuantityFormat.r2(dayValue) == QuantityFormat.r2(value)
                    presetButton(QuantityFormat.value(value, for: habit, short: true) + plus, isOn: isOn) {
                        perform(.set(value))
                    }
                    .accessibilityLabel(Text(verbatim: QuantityFormat.value(value, for: habit) + plus))
                    .accessibilityAddTraits(isOn ? .isSelected : [])
                }
            }
            if dayValue > 0 {
                Button { perform(.clear) } label: {
                    Text(verbatim: habit.entryMode == .add ? "↺" : "×")
                        .font(.rituel(.semibold, size: 15, relativeTo: .subheadline))
                        .foregroundStyle(.accentText)
                        .frame(width: 40)
                        .frame(maxHeight: .infinity)
                        .background { Pebble(shape: Capsule(), base: .accentSoft, lifted: false) }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(habit.entryMode == .add ? "Remettre à zéro ce jour" : "Effacer ce jour")
            }
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    private func presetButton(_ title: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(verbatim: title)
                .font(.rituel(.bold, size: 14, relativeTo: .subheadline))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .foregroundStyle(isOn ? Color.accentInk : Color.accentText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .padding(.horizontal, 2)
                .background {
                    Pebble(shape: Capsule(), base: isOn ? .accent : .accentSoft, lifted: false, glows: isOn)
                }
                .contentShape(Capsule())
        }
        .buttonStyle(PressScaleStyle())
    }
}

/// Mini-frise des 7 jours d'une habitude quotidienne.
struct MiniWeek: View {
    let habit: HabitSpec
    let log: EntryLog
    let selected: Date
    let today: Date

    var body: some View {
        let cal = log.calendar
        let monday = cal.monday(of: selected)
        HStack(spacing: 4) {
            ForEach(0..<7, id: \.self) { i in
                let d = cal.adding(days: i, to: monday)
                let v = log.value(habit.id, on: d)
                cell(HabitEngine.dayCell(habit, value: v, day: d, today: today), text: label(v, future: d > today), current: d == selected)
            }
        }
        .padding(.top, 2)
        .accessibilityHidden(true)
    }

    private func label(_ v: Double, future: Bool) -> String {
        if future { return "" }
        if habit.isAmount { return v > 0 ? QuantityFormat.value(v, for: habit, short: true) : "" }
        return QuantityFormat.number(v)
    }

    private func cell(_ state: DayCellState, text: String, current: Bool) -> some View {
        let shape = RoundedRectangle(cornerRadius: 9, style: .continuous)
        let (fg, bg): (Color, Color) = switch state {
        case .ok: (.ok, .okSoft)
        case .over: (.over, .overSoft)
        case .neutral: (.ink3, .surface2)
        case .future: (.ink3, .clear)
        }
        return Text(verbatim: text)
            .font(.rituel(.regular, size: 10, relativeTo: .caption2))
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .foregroundStyle(fg)
            .frame(maxWidth: .infinity, minHeight: 24)
            .background { if state != .future { Well(shape: shape, color: bg) } }
            .overlay {
                if state == .future {
                    shape.strokeBorder(Color.line, style: StrokeStyle(lineWidth: 1, dash: [3, 2]))
                } else if current {
                    shape.strokeBorder(Color.ink3, lineWidth: 1.5)
                }
            }
    }
}

/// Pilules ou barre de progression pour les périodes semaine et mois.
struct ProgressView: View {
    let display: ProgressDisplay
    let tint: Color

    var body: some View {
        Group {
            switch display {
            case .pips(let pips):
                FlowLayout(spacing: 6) {
                    ForEach(Array(pips.enumerated()), id: \.offset) { _, pip in
                        pipView(pip)
                    }
                }
            case .bar(let fraction, let over):
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Well(shape: Capsule())
                        Pebble(shape: Capsule(), base: over ? .over : tint, lifted: false)
                            .frame(width: max(fraction > 0 ? 10 : 0, geo.size.width * fraction))
                    }
                }
                .frame(height: 8)
            }
        }
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private func pipView(_ pip: PipState) -> some View {
        let shape = Capsule()
        switch pip {
        case .empty:
            Well(shape: shape).frame(width: 22, height: 10)
        case .on:
            Pebble(shape: shape, base: tint, lifted: false).frame(width: 22, height: 10)
        case .over:
            Pebble(shape: shape, base: .over, lifted: false).frame(width: 22, height: 10)
        case .bonus:
            Pebble(shape: shape, base: .ok, lifted: false).frame(width: 12, height: 10)
        }
    }
}

/// Dispose les éléments en lignes, avec retour à la ligne.
struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = arrange(width: proposal.width ?? .infinity, subviews: subviews)
        let height = rows.last.map { $0.y + $0.height } ?? 0
        let width = rows.map(\.width).max() ?? 0
        return CGSize(width: proposal.width ?? width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        for row in arrange(width: bounds.width, subviews: subviews) {
            var x = bounds.minX
            for index in row.indices {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(at: CGPoint(x: x, y: bounds.minY + row.y + (row.height - size.height) / 2), proposal: .unspecified)
                x += size.width + spacing
            }
        }
    }

    private struct Row {
        var indices: [Int] = []
        var y: CGFloat = 0
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    private func arrange(width: CGFloat, subviews: Subviews) -> [Row] {
        var rows: [Row] = []
        var row = Row()
        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            let needed = row.indices.isEmpty ? size.width : row.width + spacing + size.width
            if needed > width && !row.indices.isEmpty {
                rows.append(row)
                row = Row(y: row.y + row.height + spacing)
            }
            row.width = row.indices.isEmpty ? size.width : row.width + spacing + size.width
            row.height = max(row.height, size.height)
            row.indices.append(index)
        }
        if !row.indices.isEmpty { rows.append(row) }
        return rows
    }
}
