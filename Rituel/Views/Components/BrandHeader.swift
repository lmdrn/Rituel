import SwiftUI

/// En-tête commun : marque à gauche, pastille « Semaine 44 » (ISO) à droite.
struct BrandHeader: View {
    var date: Date = .now

    private var isoWeek: Int {
        Calendar(identifier: .iso8601).component(.weekOfYear, from: date)
    }

    var body: some View {
        HStack {
            BrandLockup()
            Spacer()
            Text("Semaine \(isoWeek)")
                .font(.rituelChip)
                .monospacedDigit()
                .foregroundStyle(.ink3)
                .padding(.horizontal, 9)
                .padding(.vertical, 4)
                .background { Pebble(shape: Capsule(), lifted: false) }
        }
    }
}

#Preview {
    BrandHeader()
        .padding()
        .background(.canvas)
}
