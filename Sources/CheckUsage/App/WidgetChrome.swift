import SwiftUI

@MainActor
final class WidgetChrome: ObservableObject {
    @Published var peeked = false
    @Published var hideEdge: HideEdge = .right
    @Published var tone: UsageTone = .good
}

struct PeekTab: View {
    var edge: HideEdge
    var tone: Color
    var peeked: Bool

    @State private var nudge = false

    var body: some View {
        let vertical = edge.isVertical
        ZStack {
            Capsule()
                .fill(Theme.panelFill)
            Capsule()
                .stroke(Theme.hairline, lineWidth: 0.7)
            Image(systemName: edge.chevron)
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(tone)
                .offset(nudgeOffset)
        }
        .frame(
            width: vertical ? Theme.peekVisible : Theme.peekLength,
            height: vertical ? Theme.peekLength : Theme.peekVisible
        )
        .onAppear { nudge = peeked }
        .onChange(of: peeked) { _, value in
            nudge = value
        }
        .animation(
            peeked ? .easeInOut(duration: 1.05).repeatForever(autoreverses: true) : .easeOut(duration: 0.2),
            value: nudge
        )
        .accessibilityLabel(L10n.t("auto_hide"))
    }

    private var nudgeOffset: CGSize {
        guard peeked, nudge else { return .zero }
        switch edge {
        case .right: return CGSize(width: -1.6, height: 0)
        case .left: return CGSize(width: 1.6, height: 0)
        case .top: return CGSize(width: 0, height: 1.6)
        case .bottom: return CGSize(width: 0, height: -1.6)
        }
    }
}
