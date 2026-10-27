import SwiftUI

/// Barre d'onglets flottante en pilule : verre liquide sur iOS 26, onglet actif en pilule pervenche.
struct FloatingTabBar: View {
    @Binding var selection: RituelTab
    @Namespace private var pill

    var body: some View {
        HStack(spacing: 4) {
            ForEach(RituelTab.allCases) { tab in
                let selected = tab == selection
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) { selection = tab }
                } label: {
                    Label(tab.title, systemImage: tab.symbol)
                        .font(.rituel(.bold, size: 14, relativeTo: .subheadline))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 6)
                        .foregroundStyle(selected ? Color.accentInk : Color.ink2)
                        .background {
                            if selected {
                                Pebble(shape: Capsule(), base: .accent, lifted: false, glows: true)
                                    .matchedGeometryEffect(id: "pill", in: pill)
                            }
                        }
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
        .padding(5)
        .modifier(TabBarSurface())
        .frame(maxWidth: 420)
        .padding(.horizontal, Metrics.gutter)
        .padding(.top, 10)
        .padding(.bottom, 4)
        .frame(maxWidth: .infinity)
        .background {
            LinearGradient(stops: [.init(color: .canvas, location: 0.55), .init(color: Color.canvas.opacity(0), location: 1)],
                           startPoint: .bottom, endPoint: .top)
                .ignoresSafeArea()
        }
        .sensoryFeedback(.selection, trigger: selection)
    }
}

private struct TabBarSurface: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.glassEffect(.regular, in: Capsule())
        } else {
            content.raisedSurface(Capsule())
        }
    }
}

#Preview {
    VStack {
        Spacer()
        FloatingTabBar(selection: .constant(.today))
    }
    .background(.canvas)
}
