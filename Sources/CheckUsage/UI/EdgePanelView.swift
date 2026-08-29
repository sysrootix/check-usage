import SwiftUI

struct EdgePanelView: View {
    @ObservedObject var model: AppModel
    @ObservedObject var chrome: WidgetChrome
    @ObservedObject private var settings = SettingsStore.shared
    var onSelect: (ProviderID, Int) -> Void
    var onToggleSettings: () -> Void

    private var scale: CGFloat { settings.widgetScale }

    var body: some View {
        ZStack(alignment: tabAlignment) {
            pill
                .opacity(chrome.peeked ? 0 : 1)
                .allowsHitTesting(!chrome.peeked)
            if chrome.peeked {
                PeekTab(
                    edge: chrome.hideEdge,
                    tone: Theme.toneColor(chrome.tone),
                    peeked: true
                )
                .transition(.opacity.combined(with: .scale(scale: 0.86)))
            }
        }
        .animation(.easeOut(duration: 0.22), value: chrome.peeked)
        .opacity(settings.widgetOpacity)
        .contextMenu {
            Button(settings.positionLocked ? L10n.t("unlock_now") : L10n.t("lock_now")) {
                settings.positionLocked.toggle()
            }
            Button(settings.autoHide ? L10n.t("auto_hide_off") : L10n.t("auto_hide")) {
                settings.autoHide.toggle()
            }
            Button(L10n.t("retry")) { Task { await model.refresh() } }
            Button(L10n.t("open_settings")) { onToggleSettings() }
            Divider()
            ForEach(WidgetPlacement.allCases) { place in
                Button(L10n.t(place.titleKey)) {
                    settings.clearCustomOrigin()
                    settings.placement = place
                }
            }
            Divider()
            Button(L10n.t("hide_panel")) { model.togglePanel() }
            Button(L10n.t("quit")) { NSApp.terminate(nil) }
        }
    }

    private var rowHeight: CGFloat {
        (Theme.panelWidth + (needsShortReset ? 14 : 0)) * scale
    }

    private var needsShortReset: Bool {
        model.visibleProviders.contains { id in
            ResetCopy.compact(reset: model.states[id]?.snapshot?.primary?.resetsAt) != nil
        }
    }

    private var tabAlignment: Alignment {
        switch chrome.hideEdge {
        case .right: .leading
        case .left: .trailing
        case .top: .bottom
        case .bottom: .top
        }
    }

    private var pill: some View {
        Group {
            if settings.layout == .horizontal {
                HStack(spacing: 0) {
                    rings
                }
                .padding(.horizontal, 9 * scale)
            } else {
                VStack(spacing: 0) {
                    rings
                }
                .padding(.vertical, 9 * scale)
            }
        }
        .frame(
            width: settings.layout == .horizontal ? nil : Theme.panelWidth * scale,
            height: settings.layout == .horizontal ? rowHeight : nil
        )
        .background(Theme.panelFill, in: Capsule())
        .overlay(
            Capsule()
                .stroke(Theme.hairline, lineWidth: 0.7)
        )
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.045), lineWidth: 0.7)
                .padding(1)
        )
        .padding(Theme.chromePad)
    }

    @ViewBuilder
    private var rings: some View {
        ForEach(Array(model.visibleProviders.enumerated()), id: \.element) { index, id in
            Button {
                onSelect(id, index)
            } label: {
                ProviderRingRow(
                    id: id,
                    state: model.states[id] ?? .idle,
                    selected: model.selected == id,
                    scale: scale,
                    showPercent: settings.showRingPercent,
                    showRemaining: settings.showRemaining
                )
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        if model.visibleProviders.isEmpty {
            emptyState
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "circle.dotted")
                .font(.system(size: 16, weight: .light))
                .foregroundStyle(Theme.muted)
            Text(L10n.t("no_data"))
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(Theme.muted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
        }
        .frame(width: 64 * scale, height: 72 * scale)
    }
}

private struct ProviderRingRow: View {
    let id: ProviderID
    let state: ProviderLoadState
    let selected: Bool
    var scale: CGFloat = 1
    var showPercent: Bool = true
    var showRemaining: Bool = false

    var body: some View {
        VStack(spacing: 6 * scale) {
            ZStack {
                ring
                BrandIcon(id: id, size: 17 * scale)
                    .opacity(isReady ? 1 : 0.38)
                if case .loading = state {
                    ProgressView()
                        .controlSize(.mini)
                        .scaleEffect(0.7)
                }
            }
            if showPercent {
                Text(percentLabel)
                    .font(.system(size: 12 * scale, weight: .semibold))
                    .monospacedDigit()
                    .tracking(-0.3)
                    .foregroundStyle(isReady ? Theme.text : Theme.muted)
            }
            if let compact = ResetCopy.compact(reset: state.snapshot?.primary?.resetsAt) {
                Text(compact)
                    .font(.system(size: 9.5 * scale, weight: .medium))
                    .monospacedDigit()
                    .foregroundStyle(Theme.muted)
                    .padding(.top, -2 * scale)
            }
        }
        .frame(
            width: Theme.panelWidth * scale,
            height: ((showPercent ? Theme.itemHeight : 58) + (ResetCopy.compact(reset: state.snapshot?.primary?.resetsAt) == nil ? 0 : 14)) * scale
        )
        .opacity(selected ? 1 : 0.88)
        .scaleEffect(selected ? 1.02 : 1)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(id.displayName), \(percentLabel)")
    }

    private var isReady: Bool {
        if case .ready = state { return true }
        return false
    }

    private var percent: Double {
        state.snapshot?.primaryPercent ?? 0
    }

    private var percentLabel: String {
        switch state {
        case .ready: String(format: "%.0f%%", showRemaining ? max(0, 100 - percent) : percent)
        case .signedOut, .missingKey: "—"
        case .error: "!"
        case .loading, .idle: "…"
        }
    }

    @ViewBuilder
    private var ring: some View {
        switch state {
        case .ready:
            UsageRing(percent: percent, tone: Theme.tone(percent), size: Theme.ringSize * scale, selected: selected)
        case .error:
            UsageRing(percent: 8, tone: Theme.critical, size: Theme.ringSize * scale, selected: selected)
        default:
            UsageRing(percent: 0, tone: Theme.muted, empty: true, size: Theme.ringSize * scale, selected: selected)
        }
    }
}
