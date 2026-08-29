import Combine
import Foundation
import SwiftUI

@MainActor
final class AppModel: ObservableObject {
    static let shared = AppModel()

    @Published var states: [ProviderID: ProviderLoadState] = [:]
    @Published var selected: ProviderID?
    @Published var lastSelected: ProviderID?
    @Published var panelVisible = true
    @Published var lastRefresh: Date?
    @Published var refreshing = false

    let settings = SettingsStore.shared
    private var timer: Timer?

    var visibleProviders: [ProviderID] {
        ProviderID.allCases.filter { id in
            guard settings.isEnabled(id) else { return false }
            if settings.showUnsigned { return true }
            if lastRefresh == nil {
                switch states[id] {
                case .signedOut, .missingKey, .error: return false
                default: return true
                }
            }
            return states[id]?.snapshot != nil
        }
    }

    var worstReady: QuotaSnapshot? {
        visibleProviders
            .compactMap { states[$0]?.snapshot }
            .max(by: { $0.primaryPercent < $1.primaryPercent })
    }

    func start() {
        for id in ProviderID.allCases {
            if states[id] == nil { states[id] = .idle }
        }
        Task { await refresh() }
        restartTimer()
    }

    func restartTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: settings.refreshSeconds, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.refresh()
            }
        }
        RunLoop.main.add(timer!, forMode: .common)
    }

    func refresh() async {
        refreshing = true
        settings.persistKeys()
        var service = UsageService()
        service.openRouterKey = settings.openRouterKey
        service.deepSeekKey = settings.deepSeekKey
        service.zaiKey = settings.zaiKey
        let snapshot = service
        let enabledIDs = ProviderID.allCases.filter { settings.isEnabled($0) }
        await withTaskGroup(of: (ProviderID, ProviderLoadState).self) { group in
            for id in enabledIDs {
                states[id] = .loading
                group.addTask {
                    let result = await snapshot.fetch(id)
                    return (id, result)
                }
            }
            for await (id, state) in group {
                states[id] = state
            }
        }
        lastRefresh = Date()
        refreshing = false
        for state in states.values {
            if let snapshot = state.snapshot {
                settings.noteUsage(snapshot)
            }
        }
        notifyThresholds()
        NotificationCenter.default.post(name: .checkUsageDidRefresh, object: nil)
    }

    private func notifyThresholds() {
        guard settings.usageAlerts else { return }
        for id in visibleProviders {
            guard let snapshot = states[id]?.snapshot else { continue }
            let percent = snapshot.primaryPercent
            let window = snapshot.primary
            let cycleEnd = window?.resetsAt ?? snapshot.cycleEnd
            settings.clearAlerts(ifPercentBelow: percent, provider: id, cycleEnd: cycleEnd)
            if percent >= 90, !settings.wasAlerted(id, level: 90, cycleEnd: cycleEnd) {
                settings.markAlerted(id, level: 90, cycleEnd: cycleEnd)
                UsageAlerts.post(provider: id, window: window?.title, percent: percent, reset: cycleEnd)
            } else if percent >= 70, !settings.wasAlerted(id, level: 70, cycleEnd: cycleEnd) {
                settings.markAlerted(id, level: 70, cycleEnd: cycleEnd)
                UsageAlerts.post(provider: id, window: window?.title, percent: percent, reset: cycleEnd)
            }
        }
    }

    func select(_ id: ProviderID?) {
        selected = id
        if let id { lastSelected = id }
        NotificationCenter.default.post(name: .checkUsageSelectionChanged, object: id)
    }

    func togglePanel() {
        if !settings.widgetEnabled {
            settings.widgetEnabled = true
            panelVisible = true
        } else {
            panelVisible.toggle()
        }
        NotificationCenter.default.post(name: .checkUsagePanelVisibility, object: panelVisible && settings.widgetEnabled)
    }

    func showPanel() {
        settings.widgetEnabled = true
        panelVisible = true
        NotificationCenter.default.post(name: .checkUsagePanelVisibility, object: true)
    }
}

extension Notification.Name {
    static let checkUsageDidRefresh = Notification.Name("checkUsageDidRefresh")
    static let checkUsageSelectionChanged = Notification.Name("checkUsageSelectionChanged")
    static let checkUsagePanelVisibility = Notification.Name("checkUsagePanelVisibility")
    static let checkUsageOpenSettings = Notification.Name("checkUsageOpenSettings")
    static let checkUsageLayoutChanged = Notification.Name("checkUsageLayoutChanged")
    static let checkUsageHotkeysChanged = Notification.Name("checkUsageHotkeysChanged")
}
