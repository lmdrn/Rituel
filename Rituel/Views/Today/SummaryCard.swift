import SwiftData
import SwiftUI

/// Résumé du jour : les 3 habitudes mises en avant, en grandes marguerites, et une ligne sur les limites.
struct SummaryCard: View {
    let habits: [HabitSpec]
    let log: EntryLog
    let selected: Date
    let today: Date

    @State private var choosing = false

    var body: some View {
        let featured = SummaryEngine.featured(habits)
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                Text("Résumé")
                    .font(.rituelCardTitle)
                    .foregroundStyle(.ink)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                Button("Modifier") { choosing = true }
                    .font(.rituel(.semibold, size: 15, relativeTo: .body))
                    .foregroundStyle(.accentText)
                    .frame(minHeight: 44)
            }

            HStack(alignment: .top, spacing: 8) {
                ForEach(Array(featured.enumerated()), id: \.element.id) { index, habit in
                    let total = log.total(habit, periodContaining: selected)
                    VStack(spacing: 8) {
                        Daisy(habit: habit, total: total, delay: Double(index) * 0.12, breathes: true)
                            .frame(width: 84, height: 84)
                        VStack(spacing: 1) {
                            Text(habit.name)
                                .font(.rituel(.bold, size: 12, relativeTo: .caption))
                                .textCase(.uppercase)
                                .foregroundStyle(.ink2)
                                .lineLimit(1)
                            (Text(verbatim: QuantityFormat.value(total, for: habit, short: true))
                                + Text(verbatim: " / \(QuantityFormat.value(habit.target, for: habit, short: true))").foregroundStyle(.ink2))
                                .font(.rituel(.title, size: 17, relativeTo: .headline))
                                .monospacedDigit()
                                .foregroundStyle(.ink)
                                .contentTransition(.numericText(value: total))
                                .animation(.snappy, value: total)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(Text(verbatim: "\(habit.name), \(QuantityFormat.value(total, for: habit)) sur \(QuantityFormat.value(habit.target, for: habit))"))
                }
            }

            if let limits = SummaryEngine.limitsLine(habits, log: log, day: selected) {
                Divider()
                HStack {
                    Text("Limites").foregroundStyle(.ink2)
                    Spacer()
                    Text(verbatim: limits.text)
                        .font(.rituel(.semibold, size: 14, relativeTo: .subheadline))
                        .foregroundStyle(limits.tone.color)
                }
                .font(.rituel(.regular, size: 14, relativeTo: .subheadline))
                .accessibilityElement(children: .combine)
            }
        }
        .padding(16)
        .cardStyle()
        .sheet(isPresented: $choosing) {
            SummaryPickerSheet(habits: habits)
        }
    }
}

/// Choisir jusqu'à 3 habitudes pour le résumé, et leur ordre.
struct SummaryPickerSheet: View {
    let habits: [HabitSpec]

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var chosen: [UUID] = []

    var body: some View {
        let byID = Dictionary(uniqueKeysWithValues: habits.map { ($0.id, $0) })
        NavigationStack {
            List {
                Section {
                    ForEach(chosen, id: \.self) { id in
                        if let habit = byID[id] { row(habit, on: true) }
                    }
                    .onMove { chosen.move(fromOffsets: $0, toOffset: $1) }
                } header: {
                    Text("Dans le résumé")
                } footer: {
                    Text("Jusqu'à 3 habitudes, dans l'ordre où elles apparaissent. Glisse pour les réordonner.")
                }

                Section("Autres habitudes") {
                    ForEach(habits.filter { !chosen.contains($0.id) }) { habit in
                        row(habit, on: false)
                            .disabled(chosen.count >= SummaryEngine.maxFeatured)
                    }
                }
            }
            .environment(\.editMode, .constant(.active))
            .navigationTitle("Résumé")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Annuler") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("OK") {
                        HabitWriter(context: context).setSummary(chosen)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .sensoryFeedback(.selection, trigger: chosen)
            .onAppear { chosen = SummaryEngine.featured(habits).map(\.id) }
        }
        .presentationDragIndicator(.visible)
    }

    private func row(_ habit: HabitSpec, on: Bool) -> some View {
        Button {
            withAnimation { chosen = SummaryEngine.toggling(habit.id, in: chosen) }
        } label: {
            HStack(spacing: 12) {
                HabitIcon(color: habit.color.color)
                VStack(alignment: .leading, spacing: 1) {
                    Text(habit.name).foregroundStyle(.ink)
                    Text(verbatim: HabitEngine.ruleText(habit)).font(.footnote).foregroundStyle(.ink2)
                }
                Spacer()
                Image(systemName: on ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(on ? Color.accent : Color.ink3)
                    .contentTransition(.symbolEffect(.replace))
            }
        }
        .accessibilityAddTraits(on ? .isSelected : [])
    }
}
