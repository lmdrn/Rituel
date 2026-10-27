import SwiftUI

/// Barre d'onglets flottante en forme de pilule.
struct FloatingTabBar: View {
    @Binding var selection: RituelTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(RituelTab.allCases) { tab in
                let selected = tab == selection
                Button {
                    selection = tab
                } label: {
                    Label(tab.title, systemImage: tab.symbol)
                        .font(.rituel(.semibold, size: 14, relativeTo: .subheadline))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .padding(.horizontal, 6)
                        .foregroundStyle(selected ? Color.accentInk : Color.ink2)
                        .background {
                            if selected { Pebble(shape: Capsule(), base: .accent, lifted: false) }
                        }
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
        .padding(5)
        .claySurface(Capsule())
        .frame(maxWidth: 420)
        .padding(.horizontal, Metrics.gutter)
        .padding(.top, 10)
        .padding(.bottom, 4)
        .frame(maxWidth: .infinity)
        .background {
            LinearGradient(stops: [.init(color: .canvas, location: 0.6), .init(color: Color.canvas.opacity(0), location: 1)],
                           startPoint: .bottom, endPoint: .top)
                .ignoresSafeArea()
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
