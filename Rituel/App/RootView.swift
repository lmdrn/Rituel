import SwiftData
import SwiftUI

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
                SoftWaves()
            }
        }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .background:
                wasInBackground = true
            case .active where wasInBackground:
                wasInBackground = false
                refreshID += 1
            default:
                break
            }
        }
        .task {
            DefaultHabits.seedIfNeeded(in: context)
            #if DEBUG
            applyDebugLaunchOptions()
            #endif
        }
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
