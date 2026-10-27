import SwiftData
import SwiftUI

/// Onglet « Habitudes » : liste réordonnable, création, édition, réglages.
struct HabitsView: View {
    /// Mis à `true` depuis un autre écran pour ouvrir directement une nouvelle habitude.
    @Binding var startNew: Bool

    @Environment(\.modelContext) private var context
    @Query(sort: \Habit.sortIndex) private var habits: [Habit]
    @State private var editing: HabitDraft?

    var body: some View {
        List {
            Group {
                hero
                    .padding(.bottom, 8)

                ForEach(habits) { habit in
                    HabitRow(spec: habit.spec) { editing = HabitDraft(editing: habit.spec) }
                        .accessibilityAction(named: "Monter") { move(habit.id, by: -1) }
                        .accessibilityAction(named: "Descendre") { move(habit.id, by: 1) }
                }
                .onMove(perform: move)

                if habits.isEmpty {
                    Text("Aucune habitude.")
                        .font(.rituelBody)
                        .foregroundStyle(.ink3)
                        .padding(.vertical, 8)
                }

                VStack(alignment: .leading, spacing: 10) {
                    if habits.count > 1 {
                        Text("Maintiens une habitude puis glisse-la pour changer l'ordre.")
                            .font(.rituel(.regular, size: 12, relativeTo: .caption))
                            .foregroundStyle(.ink3)
                    }
                    Button { newHabit() } label: {
                        Label("Nouvelle habitude", systemImage: "plus")
                    }
                    .buttonStyle(PillButtonStyle(kind: .primary))
                }
                .padding(.top, 6)
                .padding(.bottom, 22)

                SettingsSection()
            }
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 5, leading: Metrics.gutter, bottom: 5, trailing: Metrics.gutter))
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .contentMargins(.top, 16, for: .scrollContent)
        .contentMargins(.bottom, 110, for: .scrollContent)
        .sheet(item: $editing) { draft in
            HabitEditorSheet(draft: draft, onSave: save, onDelete: delete)
        }
        .onChange(of: startNew, initial: true) { _, start in
            if start {
                startNew = false
                newHabit()
            }
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 2) {
            BrandHeader().padding(.bottom, 14)
            Text("\(habits.count) \(HabitEngine.plural(Double(habits.count), "habitude"))").eyebrow()
            Text("Tes habitudes")
                .font(.rituelLargeTitle)
                .foregroundStyle(.ink)
                .accessibilityAddTraits(.isHeader)
            Text("Des limites pour ce que tu veux réduire, des objectifs pour ce que tu veux cultiver.")
                .font(.rituelBody)
                .foregroundStyle(.ink2)
                .padding(.top, 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(alignment: .topTrailing) {
            BreathingBlob().offset(x: 6, y: 30)
        }
    }

    // MARK: Actions

    private func newHabit() {
        editing = HabitDraft(newWithSortIndex: habits.count, usedColors: Set(habits.map(\.colorKey)))
    }

    private func save(_ spec: HabitSpec) {
        HabitWriter(context: context).save(spec)
    }

    private func delete(_ id: UUID) {
        HabitWriter(context: context).delete(id)
    }

    private func move(from source: IndexSet, to destination: Int) {
        var ids = habits.map(\.id)
        ids.move(fromOffsets: source, toOffset: destination)
        HabitWriter(context: context).reorder(ids)
    }

    private func move(_ id: UUID, by offset: Int) {
        var ids = habits.map(\.id)
        guard let i = ids.firstIndex(of: id), ids.indices.contains(i + offset) else { return }
        ids.swapAt(i, i + offset)
        HabitWriter(context: context).reorder(ids)
    }
}

private struct HabitRow: View {
    let spec: HabitSpec
    let onEdit: () -> Void

    var body: some View {
        Button(action: onEdit) {
            HStack(spacing: 12) {
                Circle().fill(spec.color.color).frame(width: 14, height: 14)
                VStack(alignment: .leading, spacing: 2) {
                    Text(spec.name)
                        .font(.rituelBodyStrong)
                        .foregroundStyle(.ink)
                    Text(verbatim: "\(HabitEngine.ruleText(spec)) · \(spec.kind == .limit ? "limite" : "objectif")")
                        .font(.rituelCallout)
                        .foregroundStyle(.ink2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.ink3)
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .cardStyle()
        .accessibilityElement(children: .combine)
        .accessibilityHint("Modifier")
    }
}

#Preview("Habitudes") {
    HabitsView(startNew: .constant(false))
        .background(.canvas)
        .modelContainer(PreviewData.container)
}

#Preview("Sombre") {
    HabitsView(startNew: .constant(false))
        .background(.canvas)
        .modelContainer(PreviewData.container)
        .preferredColorScheme(.dark)
}
