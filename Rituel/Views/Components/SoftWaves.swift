import SwiftUI

/// Vagues douces bleu brumeux et rose poudré en haut de l'écran, comme dans la référence « soft clay ».
struct SoftWaves: View {
    var body: some View {
        ZStack(alignment: .top) {
            Wave(phase: 0.15, amplitude: 0.16, baseline: 0.78)
                .fill(LinearGradient(colors: [Color.blush.opacity(0.55), Color.blush.opacity(0.15)], startPoint: .topTrailing, endPoint: .bottomLeading))
            Wave(phase: 0.6, amplitude: 0.12, baseline: 0.58)
                .fill(LinearGradient(colors: [Color.mist.opacity(0.4), Color.mist.opacity(0.08)], startPoint: .topLeading, endPoint: .bottomTrailing))
        }
        .frame(height: 300)
        .frame(maxHeight: .infinity, alignment: .top)
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// Bande remplie du haut jusqu'à une ligne ondulée.
struct Wave: Shape {
    /// Décalage horizontal de l'onde, en fraction de période.
    var phase: CGFloat
    /// Hauteur de l'onde, en fraction de la hauteur.
    var amplitude: CGFloat
    /// Position moyenne de la ligne, en fraction de la hauteur.
    var baseline: CGFloat

    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        let steps = 48
        for i in stride(from: steps, through: 0, by: -1) {
            let t = CGFloat(i) / CGFloat(steps)
            let y = baseline + amplitude * sin((t + phase) * .pi * 2) * (0.6 + 0.4 * t)
            p.addLine(to: CGPoint(x: rect.minX + t * rect.width, y: rect.minY + y * rect.height))
        }
        p.closeSubpath()
        return p
    }
}

#Preview {
    SoftWaves()
        .background(.canvas)
}
