import AppKit
import SwiftUI

final class ClearHostingView<Content: View>: NSHostingView<Content> {
    override var isOpaque: Bool { false }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        wantsLayer = true
        layer?.isOpaque = false
        layer?.backgroundColor = NSColor.clear.cgColor
        layer?.masksToBounds = false
        window?.isOpaque = false
        window?.backgroundColor = .clear
        window?.hasShadow = false
    }
}

final class ClearHostingController<Content: View>: NSHostingController<Content> {
    override func viewDidLoad() {
        super.viewDidLoad()
        clear()
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        clear()
        view.window?.isOpaque = false
        view.window?.backgroundColor = .clear
        view.window?.hasShadow = false
    }

    private func clear() {
        view.wantsLayer = true
        view.layer?.isOpaque = false
        view.layer?.backgroundColor = NSColor.clear.cgColor
        view.layer?.masksToBounds = false
    }
}

final class FrostedPanelView: NSVisualEffectView {
    var chromeRadius: CGFloat = Theme.popoverRadius
    var capsule = false

    override func layout() {
        super.layout()
        wantsLayer = true
        layer?.masksToBounds = true
        layer?.cornerCurve = .continuous
        layer?.backgroundColor = NSColor.clear.cgColor
        layer?.cornerRadius = capsule ? min(bounds.width, bounds.height) / 2 : chromeRadius
    }
}

struct FrostedPanel: NSViewRepresentable {
    var cornerRadius: CGFloat
    var capsule: Bool = false

    func makeNSView(context: Context) -> FrostedPanelView {
        let view = FrostedPanelView()
        view.material = .hudWindow
        view.blendingMode = .behindWindow
        view.state = .active
        view.chromeRadius = cornerRadius
        view.capsule = capsule
        return view
    }

    func updateNSView(_ view: FrostedPanelView, context: Context) {
        view.chromeRadius = cornerRadius
        view.capsule = capsule
        view.needsLayout = true
    }
}

struct CalloutPointer: View {
    var edge: DetailAnchor
    var fill: Color

    var body: some View {
        PointerShape(edge: edge)
            .fill(fill)
            .frame(
                width: edge == .left || edge == .right ? Theme.pointer : 16,
                height: edge == .above || edge == .below ? Theme.pointer : 16
            )
    }
}

private struct PointerShape: Shape {
    var edge: DetailAnchor

    func path(in rect: CGRect) -> Path {
        var path = Path()
        switch edge {
        case .left:
            path.move(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        case .right:
            path.move(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        case .above:
            path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        case .below:
            path.move(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        }
        path.closeSubpath()
        return path
    }
}
