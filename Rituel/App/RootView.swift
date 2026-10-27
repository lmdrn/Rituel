import CoreData
import SwiftData
import SwiftUI
import WidgetKit

enum RituelTab: Hashable {
    case today, recap, habits
}

/// Navigation native : trois onglets (barre en Liquid Glass sur iOS 26), chacun avec sa pile et son grand titre.
struct RootView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase
    @State private var tab: RituelTab = .today
    @State private var startNewHabit = false
    /// Change au retour au premier plan : les écrans relisent alors la base, que les widgets ont pu modifier.
    @State private var refreshID = 0
    @State private var wasInBackground = false

    var body: some View {
        TabView(selection: $tab) {
            TodayView {
                startNewHabit = true
                tab = .habits
            }
            .id(refreshID)
            .tabItem { Label("Aujourd'hui", systemImage: "checkmark.circle") }
            .tag(RituelTab.today)

            RecapView()
                .id(refreshID)
                .tabItem { Label("Récap", systemImage: "chart.bar") }
                .tag(RituelTab.recap)

            HabitsView(startNew: $startNewHabit)
                .tabItem { Label("Habitudes", systemImage: "list.bullet") }
                .tag(RituelTab.habits)
        }
        .tint(.accent)
        .sensoryFeedback(.selection, trigger: tab)
        .onReceive(NotificationCenter.default.publisher(for: .NSPersistentStoreRemoteChange).receive(on: RunLoop.main)) { _ in
            // Des données sont arrivées d'un autre appareil : widgets et rappels suivent.
            HabitWriter(context: context).removeSyncDuplicates()
            WidgetCenter.shared.reloadAllTimelines()
            Task { await ReminderScheduler.sync() }
        }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .background:
                wasInBackground = true
            case .active where wasInBackground:
                wasInBackground = false
                refreshID += 1
                Task { await refreshNativeData() }
            default:
                break
            }
        }
        .task {
            DefaultHabits.seedIfNeeded(in: context)
            HealthImporter.migrateLegacySleepSetting(in: context)
            #if DEBUG
            applyDebugLaunchOptions()
            #endif
            RituelShortcuts.updateAppShortcutParameters()
            await refreshNativeData()
        }
    }

    /// Au lancement et au retour au premier plan : doublons de synchro, données Santé, puis rappels.
    private func refreshNativeData() async {
        HabitWriter(context: context).removeSyncDuplicates()
        await HealthImporter.importAll(into: context)
        await ReminderScheduler.sync()
    }

    #if DEBUG
    /// Pour les captures : `-RituelTab habits|recap` choisit l'onglet, `-RituelNewHabit YES` ouvre la feuille.
    private func applyDebugLaunchOptions() {
        let defaults = UserDefaults.standard
        switch defaults.string(forKey: "RituelTab") {
        case "recap": tab = .recap
        case "habits": tab = .habits
        default: break
        }
        if defaults.bool(forKey: "RituelNewHabit") {
            startNewHabit = true
            tab = .habits
        }
    }
    #endif
}

#Preview("Clair") {
    RootView()
        .modelContainer(PreviewData.container)
}

#Preview("Sombre") {
    RootView()
        .modelContainer(PreviewData.container)
        .preferredColorScheme(.dark)
}
