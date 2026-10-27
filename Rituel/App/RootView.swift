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
    @State private var tab: RituelTab = .today

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch tab {
                case .today: TodayView()
                case .recap: ComingSoonView(eyebrow: "Récap de la semaine", title: "Bientôt ton récap")
                case .habits: ComingSoonView(eyebrow: "Tes habitudes", title: "Bientôt la liste")
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            FloatingTabBar(selection: $tab)
        }
        .background {
            ZStack {
                Color.canvas.ignoresSafeArea()
                SoftWaves()
            }
        }
        .task { DefaultHabits.seedIfNeeded(in: context) }
    }
}

/// Onglets des étapes 4 et 5, en attendant.
private struct ComingSoonView: View {
    let eyebrow: LocalizedStringKey
    let title: LocalizedStringKey

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 2) {
                BrandHeader().padding(.bottom, 14)
                Text(eyebrow).eyebrow()
                Text(title).font(.rituelLargeTitle).foregroundStyle(.ink)
            }
            .padding(.horizontal, Metrics.gutter)
            .padding(.top, 16)
        }
    }
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
