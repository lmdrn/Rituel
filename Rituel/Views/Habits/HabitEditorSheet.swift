import SwiftUI

/// Feuille de création / édition d'une habitude, en Form native.
struct HabitEditorSheet: View {
    @State private var draft: HabitDraft
    let onSave: (HabitSpec) -> Void
    let onDelete: (UUID) -> Void

    @Environment(\.dismiss) private var dismiss
    @FocusState private var nameFocused: Bool
    @State private var confirmDelete = false
    @State private var targetText = ""

    init(draft: HabitDraft, onSave: @escaping (HabitSpec) -> Void, onDelete: @escaping (UUID) -> Void) {
        _draft = State(initialValue: draft)
        _targetText = State(initialValue: draft.targetText)
        self.onSave = onSave
        self.onDelete = onDelete
    }

    var body: some View {
        NavigationStack {
            Form {
                if draft.isNew {
                    Section("Modèles") {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(HabitSpec.templates, id: \.name) { template in
                                    Button {
                                        withAnimation { draft.apply(template: template) }
                                        targetText = draft.targetText
                                    } label: {
                                        Label { Text(verbatim: HabitEngine.previewText(template).replacingOccurrences(of: ".", with: "")) } icon: {
                                            HabitIcon(color: template.color.color, size: 22)
                                        }
                                        .font(.rituel(.semibold, size: 14, relativeTo: .subheadline))
                                    }
                                    .buttonStyle(CapsuleButtonStyle(prominent: false))
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .listRowInsets(EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12))
                    }
                }

                Section {
                    TextField("Café froid, sport, méditation…", text: Binding(get: { draft.spec.name }, set: { draft.setName($0) }))
                        .focused($nameFocused)
                        .submitLabel(.done)
                    Picker("Type", selection: Binding(get: { draft.spec.kind }, set: { draft.setKind($0) })) {
                        Text("Limite").tag(HabitKind.limit)
                        Text("Objectif").tag(HabitKind.goal)
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Nom")
                } footer: {
                    Text(draft.spec.kind == .limit ? "Une limite : pas plus de… Pour ce que tu veux réduire." : "Un objectif : au moins… Pour ce que tu veux cultiver.")
                }

                Section("Mesure") {
                    Picker("Je note", selection: Binding(get: { draft.spec.measure }, set: { draft.setMeasure($0); targetText = draft.targetText })) {
                        Text("Des fois").tag(HabitMeasure.count)
                        Text("Une quantité").tag(HabitMeasure.amount)
                    }
                    .pickerStyle(.segmented)

                    if draft.spec.isAmount {
                        LabeledContent("Unité") {
                            TextField("h, ml, min, pas", text: Binding(get: { draft.spec.unit ?? "" }, set: { draft.setUnit($0) }))
                                .multilineTextAlignment(.trailing)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                        }
                        Picker("Comment je note", selection: Binding(get: { draft.spec.entryMode }, set: { draft.setEntryMode($0) })) {
                            Text("Valeur du jour").tag(EntryMode.set)
                            Text("J'additionne").tag(EntryMode.add)
                        }
                        LabeledContent("Combien") {
                            TextField("8", text: $targetText)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .monospacedDigit()
                                .onChange(of: targetText) { _, text in draft.setTargetText(text) }
                        }
                        LabeledContent("Choix rapides") {
                            TextField("6  6.5  7", text: Binding(get: { draft.presetsText }, set: { draft.setPresetsText($0) }))
                                .keyboardType(.numbersAndPunctuation)
                                .multilineTextAlignment(.trailing)
                                .monospacedDigit()
                        }
                    } else {
                        Stepper(value: Binding(get: { Int(draft.spec.target) }, set: { draft.stepTarget(by: $0 - Int(draft.spec.target)) }),
                                in: (draft.spec.kind == .goal ? 1 : 0)...Int(HabitDraft.maxCountTarget)) {
                            LabeledContent("Combien", value: QuantityFormat.number(draft.spec.target))
                        }
                    }
                    Picker("Par", selection: Binding(get: { draft.spec.period }, set: { draft.setPeriod($0) })) {
                        Text("Jour").tag(HabitPeriod.day)
                        Text("Semaine").tag(HabitPeriod.week)
                        Text("Mois").tag(HabitPeriod.month)
                    }
                }

                healthSection

                Section("Couleur") {
                    ColorChoice(selection: Binding(get: { draft.spec.color }, set: { draft.setColor($0) }))
                }

                Section("Rappel") {
                    Toggle("Me le rappeler chaque jour", isOn: Binding(
                        get: { draft.spec.reminderMinutes != nil },
                        set: { draft.setReminder(minutes: $0 ? (draft.spec.reminderMinutes ?? 20 * 60) : nil) }
                    ))
                    if let minutes = draft.spec.reminderMinutes {
                        DatePicker("Heure", selection: Binding(
                            get: { Self.date(fromMinutes: minutes) },
                            set: { draft.setReminder(minutes: Self.minutes(from: $0)) }
                        ), displayedComponents: .hourAndMinute)
                    }
                }

                Section {
                    HStack(spacing: 12) {
                        Daisy(filled: 7, tint: draft.spec.color.color, heartLit: true, blooms: false)
                            .frame(width: 28, height: 28)
                        Text(verbatim: draft.previewText)
                            .font(.rituel(.titleMedium, size: 17, relativeTo: .body))
                            .contentTransition(.opacity)
                    }
                    .accessibilityElement(children: .combine)
                } header: {
                    Text("Aperçu")
                }

                if !draft.isNew {
                    Section {
                        Button("Supprimer l'habitude", role: .destructive) { confirmDelete = true }
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(draft.isNew ? "Nouvelle habitude" : "Modifier")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Annuler") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Enregistrer") {
                        if let spec = draft.finalized() {
                            onSave(spec)
                            dismiss()
                        } else if draft.problem == .missingName {
                            nameFocused = true
                        }
                    }
                    .fontWeight(.semibold)
                    .disabled(draft.problem != nil)
                }
            }
            .confirmationDialog("Supprimer « \(draft.spec.name) » et tout son historique ?", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("Supprimer", role: .destructive) {
                    onDelete(draft.id)
                    dismiss()
                }
            }
            .onAppear { if draft.isNew { nameFocused = true } }
        }
        .presentationDragIndicator(.visible)
        .tint(.accent)
    }

    // MARK: Santé

    @ViewBuilder
    private var healthSection: some View {
        let sources = draft.compatibleHealthSources
        if !sources.isEmpty {
            Section {
                Picker("Remplir depuis Santé", selection: Binding(get: { draft.spec.healthSource }, set: { draft.setHealthSource($0) })) {
                    Text("Non, je note à la main").tag(HealthSource?.none)
                    ForEach(sources) { Text(verbatim: $0.title).tag(HealthSource?.some($0)) }
                }
                if draft.spec.healthSource == .workouts {
                    Picker("Type de séance", selection: Binding(get: { draft.spec.healthWorkoutKind }, set: { draft.setHealthWorkoutKind($0) })) {
                        Text("Toutes").tag(WorkoutKind?.none)
                        ForEach(WorkoutKind.allCases) { Text(verbatim: $0.title).tag(WorkoutKind?.some($0)) }
                    }
                    Stepper(value: Binding(get: { draft.spec.healthMinMinutes }, set: { draft.setHealthMinMinutes($0) }), in: 0...240, step: 5) {
                        LabeledContent("Durée minimale", value: draft.spec.healthMinMinutes == 0 ? "aucune" : "\(draft.spec.healthMinMinutes) min")
                    }
                }
            } header: {
                Text("Santé")
            } footer: {
                Text("Garmin Connect, Strava et l'Apple Watch peuvent envoyer leurs données dans Santé ; Rituel les lit de là. Ta saisie à la main reste toujours prioritaire.")
            }
        }
    }

    private static func date(fromMinutes minutes: Int) -> Date {
        RituelCalendar.current.calendar.date(bySettingHour: minutes / 60, minute: minutes % 60, second: 0, of: .now) ?? .now
    }

    private static func minutes(from date: Date) -> Int {
        let c = RituelCalendar.current.calendar.dateComponents([.hour, .minute], from: date)
        return (c.hour ?? 0) * 60 + (c.minute ?? 0)
    }
}

/// Les 16 teintes de la palette, en pastilles.
private struct ColorChoice: View {
    @Binding var selection: HabitColor

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 8), spacing: 10) {
            ForEach(HabitColor.allCases) { color in
                let on = color == selection
                Button {
                    withAnimation(.snappy) { selection = color }
                } label: {
                    Circle()
                        .fill(color.color)
                        .padding(on ? 4 : 0)
                        .overlay { if on { Circle().strokeBorder(Color.ink, lineWidth: 2) } }
                        .aspectRatio(1, contentMode: .fit)
                        .frame(minWidth: 28)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(verbatim: color.name))
                .accessibilityAddTraits(on ? .isSelected : [])
            }
        }
        .padding(.vertical, 4)
        .sensoryFeedback(.selection, trigger: selection)
    }
}

#Preview("Nouvelle") {
    Color.clear.sheet(isPresented: .constant(true)) {
        HabitEditorSheet(draft: HabitDraft(newWithSortIndex: 6), onSave: { _ in }, onDelete: { _ in })
    }
}
