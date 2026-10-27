import SwiftUI

/// En-tête commun : un carré pervenche comme le logo, la marque, la pastille « Semaine 44 »,
/// et une grande marguerite qui respire et tourne lentement en filigrane.
struct HeroCard: View {
    var date: Date = .now
    let eyebrow: String
    let title: String
    var subtitle: String? = nil

    private var isoWeek: Int { RituelCalendar.current.isoWeek(date) }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 34, style: .continuous)
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                BrandLockup()
                Spacer()
                Text("Semaine \(isoWeek)")
                    .font(.rituelChip)
                    .monospacedDigit()
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .heroGlass(Capsule())
            }
            .padding(.bottom, 12)

            Text(verbatim: eyebrow).eyebrow(.white.opacity(0.8))
            Text(verbatim: title)
                .font(.rituelLargeTitle)
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
                .contentTransition(.opacity)
            if let subtitle {
                Text(verbatim: subtitle)
                    .font(.rituelBody)
                    .foregroundStyle(.white.opacity(0.9))
                    .frame(maxWidth: 250, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            ZStack(alignment: .bottomTrailing) {
                shape.fill(
                    LinearGradient(colors: [Color(hex: 0x6262F8), .brand, Color(hex: 0x3A3AD8)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                        .shadow(.inner(color: .white.opacity(0.35), radius: 2, x: 0, y: 2))
                        .shadow(.inner(color: Color(hex: 0x20208A, opacity: 0.45), radius: 14, x: 0, y: -8))
                )
                BreathingDaisy()
                    .frame(width: 210, height: 210)
                    .offset(x: 70, y: 78)
            }
            .clipShape(shape)
            .shadow(color: Color.brand.opacity(0.35), radius: 18, y: 10)
        }
    }
}

/// Marque + nom « Rituel », en blanc sur le pervenche.
struct BrandLockup: View {
    var body: some View {
        HStack(spacing: 8) {
            BrandMark(size: 28)
                .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).strokeBorder(.white.opacity(0.35), lineWidth: 1))
            Text(verbatim: "Rituel")
                .font(.rituelBrand)
                .foregroundStyle(.white)
        }
        .accessibilityElement(children: .combine)
    }
}

extension View {
    /// Verre liquide teinté pervenche sur iOS 26 (le texte blanc reste lisible en mode clair), voile blanc avant.
    @ViewBuilder
    func heroGlass<S: Shape>(_ shape: S) -> some View {
        if #available(iOS 26.0, *) {
            glassEffect(.regular.tint(Color.brand.opacity(0.55)), in: shape)
        } else {
            background(.white.opacity(0.2), in: shape)
        }
    }
}

#Preview {
    HeroCard(eyebrow: "mardi 27 octobre", title: "Bonsoir Léa", subtitle: "Tout est en équilibre. Continue à ton rythme.")
        .padding()
        .background(.canvas)
}
