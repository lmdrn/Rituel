import SwiftUI

/// Forme organique pêche et bleu brumeux qui « respire » derrière le titre (cycle de 9 s).
struct BreathingBlob: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var inhale = false

    var body: some View {
        BlobShape()
            .fill(
                RadialGradient(
                    colors: [Color.accent.opacity(0.8), Color.mist.opacity(0.65)],
                    center: UnitPoint(x: 0.35, y: 0.35),
                    startRadius: 0,
                    endRadius: 92 * 0.72
                )
            )
            .frame(width: 92, height: 92)
            .opacity(0.55)
            .blur(radius: 6)
            .scaleEffect(inhale ? 1.12 : 1)
            .rotationEffect(.degrees(inhale ? 14 : 0))
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            .onAppear { breathe() }
            .onChange(of: reduceMotion) { breathe() }
    }

    private func breathe() {
        guard !reduceMotion else {
            inhale = false
            return
        }
        withAnimation(.easeInOut(duration: 4.5).repeatForever(autoreverses: true)) {
            inhale = true
        }
    }
}

/// Reprend le `border-radius: 46% 54% 58% 42% / 48% 44% 56% 52%` de la version web.
struct BlobShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width, h = rect.height, k: CGFloat = 0.5523
        let tl = CGSize(width: 0.46 * w, height: 0.48 * h)
        let tr = CGSize(width: 0.54 * w, height: 0.44 * h)
        let br = CGSize(width: 0.58 * w, height: 0.56 * h)
        let bl = CGSize(width: 0.42 * w, height: 0.52 * h)

        var p = Path()
        p.move(to: CGPoint(x: tl.width, y: 0))
        p.addLine(to: CGPoint(x: w - tr.width, y: 0))
        p.addCurve(to: CGPoint(x: w, y: tr.height),
                   control1: CGPoint(x: w - tr.width + k * tr.width, y: 0),
                   control2: CGPoint(x: w, y: tr.height - k * tr.height))
        p.addLine(to: CGPoint(x: w, y: h - br.height))
        p.addCurve(to: CGPoint(x: w - br.width, y: h),
                   control1: CGPoint(x: w, y: h - br.height + k * br.height),
                   control2: CGPoint(x: w - br.width + k * br.width, y: h))
        p.addLine(to: CGPoint(x: bl.width, y: h))
        p.addCurve(to: CGPoint(x: 0, y: h - bl.height),
                   control1: CGPoint(x: bl.width - k * bl.width, y: h),
                   control2: CGPoint(x: 0, y: h - bl.height + k * bl.height))
        p.addLine(to: CGPoint(x: 0, y: tl.height))
        p.addCurve(to: CGPoint(x: tl.width, y: 0),
                   control1: CGPoint(x: 0, y: tl.height - k * tl.height),
                   control2: CGPoint(x: tl.width - k * tl.width, y: 0))
        p.closeSubpath()
        return p.offsetBy(dx: rect.minX, dy: rect.minY)
    }
}

#Preview {
    BreathingBlob()
        .padding(40)
        .background(.canvas)
}
