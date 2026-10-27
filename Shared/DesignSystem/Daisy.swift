import SwiftUI

/// Un pétale de la marguerite du logo : capsule de 54 × 96 sur 256, au-dessus du cœur.
private struct Petal: Shape {
    func path(in rect: CGRect) -> Path {
        let s = min(rect.width, rect.height) / 256
        return Path(roundedRect: CGRect(x: rect.midX - 27 * s, y: rect.midY - 112 * s, width: 54 * s, height: 96 * s), cornerRadius: 27 * s)
    }
}

/// Pétales réunis en une seule forme (pas de superposition visible), pour les filigranes.
struct DaisyPetals: Shape {
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        var union = Path()
        for i in 0..<7 {
            let transform = CGAffineTransform(translationX: center.x, y: center.y)
                .rotated(by: Double(i) * 2 * .pi / 7)
                .translatedBy(x: -center.x, y: -center.y)
            union = union.union(Petal().path(in: rect).applying(transform))
        }
        return union
    }
}

/// Marguerite de progression : 7 pétales en couleurs pleines (les vides dessous, les remplis par-dessus),
/// un cœur qui s'allume en soleil. Elle éclot pétale par pétale à l'apparition et quand on la remplit.
struct Daisy: View {
    var filled: Int
    var tint: Color
    var heartLit = false
    /// Joue l'éclosion à l'apparition (désactivée par Réduire les animations).
    var blooms = true
    /// Décalage de l'éclosion, pour enchaîner plusieurs fleurs.
    var delay: Double = 0
    /// Respiration très lente au repos (résumé).
    var breathes = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var opened = false
    @State private var inhale = false

    var body: some View {
        let open = opened || !blooms || reduceMotion
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            ZStack {
                ForEach(petalOrder, id: \.self) { i in
                    Petal()
                        .fill(i < filled ? tint : Color.surface2)
                        .scaleEffect(x: 1, y: open ? 1 : 0.01, anchor: UnitPoint(x: 0.5, y: 0.5 - 16.0 / 256))
                        .rotationEffect(.degrees(Double(i) * 360 / 7))
                        .animation(.spring(response: 0.5, dampingFraction: 0.62).delay(delay + Double(i) * 0.05), value: open)
                        .animation(.spring(response: 0.45, dampingFraction: 0.6), value: filled)
                }
                Circle()
                    .fill(heartLit ? Color.sun : Color.surface2)
                    .frame(width: side * 48 / 256, height: side * 48 / 256)
                    .shadow(color: Color.sun.opacity(heartLit ? 0.65 : 0), radius: side * 0.06)
                    .scaleEffect(open ? (heartLit ? 1.08 : 1) : 0.01)
                    .animation(.spring(response: 0.45, dampingFraction: 0.5).delay(open && !opened ? 0 : delay + 0.35), value: open)
                    .animation(.spring(response: 0.4, dampingFraction: 0.45), value: heartLit)
            }
            .frame(width: side, height: side)
            .position(x: geo.size.width / 2, y: geo.size.height / 2)
        }
        .aspectRatio(1, contentMode: .fit)
        .scaleEffect(breathes && inhale ? 1.035 : 1)
        .onAppear {
            opened = true
            guard breathes, !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 4.5).repeatForever(autoreverses: true).delay(delay + 0.8)) { inhale = true }
        }
    }

    /// Pétales vides d'abord, remplis ensuite : ils passent par-dessus, sans transparence.
    private var petalOrder: [Int] {
        Array(filled..<7) + Array(0..<min(7, max(0, filled)))
    }
}

extension Daisy {
    /// Marguerite d'une habitude selon son total (objectif : progression ; limite : ce qui reste).
    init(habit: HabitSpec, total: Double, blooms: Bool = true, delay: Double = 0, breathes: Bool = false) {
        let fill = SummaryEngine.daisyFill(habit, total: total)
        self.init(filled: fill.petals, tint: fill.color == .over ? .over : habit.color.color,
                  heartLit: fill.heartLit, blooms: blooms, delay: delay, breathes: breathes)
    }
}

/// Petite marguerite blanche sur un carré arrondi de la couleur de l'habitude, comme les icônes de Réglages.
struct HabitIcon: View {
    let color: Color
    var size: CGFloat = 30

    var body: some View {
        RoundedRectangle(cornerRadius: size * 0.27, style: .continuous)
            .fill(color)
            .frame(width: size, height: size)
            .overlay {
                ZStack {
                    DaisyPetals().fill(.white)
                    Circle().fill(Color.sun).frame(width: size * 0.73 * 48 / 256)
                }
                .frame(width: size * 0.73, height: size * 0.73)
            }
            .accessibilityHidden(true)
    }
}

#Preview {
    VStack(spacing: 20) {
        HStack(spacing: 20) {
            Daisy(filled: 0, tint: HabitColor.lilas.color)
            Daisy(filled: 4, tint: HabitColor.ciel.color, delay: 0.1)
            Daisy(filled: 7, tint: HabitColor.menthe.color, heartLit: true, delay: 0.2, breathes: true)
        }
        .frame(height: 84)
        HStack { HabitIcon(color: HabitColor.lilas.color); HabitIcon(color: HabitColor.menthe.color) }
    }
    .padding()
    .background(.canvas)
}
