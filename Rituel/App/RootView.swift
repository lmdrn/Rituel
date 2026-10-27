import CoreData
import SwiftData
import SwiftUI
import WidgetKit

enum RituelTab: CaseIterable, Identifiable {
    case today, recap, habits

    var id: Self { self }

    var title: LocalizedStringKey {
        switch self {
        case .today: "Aujourd'hui"
        case .recap: "Récap"
        case .habits: "Habitudes"
        }
    }

    var symbol: String {
        switch self {
        case .today: "checkmark.circle"
        case .recap: "chart.bar"
        case .habits: "list.bullet"
        }
    }
}

struct RootView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase
    @State private var tab: RituelTab = .today
    @State private var startNewHabit = false
    /// Change au retour au premier plan : les écrans relisent alors la base, que les widgets ont pu modifier.
    @State private var refreshID = 0
    @State private var wasInBackground = false

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch tab {
                case .today:
                    TodayView {
                        startNewHabit = true
                        tab = .habits
                    }
                case .recap: RecapView()
                case .habits: HabitsView(startNew: $startNewHabit)
                }
            }
            .id(refreshID)
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            FloatingTabBar(selection: $tab)
        }
        .background {
            ZStack {
                Color.canvas.ignoresSafeArea()
                // Halo pervenche en haut de l'écran, qui donne de la profondeur au fond.
                RadialGradient(colors: [Color.accent.opacity(0.16), .clear], center: .top, startRadius: 0, endRadius: 420)
                    .ignoresSafeArea()
            }
        }
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
            #if DEBUG
            applyDebugLaunchOptions()
            #endif
            RituelShortcuts.updateAppShortcutParameters()
            await refreshNativeData()
        }
    }

    /// Au lancement et au retour au premier plan : doublons de synchro, sommeil de la nuit, puis rappels des prochains jours.
    private func refreshNativeData() async {
        HabitWriter(context: context).removeSyncDuplicates()
        await SleepImporter.importLastNight(into: context)
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
