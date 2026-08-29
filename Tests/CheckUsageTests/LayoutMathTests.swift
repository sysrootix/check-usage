import XCTest
@testable import CheckUsage

final class LayoutMathTests: XCTestCase {
    private let visible = CGRect(x: 0, y: 0, width: 1400, height: 900)

    func testTopTrailingFrame() {
        let frame = LayoutMath.widgetFrame(
            visible: visible,
            placement: .topTrailing,
            size: CGSize(width: 80, height: 160),
            inset: 6
        )
        XCTAssertEqual(frame.maxX, 1400, accuracy: 0.5)
        XCTAssertEqual(frame.maxY, 894, accuracy: 0.5)
    }

    func testTopLeadingFrame() {
        let frame = LayoutMath.widgetFrame(
            visible: visible,
            placement: .topLeading,
            size: CGSize(width: 80, height: 160),
            inset: 8
        )
        XCTAssertEqual(frame.minX, 0, accuracy: 0.5)
        XCTAssertEqual(frame.maxY, 892, accuracy: 0.5)
    }

    func testTrailingCenterFrame() {
        let frame = LayoutMath.widgetFrame(
            visible: visible,
            placement: .trailingCenter,
            size: CGSize(width: 80, height: 160),
            inset: 6
        )
        XCTAssertEqual(frame.maxX, 1400, accuracy: 0.5)
        XCTAssertEqual(frame.midY, 450, accuracy: 0.5)
    }

    func testDetailGoesLeftOnRightWidget() {
        let widget = CGRect(x: 1320, y: 700, width: 80, height: 160)
        let frame = LayoutMath.detailFrame(
            widget: widget,
            placement: .topTrailing,
            layout: .vertical,
            index: 0,
            detailSize: CGSize(width: 268, height: 240),
            visible: visible,
            scale: 1
        )
        XCTAssertLessThan(frame.maxX, widget.minX)
    }

    func testDetailGoesRightOnLeftWidget() {
        let widget = CGRect(x: 8, y: 700, width: 80, height: 160)
        let frame = LayoutMath.detailFrame(
            widget: widget,
            placement: .topLeading,
            layout: .vertical,
            index: 0,
            detailSize: CGSize(width: 268, height: 240),
            visible: visible,
            scale: 1
        )
        XCTAssertGreaterThan(frame.minX, widget.maxX)
    }

    func testMidRightDetailGoesLeft() {
        let widget = CGRect(x: 1320, y: 370, width: 80, height: 160)
        let frame = LayoutMath.detailFrame(
            widget: widget,
            placement: .trailingCenter,
            layout: .vertical,
            index: 0,
            detailSize: CGSize(width: 268, height: 240),
            visible: visible,
            scale: 1
        )
        XCTAssertLessThan(frame.maxX, widget.minX)
    }

    func testTopCenterDetailGoesBelow() {
        let widget = CGRect(x: 660, y: 740, width: 80, height: 160)
        let frame = LayoutMath.detailFrame(
            widget: widget,
            placement: .topCenter,
            layout: .vertical,
            index: 0,
            detailSize: CGSize(width: 268, height: 240),
            visible: visible,
            scale: 1
        )
        XCTAssertLessThan(frame.maxY, widget.minY + 1)
    }

    func testNearestCorner() {
        XCTAssertEqual(LayoutMath.nearestPlacement(for: CGPoint(x: 20, y: 780), in: visible), .topLeading)
        XCTAssertEqual(LayoutMath.nearestPlacement(for: CGPoint(x: 1380, y: 20), in: visible), .bottomTrailing)
        XCTAssertEqual(LayoutMath.nearestPlacement(for: CGPoint(x: 700, y: 890), in: visible), .topCenter)
        XCTAssertEqual(LayoutMath.nearestPlacement(for: CGPoint(x: 1390, y: 450), in: visible), .trailingCenter)
    }

    func testHorizontalMetrics() {
        let metrics = WidgetMetrics(scale: 1, count: 2, showPercent: true, layout: .horizontal)
        XCTAssertEqual(metrics.size.width, 176, accuracy: 0.5)
        XCTAssertEqual(metrics.size.height, 78, accuracy: 0.5)
    }

    func testHideEdgeMatchesCorner() {
        XCTAssertEqual(WidgetPlacement.topTrailing.hideEdge, .right)
        XCTAssertEqual(WidgetPlacement.topLeading.hideEdge, .left)
        XCTAssertEqual(WidgetPlacement.topCenter.hideEdge, .top)
        XCTAssertEqual(WidgetPlacement.bottomCenter.hideEdge, .bottom)
        XCTAssertEqual(WidgetPlacement.trailingCenter.hideEdge, .right)
        XCTAssertEqual(HideEdge.right.chevron, "chevron.left")
        XCTAssertEqual(HideEdge.left.chevron, "chevron.right")
    }

    func testTuckedWindowLeavesPeekOnRight() {
        let revealed = CGRect(x: 1280, y: 700, width: 106, height: 228)
        let tucked = LayoutMath.tuckedWindowFrame(
            revealed: revealed,
            edge: .right,
            visible: visible,
            peek: 18
        )
        XCTAssertEqual(tucked.minX, 1382, accuracy: 0.5)
        XCTAssertEqual(tucked.maxX, 1488, accuracy: 0.5)
        XCTAssertEqual(tucked.minY, revealed.minY, accuracy: 0.5)
        XCTAssertEqual(tucked.height, revealed.height, accuracy: 0.5)
    }

    func testTuckedWindowLeavesPeekOnLeft() {
        let revealed = CGRect(x: 20, y: 400, width: 106, height: 228)
        let tucked = LayoutMath.tuckedWindowFrame(
            revealed: revealed,
            edge: .left,
            visible: visible,
            peek: 18
        )
        XCTAssertEqual(tucked.maxX, 18, accuracy: 0.5)
        XCTAssertEqual(tucked.minX, 18 - 106, accuracy: 0.5)
    }

    func testTuckedWindowLeavesPeekOnTop() {
        let revealed = CGRect(x: 640, y: 700, width: 106, height: 228)
        let tucked = LayoutMath.tuckedWindowFrame(
            revealed: revealed,
            edge: .top,
            visible: visible,
            peek: 18
        )
        XCTAssertEqual(tucked.minY, 882, accuracy: 0.5)
        XCTAssertEqual(tucked.maxY, 1110, accuracy: 0.5)
    }

    func testTuckedWindowLeavesPeekOnBottom() {
        let revealed = CGRect(x: 640, y: 20, width: 106, height: 228)
        let tucked = LayoutMath.tuckedWindowFrame(
            revealed: revealed,
            edge: .bottom,
            visible: visible,
            peek: 18
        )
        XCTAssertEqual(tucked.maxY, 18, accuracy: 0.5)
        XCTAssertEqual(tucked.minY, 18 - 228, accuracy: 0.5)
    }

    func testPeekHitRectCoversVisibleStrip() {
        let tucked = CGRect(x: 1382, y: 700, width: 106, height: 228)
        let hit = LayoutMath.peekHitRect(tucked: tucked, edge: .right, peek: 18, slop: 8)
        XCTAssertTrue(hit.contains(CGPoint(x: 1390, y: 810)))
        XCTAssertFalse(hit.contains(CGPoint(x: 1200, y: 810)))
    }
}
