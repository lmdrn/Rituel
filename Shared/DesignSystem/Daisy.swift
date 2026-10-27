import SwiftUI

/// Pétales de la marguerite du logo, réunis en une seule forme (pas de superposition visible entre pétales).
/// Géométrie de reference/logo/rituel-symbole.svg : 7 capsules de 54 × 96 sur 256, cœur de rayon 24.
struct DaisyPetals: Shape {
    var count = 7
    /// Pétales à inclure, dans l'ordre à partir du haut, dans le sens des aiguilles d'une montre.
    var range: Range<Int> = 0..<7

    func path(in rect: CGRect) -> Path {
        let s = min(rect.width, rect.height) / 256
        let center = CGPoint(x: rect.midX, y: rect.midY)
        var union = Path()
        for i in range where i < count {
            let petal = Path(roundedRect: CGRect(x: -27 * s, y: -112 * s, width: 54 * s, height: 96 * s), cornerRadius: 27 * s)
            let angle = Double(i) * 2 * .pi / Double(count)
            let transform = CGAffineTransform(translationX: center.x, y: center.y).rotated(by: angle)
            union = union.union(petal.applying(transform))
        }
        return union
    }
}

/// Marguerite de progression : les pétales se remplissent avec la couleur de l'habitude,
/// le cœur s'allume en soleil quand c'est tenu.
struct Daisy: View {
    /// Nombre de pétales remplis, de 0 à 7.
    var filled: Int
    var tint: Color
    var heartLit = false
    var emptyColor: Color = .surface2

    @Environment(\.colorScheme) private var scheme
    @Environment(\.self) private var environment

    var body: some View {
        let shade = scheme == .dark ? Color.black.opacity(0.35) : Color(hex: 0x3A3AB0, opacity: 0.14)
        ZStack {
            DaisyPetals()
                .fill(emptyColor.shadow(.inner(color: shade, radius: 2, x: 0, y: 1.5)))
            DaisyPetals(range: 0..<filled)
                .fill(
                    LinearGradient(colors: [tint.mixed(with: .white, amount: 0.25, in: environment), tint],
                                   startPoint: .top, endPoint: .bottom)
                        .shadow(.inner(color: .white.opacity(scheme == .dark ? 0.15 : 0.55), radius: 1.5, x: 0, y: 1.5))
                        .shadow(.inner(color: shade, radius: 3, x: 0, y: -2))
                )
                .shadow(color: tint.opacity(filled > 0 ? 0.35 : 0), radius: 6, y: 3)
            GeometryReader { geo in
                let side = min(geo.size.width, geo.size.height) * 48 / 256
                Circle()
                    .fill((heartLit ? Color.sun : emptyColor.mixed(with: .white, amount: 0.3, in: environment))
                        .shadow(.inner(color: .white.opacity(0.6), radius: 1, x: 0, y: 1)))
                    .shadow(color: Color.sun.opacity(heartLit ? 0.7 : 0), radius: heartLit ? 6 : 0)
                    .frame(width: side, height: side)
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

/// Grande marguerite qui respire et tourne lentement (en-têtes). Coupée si Réduire les animations est activé.
struct BreathingDaisy: View {
    var petalColor: Color = .white.opacity(0.16)
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30, paused: reduceMotion)) { context in
            let t = reduceMotion ? 0 : context.date.timeIntervalSinceReferenceDate
            // Respiration lente : un cycle de 9 s ; un tour complet en 90 s.
            let breath = (sin(t * 2 * .pi / 9) + 1) / 2
            GeometryReader { geo in
                let side = min(geo.size.width, geo.size.height)
                ZStack {
                    DaisyPetals().fill(petalColor)
                    Circle()
                        .fill(Color.sun)
                        .frame(width: side * 48 / 256, height: side * 48 / 256)
                        .shadow(color: Color.sun.opacity(0.6), radius: side * (0.04 + 0.025 * breath))
                        .scaleEffect(0.96 + 0.08 * breath)
                }
                .frame(width: side, height: side)
                .rotationEffect(.degrees(t.truncatingRemainder(dividingBy: 90) / 90 * 360))
                .scaleEffect(0.97 + 0.05 * breath)
                .position(x: geo.size.width / 2, y: geo.size.height / 2)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

#Preview {
    HStack(spacing: 20) {
        Daisy(filled: 0, tint: HabitColor.lilas.color)
        Daisy(filled: 3, tint: HabitColor.ciel.color)
        Daisy(filled: 7, tint: HabitColor.menthe.color, heartLit: true)
    }
    .frame(height: 80)
    .padding()
    .background(.canvas)
}
