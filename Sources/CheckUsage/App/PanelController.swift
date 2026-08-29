import AppKit
import Combine
import QuartzCore
import SwiftUI

@MainActor
final class PanelController: NSObject, NSWindowDelegate {
    static let shared = PanelController()

    private var edgePanel: NSPanel?
    private var detailPanel: NSPanel?
    private var settingsWindow: NSWindow?
    private let model = AppModel.shared
    private var globalClick: Any?
    private var localClick: Any?
    private var localKeys: Any?
    private var snapWork: DispatchWorkItem?
    private var programmaticMove = false
    private var lastDetailIndex = 0
    private var ignoreDismissUntil = Date.distantPast
    private var contentSignature = ""
    private var started = false
    private var dragSnapArmed = false
    private var bags = Set<AnyCancellable>()
    private let chrome = WidgetChrome()
    private var lastRevealedVisual: CGRect = .zero
    private var hideWork: DispatchWorkItem?
    private var hoverShowWork: DispatchWorkItem?
    private var hoverHideWork: DispatchWorkItem?
    private var detailPinned = false
    private var globalMouse: Any?
    private var localMouse: Any?
    private var edgePlaced = false

    func start() {
        guard !started else { return }
        started = true
        applyWidgetVisibility()
        installMonitors()
        registerHotkeys()
        observe(.checkUsageDidRefresh) { $0.relayout() }
        observe(.checkUsagePanelVisibility) { $0.applyWidgetVisibility() }
        observe(.checkUsageLayoutChanged) { $0.applyWidgetVisibility() }
        observe(.checkUsageHotkeysChanged) { $0.registerHotkeys() }
        observe(.checkUsageOpenSettings) { $0.openSettings() }
        observe(NSApplication.didChangeScreenParametersNotification) { $0.relayout() }
        model.objectWillChange
            .debounce(for: .milliseconds(80), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.relayout()
            }
            .store(in: &bags)
    }

    func registerHotkeys() {
        let center = HotKeyCenter.shared
        center.onToggleWidget = { AppModel.shared.togglePanel() }
        center.onToggleDetail = { PanelController.shared.toggleLastDetail() }
        center.register(widget: model.settings.hotkeyWidget, detail: model.settings.hotkeyDetail)
    }

    func applyWidgetVisibility() {
        let show = model.panelVisible && model.settings.widgetEnabled
        if show {
            showEdgePanel()
        } else {
            edgePanel?.orderOut(nil)
            if detailPanel?.isVisible == true, let id = model.selected {
                showDetail(id: id, index: lastDetailIndex)
            }
        }
    }

    func showEdgePanel() {
        if edgePanel == nil {
            let panel = makePanel(size: NSSize(width: 80, height: 200))
            panel.delegate = self
            edgePanel = panel
            contentSignature = ""
        }
        installEdgeContentIfNeeded()
        relayout()
        edgePanel?.orderFrontRegardless()
    }

    func installEdgeContentIfNeeded() {
        let signature = model.visibleProviders.map(\.rawValue).joined(separator: ",")
            + "|\(model.settings.layout.rawValue)|\(model.settings.showRingPercent)"
        guard signature != contentSignature || edgePanel?.contentView == nil else { return }
        contentSignature = signature
        installEdgeContent()
    }

    func installEdgeContent() {
        guard let edgePanel else { return }
        let view = EdgePanelView(
            model: model,
            chrome: chrome,
            onSelect: { [weak self] id, index in
                self?.toggleDetail(id: id, index: index)
            },
            onToggleSettings: { [weak self] in
                self?.openSettings()
            }
        )
        install(view, in: edgePanel)
    }

    func toggleDetail(id: ProviderID, index: Int) {
        lastDetailIndex = index
        if model.selected == id, detailPanel?.isVisible == true, detailPinned {
            hideDetail()
            return
        }
        detailPinned = true
        hoverHideWork?.cancel()
        model.select(id)
        showDetail(id: id, index: index)
    }

    func toggleLastDetail() {
        let id = model.selected
            ?? model.lastSelected
            ?? model.worstReady?.provider
            ?? model.visibleProviders.first
        guard let id else {
            openSettings()
            return
        }
        let index = model.visibleProviders.firstIndex(of: id) ?? 0
        toggleDetail(id: id, index: index)
    }

    func showDetail(id: ProviderID, index: Int) {
        revealWidget(animated: false)
        lastDetailIndex = index
        let placement = currentPlacement()
        let layout = model.settings.layout
        let anchor = LayoutMath.detailAnchor(placement: placement, layout: layout)
        var pointerY: CGFloat = 0.5
        func root(_ pointer: CGFloat) -> DetailPopoverView {
            DetailPopoverView(
                id: id,
                state: model.states[id] ?? .idle,
                anchor: anchor,
                pointerY: pointer,
                onRefresh: { Task { await AppModel.shared.refresh() } },
                onOpenDashboard: {
                    if let url = id.dashboardURL {
                        NSWorkspace.shared.open(url)
                    }
                }
            )
        }
        let host = ClearHostingController(rootView: root(pointerY))
        host.view.layoutSubtreeIfNeeded()
        let fitting = NSSize(width: Theme.popoverWidth + Theme.chromePad * 2 + Theme.pointer, height: 1100)
        var size = host.sizeThatFits(in: fitting)
        if detailPanel == nil {
            let panel = makePanel(size: size)
            panel.isMovableByWindowBackground = true
            detailPanel = panel
        }
        var frame = detailRect(size: size, index: index, placement: placement)
        if let widget = visualWidgetFrame() {
            let ring = LayoutMath.ringCenter(
                widget: widget,
                layout: layout,
                index: index,
                scale: model.settings.widgetScale
            )
            let fromTop = (frame.maxY - ring.y) / max(frame.height, 1)
            pointerY = min(0.86, max(0.14, fromTop))
            host.rootView = root(pointerY)
            size = host.sizeThatFits(in: fitting)
            frame = detailRect(size: size, index: index, placement: placement)
        }
        install(host.rootView, in: detailPanel!, host: host)
        beginProgrammaticMove()
        detailPanel?.setFrame(frame, display: true, animate: false)
        ignoreDismissUntil = Date().addingTimeInterval(0.28)
        detailPanel?.orderFrontRegardless()
    }

    func hideDetail() {
        detailPinned = false
        hoverShowWork?.cancel()
        hoverHideWork?.cancel()
        detailPanel?.orderOut(nil)
        model.select(nil)
        scheduleTuck()
    }

    func relayout() {
        installEdgeContentIfNeeded()
        guard model.panelVisible, model.settings.widgetEnabled else {
            if detailPanel?.isVisible == true, let id = model.selected {
                showDetail(id: id, index: lastDetailIndex)
            }
            return
        }
        guard let edgePanel, let screen = NSScreen.main ?? NSScreen.screens.first else { return }
        let metrics = WidgetMetrics(
            scale: model.settings.widgetScale,
            count: max(1, model.visibleProviders.count),
            showPercent: model.settings.showRingPercent,
            layout: model.settings.layout,
            shortReset: hasShortReset
        )
        let visual: CGRect
        if model.settings.useCustomOrigin {
            visual = LayoutMath.clampedFrame(
                origin: CGPoint(x: model.settings.customX, y: model.settings.customY),
                size: metrics.size,
                visible: screen.visibleFrame
            )
        } else {
            visual = LayoutMath.widgetFrame(
                visible: screen.visibleFrame,
                placement: model.settings.placement,
                size: metrics.size,
                inset: model.settings.edgeInset
            )
        }
        lastRevealedVisual = visual
        chrome.hideEdge = currentPlacement().hideEdge
        chrome.tone = UsageTone.from(percent: model.worstReady?.primaryPercent ?? 0)
        if !model.settings.autoHide {
            chrome.peeked = false
        } else if !chrome.peeked, !shouldStayRevealed {
            chrome.peeked = true
        }
        applyEdgeFrame(animated: true)
        edgePanel.orderFrontRegardless()
        if detailPanel?.isVisible == true, let id = model.selected {
            showDetail(id: id, index: lastDetailIndex)
        }
    }

    func openSettings() {
        if settingsWindow == nil {
            let host = NSHostingController(
                rootView: SettingsView(settings: model.settings) { [weak self] in
                    Task { @MainActor in
                        AppModel.shared.restartTimer()
                        self?.registerHotkeys()
                        await AppModel.shared.refresh()
                        self?.applyWidgetVisibility()
                    }
                }
            )
            let window = NSWindow(contentViewController: host)
            window.styleMask = [.titled, .closable, .miniaturizable]
            window.setContentSize(NSSize(width: 640, height: 580))
            window.center()
            window.isReleasedWhenClosed = false
            settingsWindow = window
        }
        settingsWindow?.title = L10n.t("settings")
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    nonisolated func windowDidMove(_ notification: Notification) {
        Task { @MainActor in
            self.scheduleSnap()
        }
    }

    private func currentPlacement() -> WidgetPlacement {
        guard let screen = NSScreen.main ?? NSScreen.screens.first, let widget = visualWidgetFrame() else {
            return model.settings.placement
        }
        if model.settings.useCustomOrigin {
            return LayoutMath.nearestPlacement(
                for: CGPoint(x: widget.midX, y: widget.midY),
                in: screen.visibleFrame
            )
        }
        return model.settings.placement
    }

    private func visualWidgetFrame() -> CGRect? {
        if lastRevealedVisual.width > 1 {
            return lastRevealedVisual
        }
        guard let edgePanel, edgePanel.isVisible else { return nil }
        return LayoutMath.visualFrame(window: edgePanel.frame)
    }

    private var shouldStayRevealed: Bool {
        if !model.settings.autoHide { return true }
        if detailPanel?.isVisible == true { return true }
        if !model.settings.positionLocked, NSEvent.pressedMouseButtons != 0 { return true }
        return hoverContains(NSEvent.mouseLocation)
    }

    private func applyEdgeFrame(animated: Bool) {
        guard let edgePanel, let screen = NSScreen.main ?? NSScreen.screens.first else { return }
        let revealedWindow = LayoutMath.chromeFrame(visual: lastRevealedVisual)
        guard revealedWindow.width > 1 else { return }
        let target: CGRect
        if model.settings.autoHide, chrome.peeked {
            target = LayoutMath.tuckedWindowFrame(
                revealed: revealedWindow,
                edge: chrome.hideEdge,
                visible: screen.visibleFrame,
                peek: Theme.peekVisible
            )
        } else {
            target = revealedWindow
        }
        edgePanel.isMovableByWindowBackground = !model.settings.positionLocked && !chrome.peeked
        if framesClose(edgePanel.frame, target) {
            return
        }
        let shouldAnimate = animated && edgePlaced
        beginProgrammaticMove()
        if shouldAnimate {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = chrome.peeked ? 0.42 : 0.32
                context.timingFunction = CAMediaTimingFunction(controlPoints: 0.22, 0.9, 0.28, 1)
                context.allowsImplicitAnimation = true
                edgePanel.animator().setFrame(target, display: true)
            }
        } else {
            edgePanel.setFrame(target, display: true, animate: false)
        }
        edgePlaced = true
    }

    private func framesClose(_ a: CGRect, _ b: CGRect) -> Bool {
        abs(a.minX - b.minX) < 0.6
            && abs(a.minY - b.minY) < 0.6
            && abs(a.width - b.width) < 0.6
            && abs(a.height - b.height) < 0.6
    }

    private func revealWidget(animated: Bool) {
        hideWork?.cancel()
        hideWork = nil
        guard chrome.peeked else { return }
        chrome.peeked = false
        applyEdgeFrame(animated: animated)
    }

    private func scheduleTuck() {
        guard model.settings.autoHide else { return }
        hideWork?.cancel()
        let work = DispatchWorkItem { [weak self] in
            Task { @MainActor in
                guard let self else { return }
                guard self.model.settings.autoHide, !self.shouldStayRevealed else { return }
                self.chrome.peeked = true
                self.applyEdgeFrame(animated: true)
            }
        }
        hideWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.48, execute: work)
    }

    private func hoverContains(_ point: NSPoint) -> Bool {
        guard let edgePanel, edgePanel.isVisible, let screen = NSScreen.main ?? NSScreen.screens.first else {
            return false
        }
        if detailPanel?.isVisible == true, detailPanel?.frame.contains(point) == true {
            return true
        }
        if chrome.peeked {
            let tucked = LayoutMath.tuckedWindowFrame(
                revealed: LayoutMath.chromeFrame(visual: lastRevealedVisual),
                edge: chrome.hideEdge,
                visible: screen.visibleFrame,
                peek: Theme.peekVisible
            )
            return LayoutMath.peekHitRect(
                tucked: tucked,
                edge: chrome.hideEdge,
                peek: Theme.peekVisible,
                slop: 8
            ).contains(point)
        }
        return edgePanel.frame.insetBy(dx: -6, dy: -6).contains(point)
    }

    private var hasShortReset: Bool {
        model.visibleProviders.contains { id in
            ResetCopy.compact(reset: model.states[id]?.snapshot?.primary?.resetsAt) != nil
        }
    }

    private func updateHover() {
        let point = NSEvent.mouseLocation
        if model.settings.autoHide, model.panelVisible, model.settings.widgetEnabled {
            if hoverContains(point) {
                revealWidget(animated: true)
            } else {
                scheduleTuck()
            }
        }
        updateDetailHover(at: point)
    }

    private func updateDetailHover(at point: NSPoint) {
        guard model.panelVisible, model.settings.widgetEnabled else { return }
        if chrome.peeked {
            if !detailPinned { scheduleHoverHide() }
            return
        }
        if detailPinned { return }
        if let hit = ringAt(point) {
            scheduleHoverShow(id: hit.0, index: hit.1)
        } else if detailPanel?.isVisible == true, detailPanel?.frame.insetBy(dx: -6, dy: -6).contains(point) == true {
            hoverHideWork?.cancel()
        } else {
            scheduleHoverHide()
        }
    }

    private func ringAt(_ point: NSPoint) -> (ProviderID, Int)? {
        guard let widget = visualWidgetFrame() else { return nil }
        let scale = model.settings.widgetScale
        let radius = 34 * scale
        for (index, id) in model.visibleProviders.enumerated() {
            let center = LayoutMath.ringCenter(
                widget: widget,
                layout: model.settings.layout,
                index: index,
                scale: scale
            )
            if hypot(point.x - center.x, point.y - center.y) <= radius {
                return (id, index)
            }
        }
        return nil
    }

    private func scheduleHoverShow(id: ProviderID, index: Int) {
        hoverHideWork?.cancel()
        if model.selected == id, detailPanel?.isVisible == true { return }
        hoverShowWork?.cancel()
        let work = DispatchWorkItem { [weak self] in
            Task { @MainActor in
                guard let self, !self.detailPinned else { return }
                self.lastDetailIndex = index
                self.model.select(id)
                self.showDetail(id: id, index: index)
            }
        }
        hoverShowWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12, execute: work)
    }

    private func scheduleHoverHide() {
        hoverShowWork?.cancel()
        guard !detailPinned, detailPanel?.isVisible == true else { return }
        hoverHideWork?.cancel()
        let work = DispatchWorkItem { [weak self] in
            Task { @MainActor in
                guard let self, !self.detailPinned else { return }
                let point = NSEvent.mouseLocation
                if self.ringAt(point) != nil { return }
                if self.detailPanel?.frame.insetBy(dx: -6, dy: -6).contains(point) == true { return }
                self.hideDetail()
            }
        }
        hoverHideWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.28, execute: work)
    }

    private func detailRect(size: NSSize, index: Int, placement: WidgetPlacement) -> CGRect {
        guard let screen = NSScreen.main ?? NSScreen.screens.first else {
            return CGRect(origin: .zero, size: size)
        }
        if let widget = visualWidgetFrame() {
            return LayoutMath.detailFrame(
                widget: widget,
                placement: placement,
                layout: model.settings.layout,
                index: index,
                detailSize: size,
                visible: screen.visibleFrame,
                scale: model.settings.widgetScale
            )
        }
        return LayoutMath.widgetFrame(
            visible: screen.visibleFrame,
            placement: placement,
            size: size,
            inset: max(16, model.settings.edgeInset + 10)
        )
    }

    private func install<V: View>(_ view: V, in panel: NSPanel, host: ClearHostingController<V>? = nil) {
        let root = view.background(Color.clear)
        let hosting = ClearHostingView(rootView: root)
        hosting.wantsLayer = true
        hosting.layer?.backgroundColor = NSColor.clear.cgColor
        hosting.layer?.isOpaque = false
        panel.contentViewController = nil
        panel.contentView = hosting
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        if let usage = panel as? UsagePanel {
            usage.onPointerHover = { [weak self] _ in
                Task { @MainActor in self?.updateHover() }
            }
            usage.refreshTracking()
        }
        _ = host
    }

    private func positionDetail(size: NSSize, index: Int) {
        beginProgrammaticMove()
        detailPanel?.setFrame(detailRect(size: size, index: index, placement: currentPlacement()), display: true, animate: false)
    }

    private func installMonitors() {
        globalClick = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            Task { @MainActor in self?.dismissIfOutside() }
        }
        localClick = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            Task { @MainActor in self?.dismissIfOutside() }
            return event
        }
        localKeys = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53, self?.detailPanel?.isVisible == true {
                Task { @MainActor in self?.hideDetail() }
                return nil
            }
            return event
        }
        globalMouse = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved, .leftMouseDragged]) { [weak self] _ in
            Task { @MainActor in self?.updateHover() }
        }
        localMouse = NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved, .leftMouseDragged]) { [weak self] event in
            Task { @MainActor in self?.updateHover() }
            return event
        }
    }

    private func dismissIfOutside() {
        guard model.settings.dismissOutside, detailPanel?.isVisible == true else { return }
        guard Date() >= ignoreDismissUntil else { return }
        if hitOurWindows(NSEvent.mouseLocation) { return }
        hideDetail()
    }

    private func hitOurWindows(_ point: NSPoint) -> Bool {
        if edgePanel?.isVisible == true, edgePanel?.frame.contains(point) == true { return true }
        if detailPanel?.isVisible == true, detailPanel?.frame.contains(point) == true { return true }
        if settingsWindow?.isVisible == true, settingsWindow?.frame.contains(point) == true { return true }
        return false
    }

    private func scheduleSnap() {
        if chrome.peeked { return }
        if model.settings.positionLocked {
            if !programmaticMove { relayout() }
            return
        }
        if NSEvent.pressedMouseButtons != 0 {
            dragSnapArmed = true
        }
        guard dragSnapArmed, !programmaticMove, edgePanel?.isVisible == true else { return }
        snapWork?.cancel()
        let work = DispatchWorkItem { [weak self] in
            Task { @MainActor in self?.snapToNearest() }
        }
        snapWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16, execute: work)
    }

    private func snapToNearest() {
        guard dragSnapArmed, !programmaticMove, !model.settings.positionLocked else { return }
        guard let edgePanel, let screen = NSScreen.main ?? NSScreen.screens.first else { return }
        dragSnapArmed = false
        let visual = LayoutMath.visualFrame(window: edgePanel.frame)
        if model.settings.snapToEdges {
            model.settings.clearCustomOrigin()
            let nearest = LayoutMath.nearestPlacement(
                for: CGPoint(x: visual.midX, y: visual.midY),
                in: screen.visibleFrame
            )
            if nearest != model.settings.placement {
                model.settings.placement = nearest
            } else {
                relayout()
            }
        } else {
            let clamped = LayoutMath.clampedFrame(
                origin: visual.origin,
                size: visual.size,
                visible: screen.visibleFrame
            )
            model.settings.rememberCustomOrigin(clamped.origin)
            beginProgrammaticMove()
            edgePanel.setFrame(LayoutMath.chromeFrame(visual: clamped), display: true, animate: true)
        }
    }

    private func beginProgrammaticMove() {
        programmaticMove = true
        dragSnapArmed = false
        snapWork?.cancel()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) { [weak self] in
            self?.programmaticMove = false
        }
    }

    private func observe(_ name: Notification.Name, _ handler: @escaping @MainActor (PanelController) -> Void) {
        NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                handler(self)
            }
        }
    }

    private func makePanel(size: NSSize) -> NSPanel {
        let panel = UsagePanel(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.nonactivatingPanel, .fullSizeContentView, .borderless],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.hidesOnDeactivate = false
        panel.becomesKeyOnlyIfNeeded = true
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.animationBehavior = .none
        panel.acceptsMouseMovedEvents = true
        return panel
    }
}

final class UsagePanel: NSPanel {
    var onPointerHover: ((Bool) -> Void)?

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    func refreshTracking() {
        guard let view = contentView else { return }
        for area in view.trackingAreas {
            view.removeTrackingArea(area)
        }
        view.addTrackingArea(
            NSTrackingArea(
                rect: .zero,
                options: [.mouseEnteredAndExited, .mouseMoved, .activeAlways, .inVisibleRect],
                owner: self,
                userInfo: nil
            )
        )
    }

    override func mouseEntered(with event: NSEvent) {
        onPointerHover?(true)
    }

    override func mouseExited(with event: NSEvent) {
        onPointerHover?(false)
    }

    override func mouseMoved(with event: NSEvent) {
        onPointerHover?(true)
    }
}
