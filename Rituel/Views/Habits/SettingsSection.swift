import SwiftUI

/// Réglages : prénom, synchro iCloud, import du sommeil, rappels.
struct SettingsSection: View {
    @AppStorage(SharedDefaults.firstNameKey, store: SharedDefaults.store) private var firstName = ""
    @AppStorage(SharedDefaults.healthSleepImportKey, store: SharedDefaults.store) private var importSleep = false
    @AppStorage(SharedDefaults.remindersEnabledKey, store: SharedDefaults.store) private var remindersEnabled = true
    @FocusState private var nameFocused: Bool

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

                HStack(spacing: 8) {
                    Circle().fill(Color.ink3).frame(width: 7, height: 7)
                    Text("Enregistré sur cet appareil")
                        .font(.rituel(.regular, size: 12, relativeTo: .caption))
                        .foregroundStyle(.ink2)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Synchro iCloud : enregistré sur cet appareil")
            }
            .padding(16)
            .cardStyle()
        }
        .onChange(of: firstName) { _, name in
            if name.count > HabitSpec.maxNameLength { firstName = String(name.prefix(HabitSpec.maxNameLength)) }
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
