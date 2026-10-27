import SwiftData
import SwiftUI

/// Onglet « Habitudes » : liste groupée native (réordonner, supprimer), création, réglages.
struct HabitsView: View {
    /// Mis à `true` depuis un autre écran pour ouvrir directement une nouvelle habitude.
    @Binding var startNew: Bool

    @Environment(\.modelContext) private var context
    @Query(sort: \Habit.sortIndex) private var habits: [Habit]
    @State private var editing: HabitDraft?
    @State private var pendingDelete: HabitSpec?

    var body: some View {
        let specs = habits.map(\.spec)
        NavigationStack {
            List {
                ForEach(HabitPeriod.allCases, id: \.self) { period in
                    let group = specs.filter { $0.period == period }
                    if !group.isEmpty {
                        Section(period.sectionTitle) {
                            ForEach(group) { habit in
                                Button { editing = HabitDraft(editing: habit) } label: { HabitRow(habit: habit) }
                                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                        Button("Supprimer", systemImage: "trash", role: .destructive) { pendingDelete = habit }
                                    }
                            }
                            .onMove { move(in: period, from: $0, to: $1, specs: specs) }
                        }
                    }
                }
                if specs.isEmpty {
                    Section { Text("Aucune habitude. Touche + pour commencer.").foregroundStyle(.ink2) }
                } else {
                    Section {} footer: {
                        Text("Touche une habitude pour la modifier. « Modifier » pour changer l'ordre, balaie vers la gauche pour supprimer.")
                    }
                }

                SettingsSection()
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(.canvas)
            .navigationTitle("Habitudes")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { EditButton() }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Nouvelle habitude", systemImage: "plus") { newHabit(specs) }
                }
            }
            .sheet(item: $editing) { draft in
                HabitEditorSheet(draft: draft, onSave: save, onDelete: delete)
            }
            .confirmationDialog("Supprimer « \(pendingDelete?.name ?? "") » et tout son historique ?",
                                isPresented: Binding(get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } }),
                                titleVisibility: .visible) {
                Button("Supprimer", role: .destructive) {
                    if let id = pendingDelete?.id { delete(id) }
                }
            }
            .onChange(of: startNew, initial: true) { _, start in
                if start {
                    startNew = false
                    newHabit(specs)
                }
            }
        }
    }

    // MARK: Actions

    private func newHabit(_ specs: [HabitSpec]) {
        editing = HabitDraft(newWithSortIndex: specs.count, usedColors: Set(specs.map(\.colorKey)))
    }

    private func save(_ spec: HabitSpec) {
        HabitWriter(context: context).save(spec)
        RituelShortcuts.updateAppShortcutParameters()
        Task {
            // La permission n'est demandée qu'au premier rappel activé, et pour la seule donnée Santé choisie.
            if spec.reminderMinutes != nil { await ReminderScheduler.requestAuthorizationIfNeeded() }
            if let source = spec.healthSource {
                await HealthImporter.requestAuthorization(for: [source])
                await HealthImporter.importAll(into: context)
            }
            await ReminderScheduler.sync()
        }
    }

    private func delete(_ id: UUID) {
        withAnimation { HabitWriter(context: context).delete(id) }
        RituelShortcuts.updateAppShortcutParameters()
        Task { await ReminderScheduler.sync() }
    }

    /// Réordonne à l'intérieur d'une période ; l'ordre global reste groupé par période.
    private func move(in period: HabitPeriod, from source: IndexSet, to destination: Int, specs: [HabitSpec]) {
        var groups = Dictionary(grouping: specs, by: \.period).mapValues { $0.map(\.id) }
        groups[period]?.move(fromOffsets: source, toOffset: destination)
        let ordered = HabitPeriod.allCases.flatMap { groups[$0] ?? [] }
        HabitWriter(context: context).reorder(ordered)
    }
}

extension HabitPeriod {
    var sectionTitle: LocalizedStringKey {
        switch self {
        case .day: "Par jour"
        case .week: "Par semaine"
        case .month: "Par mois"
        }
    }
}

private struct HabitRow: View {
    let habit: HabitSpec

    var body: some View {
        HStack(spacing: 12) {
            HabitIcon(color: habit.color.color)
            VStack(alignment: .leading, spacing: 1) {
                Text(habit.name).foregroundStyle(.ink)
                HStack(spacing: 4) {
                    Text(verbatim: HabitEngine.ruleText(habit))
                    if let source = habit.healthSource {
                        Text(verbatim: "· \(source.title) depuis Santé")
                    }
                }
                .font(.footnote)
                .foregroundStyle(.ink2)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.ink3)
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityHint("Modifier")
    }
}

/// Réglages : prénom, rappels, langue, synchro iCloud.
private struct SettingsSection: View {
    @AppStorage(SharedDefaults.firstNameKey, store: SharedDefaults.store) private var firstName = ""
    @AppStorage(SharedDefaults.remindersEnabledKey, store: SharedDefaults.store) private var remindersEnabled = true
    @Environment(\.openURL) private var openURL
    @State private var cloudAvailable = false

    var body: some View {
        Section {
            LabeledContent("Prénom") {
                TextField("Pour te dire bonjour", text: $firstName)
                    .multilineTextAlignment(.trailing)
                    .textContentType(.givenName)
                    .submitLabel(.done)
            }
            Toggle("Rappels", isOn: $remindersEnabled)
            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
            } label: {
                LabeledContent("Langue de l'app") {
                    Text(verbatim: Locale.current.localizedString(forLanguageCode: Bundle.main.preferredLocalizations.first ?? "fr")?.capitalized ?? "Français")
                }
            }
            .foregroundStyle(.ink)
            LabeledContent("iCloud") {
                Label(cloudAvailable ? "Synchronisé" : "Sur cet appareil", systemImage: cloudAvailable ? "checkmark.icloud" : "icloud.slash")
                    .foregroundStyle(cloudAvailable ? Color.ok : Color.ink2)
            }
        } header: {
            Text("Réglages")
        } footer: {
            Text("Pour relier une habitude à Santé (Garmin, Strava ou Apple Watch y envoient leurs données), ouvre-la et choisis « Remplir depuis Santé ».")
        }
        .onChange(of: firstName) { _, name in
            if name.count > HabitSpec.maxNameLength { firstName = String(name.prefix(HabitSpec.maxNameLength)) }
        }
        .onChange(of: remindersEnabled) { _, _ in
            Task { await ReminderScheduler.sync() }
        }
        .task { cloudAvailable = await CloudStatus.isSyncing() }
    }
}

#Preview("Habitudes") {
    HabitsView(startNew: .constant(false))
        .modelContainer(PreviewData.container)
}
