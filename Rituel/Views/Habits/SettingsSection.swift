import SwiftUI

/// Réglages : prénom, synchro iCloud, import du sommeil, rappels.
struct SettingsSection: View {
    @AppStorage(SharedDefaults.firstNameKey, store: SharedDefaults.store) private var firstName = ""
    @AppStorage(SharedDefaults.healthSleepImportKey, store: SharedDefaults.store) private var importSleep = false
    @AppStorage(SharedDefaults.remindersEnabledKey, store: SharedDefaults.store) private var remindersEnabled = true
    @FocusState private var nameFocused: Bool
    @Environment(\.modelContext) private var context
    @State private var cloudAvailable = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Réglages")
                .font(.rituelTitle)
                .foregroundStyle(.ink)
                .accessibilityAddTraits(.isHeader)

            VStack(alignment: .leading, spacing: 16) {
                FormField(label: "Ton prénom") {
                    TextField("Pour te dire bonjour", text: $firstName)
                        .focused($nameFocused)
                        .textContentType(.givenName)
                        .submitLabel(.done)
                        .rituelField(focused: nameFocused)
                }

                divider

                SettingToggle(isOn: $importSleep, title: "Sommeil depuis Santé",
                              detail: "Remplit ton habitude Sommeil avec ton temps de sommeil réel. Une saisie à la main reste prioritaire.")

                divider

                SettingToggle(isOn: $remindersEnabled, title: "Rappels",
                              detail: "Les notifications des habitudes qui ont un rappel. L'heure se règle dans chaque habitude.")

                divider

                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Circle().fill(cloudAvailable ? Color.ok : Color.ink3).frame(width: 7, height: 7)
                    Text(cloudAvailable ? "Synchronisé avec iCloud entre tes appareils"
                                        : "Enregistré sur cet appareil. Connecte-toi à iCloud pour retrouver tes habitudes ailleurs.")
                        .font(.rituel(.regular, size: 12, relativeTo: .caption))
                        .foregroundStyle(.ink2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .accessibilityElement(children: .combine)
                .task { cloudAvailable = await CloudStatus.isSyncing() }

            }
            .padding(16)
            .cardStyle()
        }
        .onChange(of: firstName) { _, name in
            if name.count > HabitSpec.maxNameLength { firstName = String(name.prefix(HabitSpec.maxNameLength)) }
        }
        .onChange(of: importSleep) { _, on in
            guard on else { return }
            Task {
                await SleepImporter.requestAuthorization()
                await SleepImporter.importLastNight(into: context)
            }
        }
        .onChange(of: remindersEnabled) { _, _ in
            Task { await ReminderScheduler.sync() }
        }
    }

    private var divider: some View {
        Rectangle().fill(Color.line).frame(height: 1)
    }
}

private struct SettingToggle: View {
    @Binding var isOn: Bool
    let title: LocalizedStringKey
    let detail: LocalizedStringKey

    var body: some View {
        Toggle(isOn: $isOn) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.rituelBodyStrong)
                    .foregroundStyle(.ink)
                Text(detail)
                    .font(.rituelCallout)
                    .foregroundStyle(.ink2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .tint(.accent)
    }
}
