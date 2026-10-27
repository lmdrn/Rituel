import SwiftUI

/// Carré pervenche arrondi avec la marguerite blanche et le cœur soleil.
struct BrandMark: View {
    var size: CGFloat = 28

    var body: some View {
        Image("BrandMark")
            .resizable()
            .interpolation(.high)
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: size * 8 / 28, style: .continuous))
            .accessibilityHidden(true)
    }
}

/// Marque + nom « Rituel » en Fraunces.
struct BrandLockup: View {
    var body: some View {
        HStack(spacing: 9) {
            BrandMark()
            Text(verbatim: "Rituel")
                .font(.rituelBrand)
                .foregroundStyle(.ink)
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}
