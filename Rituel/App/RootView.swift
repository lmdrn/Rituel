import SwiftUI

/// Étape 1 : coquille vide aux couleurs de Rituel. Les onglets arrivent à l'étape 3.
struct RootView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Metrics.sectionSpacing) {
                VStack(alignment: .leading, spacing: 2) {
                    BrandHeader()
                        .padding(.bottom, 14)
                    Text(Date.now.formatted(.dateTime.weekday(.wide).day().month(.wide).locale(.rituel)))
                        .eyebrow()
                    Text("Bonjour")
                        .font(.rituelLargeTitle)
                        .foregroundStyle(.ink)
                    Text("Tout est en équilibre. Continue à ton rythme.")
                        .font(.rituelBody)
                        .foregroundStyle(.ink2)
                        .padding(.top, 6)
                }
                .background(alignment: .topTrailing) {
                    BreathingBlob()
                        .offset(x: 6, y: 30)
                }
            }
            .padding(.horizontal, Metrics.gutter)
            .padding(.vertical, 16)
            .frame(maxWidth: 520)
            .frame(maxWidth: .infinity)
        }
        .background(.canvas)
    }
}

extension Locale {
    /// L'interface est en français : les dates aussi, quelle que soit la langue de l'appareil.
    static let rituel = Locale(identifier: "fr_FR")
}

#Preview("Clair") {
    RootView()
}

#Preview("Sombre") {
    RootView()
        .preferredColorScheme(.dark)
}
