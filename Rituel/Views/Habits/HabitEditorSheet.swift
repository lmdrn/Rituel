import SwiftUI

/// Feuille de création / édition d'une habitude.
struct HabitEditorSheet: View {
    @State private var draft: HabitDraft
    let onSave: (HabitSpec) -> Void
    let onDelete: (UUID) -> Void

    @Environment(\.dismiss) private var dismiss
    @FocusState private var focus: Field?
    @State private var confirmDelete = false
    @State private var nameHint = false

    private enum Field: Hashable { case name, unit, target, presets }

    init(draft: HabitDraft, onSave: @escaping (HabitSpec) -> Void, onDelete: @escaping (UUID) -> Void) {
        _draft = State(initialValue: draft)
        self.onSave = onSave
        self.onDelete = onDelete
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text(draft.isNew ? "Nouvelle habitude" : "Modifier")
                    .font(.rituelTitle)
                    .foregroundStyle(.ink)
                    .accessibilityAddTraits(.isHeader)

                FormField(label: "Nom") {
                    TextField(nameHint ? "Donne-lui un nom" : "Café froid, sport, méditation…",
                              text: Binding(get: { draft.spec.name }, set: { draft.setName($0) }))
                        .focused($focus, equals: .name)
                        .submitLabel(.done)
                        .rituelField(focused: focus == .name)
                }

                FormField(label: "Type") {
                    ChoiceSegment(options: [
                        .init(value: HabitKind.limit, title: "Limite", subtitle: "pas plus de"),
                        .init(value: HabitKind.goal, title: "Objectif", subtitle: "au moins"),
                    ], selection: Binding(get: { draft.spec.kind }, set: { draft.setKind($0) }))
                }

                FormField(label: "Je suis") {
                    ChoiceSegment(options: [
                        .init(value: HabitMeasure.count, title: "Des fois", subtitle: "je coche"),
                        .init(value: HabitMeasure.amount, title: "Une quantité", subtitle: "heures, ml, min…"),
                    ], selection: Binding(get: { draft.spec.measure }, set: { draft.setMeasure($0) }))
                }

                if draft.spec.isAmount { amountFields } else { countField }

                FormField(label: "Par") {
                    ChoiceSegment(options: [
                        .init(value: HabitPeriod.day, title: "Jour"),
                        .init(value: HabitPeriod.week, title: "Semaine"),
                        .init(value: HabitPeriod.month, title: "Mois"),
                    ], selection: Binding(get: { draft.spec.period }, set: { draft.setPeriod($0) }))
                }

                FormField(label: "Couleur") {
                    ColorGrid(selection: Binding(get: { draft.spec.color }, set: { draft.setColor($0) }))
                }

                reminderField

                Text(verbatim: draft.previewText)
                    .font(.rituelBrand)
                    .foregroundStyle(.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 14)
                    .padding(.leading, 20)
                    .padding(.trailing, 16)
                    .background(alignment: .leading) {
                        UnevenRoundedRectangle(topLeadingRadius: 16, bottomLeadingRadius: 16, style: .continuous)
                            .fill(draft.spec.color.color)
                            .frame(width: 6)
                    }
                    .claySurface(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .accessibilityLabel(Text(verbatim: "Aperçu : \(draft.previewText)"))

                actions
            }
            .padding(.horizontal, 18)
            .padding(.top, 24)
            .padding(.bottom, 22)
            .animation(.easeOut(duration: 0.2), value: draft.spec.measure)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(.canvas)
        .presentationDragIndicator(.visible)
        .presentationBackground(.canvas)
        .presentationCornerRadius(26)
        .onAppear { if draft.isNew { focus = .name } }
    }

    // MARK: Champs

    private var countField: some View {
        FormField(label: "Combien") {
            CountStepper(value: QuantityFormat.number(draft.spec.target),
                         canDecrement: draft.canDecrement, canIncrement: draft.canIncrement) { draft.stepTarget(by: $0) }
        }
    }

    @ViewBuilder
    private var amountFields: some View {
        FormField(label: "Unité") {
            TextField("h, ml, min, km", text: Binding(get: { draft.spec.unit ?? "" }, set: { draft.setUnit($0) }))
                .focused($focus, equals: .unit)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .rituelField(focused: focus == .unit)
        }
        FormField(label: "Comment je note") {
            ChoiceSegment(options: [
                .init(value: EntryMode.set, title: "Valeur du jour", subtitle: "ex. sommeil"),
                .init(value: EntryMode.add, title: "J'additionne", subtitle: "ex. eau"),
            ], selection: Binding(get: { draft.spec.entryMode }, set: { draft.setEntryMode($0) }))
        }
        FormField(label: "Combien") {
            DecimalField(value: draft.spec.target, onChange: { draft.setTargetText($0) })
                .focused($focus, equals: .target)
                .rituelField(focused: focus == .target)
        }
        FormField(label: "Choix rapides") {
            TextField("6  6.5  7  7.5  8  9", text: Binding(get: { draft.presetsText }, set: { draft.setPresetsText($0) }))
                .focused($focus, equals: .presets)
                .keyboardType(.numbersAndPunctuation)
                .monospacedDigit()
                .rituelField(focused: focus == .presets)
            Text("Séparés par des espaces. Pour les heures, 7.5 = 7h30.")
                .font(.rituel(.regular, size: 12, relativeTo: .caption))
                .foregroundStyle(.ink3)
        }
    }

    private var reminderField: some View {
        FormField(label: "Rappel") {
            VStack(alignment: .leading, spacing: 10) {
                Toggle(isOn: Binding(
                    get: { draft.spec.reminderMinutes != nil },
                    set: { draft.setReminder(minutes: $0 ? (draft.spec.reminderMinutes ?? 20 * 60) : nil) }
                )) {
                    Text("Me le rappeler chaque jour")
                        .font(.rituelBody)
                        .foregroundStyle(.ink)
                }
                .tint(.accent)

                if let minutes = draft.spec.reminderMinutes {
                    DatePicker("Heure", selection: Binding(
                        get: { Self.date(fromMinutes: minutes) },
                        set: { draft.setReminder(minutes: Self.minutes(from: $0)) }
                    ), displayedComponents: .hourAndMinute)
                    .font(.rituelBody)
                    .foregroundStyle(.ink)
                    .tint(.accentText)
                    .environment(\.locale, .rituel)
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .background(.surface, in: RoundedRectangle(cornerRadius: Metrics.fieldRadius, style: .continuous))
        }
    }

    // MARK: Actions

    private var actions: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 10) {
                deleteControls
                Spacer(minLength: 0)
                saveControls
            }
            VStack(alignment: .leading, spacing: 12) {
                saveControls
                deleteControls
            }
        }
        .padding(.top, 4)
    }

    @ViewBuilder
    private var deleteControls: some View {
        if !draft.isNew {
            if confirmDelete {
                HStack(spacing: 8) {
                    Text("Supprimer pour de bon ?")
                        .font(.rituelCallout)
                        .foregroundStyle(.over)
                    Button("Oui, supprimer") {
                        onDelete(draft.id)
                        dismiss()
                    }
                    .buttonStyle(PillButtonStyle(kind: .ghost))
                    Button("Non") { confirmDelete = false }
                        .buttonStyle(PillButtonStyle(kind: .soft))
                }
            } else {
                Button("Supprimer") { confirmDelete = true }
                    .buttonStyle(PillButtonStyle(kind: .ghost))
            }
        }
    }

    private var saveControls: some View {
        HStack(spacing: 8) {
            Button("Annuler") { dismiss() }
                .buttonStyle(PillButtonStyle(kind: .soft))
            Button("Enregistrer", action: save)
                .buttonStyle(PillButtonStyle(kind: .primary))
        }
    }

    private func save() {
        switch draft.problem {
        case .missingName:
            nameHint = true
            focus = .name
        case .missingTarget:
            focus = .target
        case nil:
            if let spec = draft.finalized() {
                onSave(spec)
                dismiss()
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

/// Champ décimal qui garde la saisie telle quelle (« 1, » en cours de frappe) et accepte la virgule.
private struct DecimalField: View {
    let value: Double
    let onChange: (String) -> Void
    @State private var text = ""

    var body: some View {
        TextField("8", text: $text)
            .keyboardType(.decimalPad)
            .monospacedDigit()
            .onAppear { text = QuantityFormat.number(value) }
            .onChange(of: text) { _, new in onChange(new) }
    }
}

#Preview("Nouvelle") {
    Color.canvas.sheet(isPresented: .constant(true)) {
        HabitEditorSheet(draft: HabitDraft(newWithSortIndex: 6), onSave: { _ in }, onDelete: { _ in })
    }
}

#Preview("Sommeil, sombre") {
    Color.canvas.sheet(isPresented: .constant(true)) {
        HabitEditorSheet(draft: HabitDraft(editing: DefaultHabits.specs[0]), onSave: { _ in }, onDelete: { _ in })
    }
    .preferredColorScheme(.dark)
}
