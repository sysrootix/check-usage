import Foundation

enum WidgetPlacement: String, CaseIterable, Identifiable, Codable, Sendable {
    case topLeading
    case topCenter
    case topTrailing
    case leadingCenter
    case trailingCenter
    case bottomLeading
    case bottomCenter
    case bottomTrailing

    var id: String { rawValue }

    var titleKey: String {
        switch self {
        case .topLeading: "place_top_leading"
        case .topCenter: "place_top_center"
        case .topTrailing: "place_top_trailing"
        case .leadingCenter: "place_leading_center"
        case .trailingCenter: "place_trailing_center"
        case .bottomLeading: "place_bottom_leading"
        case .bottomCenter: "place_bottom_center"
        case .bottomTrailing: "place_bottom_trailing"
        }
    }

    var isLeading: Bool {
        self == .topLeading || self == .bottomLeading || self == .leadingCenter
    }

    var isBottom: Bool {
        self == .bottomLeading || self == .bottomTrailing || self == .bottomCenter
    }

    var hideEdge: HideEdge {
        switch self {
        case .topTrailing, .trailingCenter, .bottomTrailing: .right
        case .topLeading, .leadingCenter, .bottomLeading: .left
        case .topCenter: .top
        case .bottomCenter: .bottom
        }
    }
}

enum HideEdge: String, Sendable, Equatable {
    case left, right, top, bottom

    var isVertical: Bool {
        self == .left || self == .right
    }

    var chevron: String {
        switch self {
        case .right: "chevron.left"
        case .left: "chevron.right"
        case .top: "chevron.down"
        case .bottom: "chevron.up"
        }
    }
}

enum WidgetLayout: String, CaseIterable, Identifiable, Codable, Sendable {
    case vertical
    case horizontal

    var id: String { rawValue }

    var titleKey: String {
        switch self {
        case .vertical: "layout_vertical"
        case .horizontal: "layout_horizontal"
        }
    }
}

enum DetailAnchor: Sendable {
    case left, right, above, below
}

struct WidgetMetrics: Equatable, Sendable {
    var scale: CGFloat
    var count: Int
    var showPercent: Bool
    var layout: WidgetLayout
    var shortReset: Bool = false

    var item: CGFloat { ((showPercent ? 78 : 58) + (shortReset ? 14 : 0)) * scale }
    var padding: CGFloat { 10 * scale }
    var ring: CGFloat { 46 * scale }

    var size: CGSize {
        let n = CGFloat(max(count, 1))
        switch layout {
        case .vertical:
            return CGSize(width: 78 * scale, height: padding * 2 + item * n)
        case .horizontal:
            return CGSize(width: padding * 2 + (showPercent ? 78 : 58) * scale * n, height: item)
        }
    }
}

enum LayoutMath {
    static func widgetFrame(
        visible: CGRect,
        placement: WidgetPlacement,
        size: CGSize,
        inset: CGFloat
    ) -> CGRect {
        let x: CGFloat
        let y: CGFloat
        switch placement {
        case .topTrailing:
            x = visible.maxX - size.width
            y = visible.maxY - size.height - inset
        case .topLeading:
            x = visible.minX
            y = visible.maxY - size.height - inset
        case .bottomTrailing:
            x = visible.maxX - size.width
            y = visible.minY + inset
        case .bottomLeading:
            x = visible.minX
            y = visible.minY + inset
        case .topCenter:
            x = visible.midX - size.width / 2
            y = visible.maxY - size.height
        case .bottomCenter:
            x = visible.midX - size.width / 2
            y = visible.minY + inset
        case .leadingCenter:
            x = visible.minX
            y = visible.midY - size.height / 2
        case .trailingCenter:
            x = visible.maxX - size.width
            y = visible.midY - size.height / 2
        }
        return CGRect(x: x, y: y, width: size.width, height: size.height)
    }

    static func detailAnchor(placement: WidgetPlacement, layout: WidgetLayout) -> DetailAnchor {
        switch placement {
        case .leadingCenter: return .right
        case .trailingCenter: return .left
        case .topCenter: return .below
        case .bottomCenter: return .above
        case .topLeading, .bottomLeading:
            return layout == .vertical ? .right : (placement.isBottom ? .above : .below)
        case .topTrailing, .bottomTrailing:
            return layout == .vertical ? .left : (placement.isBottom ? .above : .below)
        }
    }

    static func detailFrame(
        widget: CGRect,
        placement: WidgetPlacement,
        layout: WidgetLayout,
        index: Int,
        detailSize: CGSize,
        visible: CGRect,
        scale: CGFloat
    ) -> CGRect {
        let gap: CGFloat = 3
        let center = ringCenter(widget: widget, layout: layout, index: index, scale: scale)

        let x: CGFloat
        let y: CGFloat
        switch detailAnchor(placement: placement, layout: layout) {
        case .left:
            x = widget.minX - detailSize.width - gap
            y = center.y - detailSize.height / 2
        case .right:
            x = widget.maxX + gap
            y = center.y - detailSize.height / 2
        case .above:
            x = center.x - detailSize.width / 2
            y = widget.maxY + gap
        case .below:
            x = center.x - detailSize.width / 2
            y = widget.minY - detailSize.height - gap
        }

        return CGRect(
            x: min(max(x, visible.minX + 8), visible.maxX - detailSize.width - 8),
            y: min(max(y, visible.minY + 8), visible.maxY - detailSize.height - 8),
            width: detailSize.width,
            height: detailSize.height
        )
    }

    static func ringCenter(widget: CGRect, layout: WidgetLayout, index: Int, scale: CGFloat) -> CGPoint {
        let item = 78 * scale
        let padding = 10 * scale
        switch layout {
        case .vertical:
            return CGPoint(
                x: widget.midX,
                y: widget.maxY - padding - item * CGFloat(index) - item / 2
            )
        case .horizontal:
            return CGPoint(
                x: widget.minX + padding + item * CGFloat(index) + item / 2,
                y: widget.midY
            )
        }
    }

    static func chromeFrame(visual: CGRect, pad: CGFloat = Theme.chromePad) -> CGRect {
        visual.insetBy(dx: -pad, dy: -pad)
    }

    static func visualFrame(window: CGRect, pad: CGFloat = Theme.chromePad) -> CGRect {
        window.insetBy(dx: pad, dy: pad)
    }

    static func clampedFrame(origin: CGPoint, size: CGSize, visible: CGRect) -> CGRect {
        CGRect(
            x: min(max(origin.x, visible.minX), max(visible.minX, visible.maxX - size.width)),
            y: min(max(origin.y, visible.minY), max(visible.minY, visible.maxY - size.height)),
            width: size.width,
            height: size.height
        )
    }

    static func tuckedWindowFrame(
        revealed: CGRect,
        edge: HideEdge,
        visible: CGRect,
        peek: CGFloat
    ) -> CGRect {
        var frame = revealed
        switch edge {
        case .right:
            frame.origin.x = visible.maxX - peek
        case .left:
            frame.origin.x = visible.minX + peek - revealed.width
        case .top:
            frame.origin.y = visible.maxY - peek
        case .bottom:
            frame.origin.y = visible.minY + peek - revealed.height
        }
        return frame
    }

    static func peekHitRect(tucked: CGRect, edge: HideEdge, peek: CGFloat, slop: CGFloat) -> CGRect {
        switch edge {
        case .right:
            CGRect(x: tucked.minX - slop, y: tucked.minY - slop, width: peek + slop * 2, height: tucked.height + slop * 2)
        case .left:
            CGRect(x: tucked.maxX - peek - slop, y: tucked.minY - slop, width: peek + slop * 2, height: tucked.height + slop * 2)
        case .top:
            CGRect(x: tucked.minX - slop, y: tucked.minY - slop, width: tucked.width + slop * 2, height: peek + slop * 2)
        case .bottom:
            CGRect(x: tucked.minX - slop, y: tucked.maxY - peek - slop, width: tucked.width + slop * 2, height: peek + slop * 2)
        }
    }

    static func nearestPlacement(for point: CGPoint, in visible: CGRect) -> WidgetPlacement {
        let candidates: [(WidgetPlacement, CGPoint)] = [
            (.topLeading, CGPoint(x: visible.minX, y: visible.maxY)),
            (.topCenter, CGPoint(x: visible.midX, y: visible.maxY)),
            (.topTrailing, CGPoint(x: visible.maxX, y: visible.maxY)),
            (.leadingCenter, CGPoint(x: visible.minX, y: visible.midY)),
            (.trailingCenter, CGPoint(x: visible.maxX, y: visible.midY)),
            (.bottomLeading, CGPoint(x: visible.minX, y: visible.minY)),
            (.bottomCenter, CGPoint(x: visible.midX, y: visible.minY)),
            (.bottomTrailing, CGPoint(x: visible.maxX, y: visible.minY)),
        ]
        return candidates.min(by: {
            hypot($0.1.x - point.x, $0.1.y - point.y) < hypot($1.1.x - point.x, $1.1.y - point.y)
        })?.0 ?? .topTrailing
    }
}
