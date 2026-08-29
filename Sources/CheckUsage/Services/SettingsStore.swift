import AppKit
import Foundation
import ServiceManagement

@MainActor
final class SettingsStore: ObservableObject {
    static let shared = SettingsStore()

    @Published var language: AppLanguage {
        didSet {
            L10n.language = language
            persist()
        }
    }

    @Published var refreshSeconds: Double { didSet { persist() } }
    @Published var showUnsigned: Bool { didSet { persist() } }
    @Published var showMenuBarPercent: Bool { didSet { persist() } }

    @Published var widgetEnabled: Bool {
        didSet {
            persist()
            NotificationCenter.default.post(name: .checkUsageLayoutChanged, object: nil)
        }
    }

    @Published var placement: WidgetPlacement {
        didSet {
            persist()
            NotificationCenter.default.post(name: .checkUsageLayoutChanged, object: nil)
        }
    }

    @Published var layout: WidgetLayout {
        didSet {
            persist()
            NotificationCenter.default.post(name: .checkUsageLayoutChanged, object: nil)
        }
    }

    @Published var dismissOutside: Bool { didSet { persist() } }

    @Published var widgetScale: Double {
        didSet {
            persist()
            NotificationCenter.default.post(name: .checkUsageLayoutChanged, object: nil)
        }
    }

    @Published var edgeInset: Double {
        didSet {
            persist()
            NotificationCenter.default.post(name: .checkUsageLayoutChanged, object: nil)
        }
    }

    @Published var showRingPercent: Bool {
        didSet {
            persist()
            NotificationCenter.default.post(name: .checkUsageLayoutChanged, object: nil)
        }
    }

    @Published var positionLocked: Bool {
        didSet {
            persist()
            NotificationCenter.default.post(name: .checkUsageLayoutChanged, object: nil)
        }
    }

    @Published var snapToEdges: Bool { didSet { persist() } }
    @Published var useCustomOrigin: Bool { didSet { persist() } }
    @Published var customX: Double { didSet { persist() } }
    @Published var customY: Double { didSet { persist() } }

    @Published var widgetOpacity: Double {
        didSet {
            persist()
            NotificationCenter.default.post(name: .checkUsageLayoutChanged, object: nil)
        }
    }

    @Published var showRemaining: Bool {
        didSet {
            persist()
            NotificationCenter.default.post(name: .checkUsageLayoutChanged, object: nil)
        }
    }

    @Published var usageAlerts: Bool {
        didSet {
            persist()
            if usageAlerts { UsageAlerts.request() }
        }
    }

    @Published var showPace: Bool { didSet { persist() } }

    @Published var autoHide: Bool {
        didSet {
            persist()
            NotificationCenter.default.post(name: .checkUsageLayoutChanged, object: nil)
        }
    }

    @Published var hotkeyWidget: KeyCombo? {
        didSet {
            persist()
            NotificationCenter.default.post(name: .checkUsageHotkeysChanged, object: nil)
        }
    }

    @Published var hotkeyDetail: KeyCombo? {
        didSet {
            persist()
            NotificationCenter.default.post(name: .checkUsageHotkeysChanged, object: nil)
        }
    }

    @Published var enabled: [ProviderID: Bool]
    @Published var openRouterKey: String
    @Published var deepSeekKey: String
    @Published var zaiKey: String

    private var ready = false
    private var saveWork: DispatchWorkItem?
    private var alerted: [String: Bool]
    private var watches: [String: CycleWatch]
    private let defaults = UserDefaults.standard

    private init() {
        let snapshot = SettingsFile.load() ?? Self.migrateFromDefaults()
        language = AppLanguage(rawValue: snapshot.language) ?? .system
        refreshSeconds = snapshot.refreshSeconds
        showUnsigned = snapshot.showUnsigned
        showMenuBarPercent = snapshot.showMenuBarPercent
        widgetEnabled = snapshot.widgetEnabled
        placement = WidgetPlacement(rawValue: snapshot.placement) ?? .topTrailing
        layout = WidgetLayout(rawValue: snapshot.layout) ?? .vertical
        dismissOutside = snapshot.dismissOutside
        widgetScale = snapshot.widgetScale
        edgeInset = snapshot.edgeInset
        showRingPercent = snapshot.showRingPercent
        positionLocked = snapshot.positionLocked
        snapToEdges = snapshot.snapToEdges
        useCustomOrigin = snapshot.useCustomOrigin
        customX = snapshot.customX
        customY = snapshot.customY
        widgetOpacity = snapshot.widgetOpacity
        showRemaining = snapshot.showRemaining
        usageAlerts = snapshot.usageAlerts
        showPace = snapshot.showPace
        autoHide = snapshot.autoHide
        hotkeyWidget = snapshot.hotkeyWidget ?? .defaultWidget
        hotkeyDetail = snapshot.hotkeyDetail ?? .defaultDetail
        alerted = snapshot.alerted
        watches = snapshot.watches
        var map: [ProviderID: Bool] = [:]
        for id in ProviderID.allCases {
            map[id] = snapshot.enabled[id.rawValue] ?? id.defaultEnabled
        }
        enabled = map
        openRouterKey = SecretStore.appSecret(account: "openrouter") ?? ProcessInfo.processInfo.environment["OPENROUTER_API_KEY"] ?? ""
        deepSeekKey = SecretStore.appSecret(account: "deepseek") ?? ProcessInfo.processInfo.environment["DEEPSEEK_API_KEY"] ?? ""
        zaiKey = SecretStore.appSecret(account: "zai") ?? ProcessInfo.processInfo.environment["ZAI_API_KEY"] ?? ""
        L10n.language = language
        ready = true
        if SettingsFile.load() == nil {
            writeNow()
        }
        if snapshot.launchAtLogin != (SMAppService.mainApp.status == .enabled) {
            launchAtLogin = snapshot.launchAtLogin
        }
    }

    func isEnabled(_ id: ProviderID) -> Bool {
        enabled[id] ?? true
    }

    func setEnabled(_ id: ProviderID, _ value: Bool) {
        enabled[id] = value
        persist()
    }

    func rememberCustomOrigin(_ point: CGPoint) {
        useCustomOrigin = true
        customX = point.x
        customY = point.y
    }

    func clearCustomOrigin() {
        useCustomOrigin = false
    }

    func wasAlerted(_ provider: ProviderID, level: Int, cycleEnd: Date?) -> Bool {
        alerted[alertKey(provider, level: level, cycleEnd: cycleEnd)] == true
    }

    func markAlerted(_ provider: ProviderID, level: Int, cycleEnd: Date?) {
        alerted[alertKey(provider, level: level, cycleEnd: cycleEnd)] = true
        persist()
    }

    func clearAlerts(ifPercentBelow threshold: Double, provider: ProviderID, cycleEnd: Date?) {
        if threshold < 65 {
            alerted.removeValue(forKey: alertKey(provider, level: 70, cycleEnd: cycleEnd))
            alerted.removeValue(forKey: alertKey(provider, level: 90, cycleEnd: cycleEnd))
            persist()
        } else if threshold < 85 {
            alerted.removeValue(forKey: alertKey(provider, level: 90, cycleEnd: cycleEnd))
            persist()
        }
    }

    func persistKeys() {
        SecretStore.setAppSecret(account: "openrouter", secret: openRouterKey.trimmingCharacters(in: .whitespacesAndNewlines))
        SecretStore.setAppSecret(account: "deepseek", secret: deepSeekKey.trimmingCharacters(in: .whitespacesAndNewlines))
        SecretStore.setAppSecret(account: "zai", secret: zaiKey.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    var settingsFilePath: String {
        SettingsFile.url.path
    }

    func revealSettingsFile() {
        let folder = SettingsFile.url.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        if !FileManager.default.fileExists(atPath: SettingsFile.url.path) {
            writeNow()
        }
        NSWorkspace.shared.activateFileViewerSelecting([SettingsFile.url])
    }

    var launchAtLogin: Bool {
        get { SMAppService.mainApp.status == .enabled }
        set {
            do {
                if newValue { try SMAppService.mainApp.register() }
                else { try SMAppService.mainApp.unregister() }
            } catch {}
            persist()
            objectWillChange.send()
        }
    }

    private func alertKey(_ provider: ProviderID, level: Int, cycleEnd: Date?) -> String {
        let stamp = cycleEnd.map { String(Int($0.timeIntervalSince1970 / 3600)) } ?? "0"
        return "\(provider.rawValue).\(level).\(stamp)"
    }

    private func persist() {
        guard ready else { return }
        saveWork?.cancel()
        let work = DispatchWorkItem { [weak self] in
            Task { @MainActor in self?.writeNow() }
        }
        saveWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15, execute: work)
    }

    private func writeNow() {
        try? SettingsFile.save(snapshot())
    }

    func snapshot() -> SettingsSnapshot {
        var enabledRaw: [String: Bool] = [:]
        for (id, value) in enabled {
            enabledRaw[id.rawValue] = value
        }
        return SettingsSnapshot(
            version: 1,
            language: language.rawValue,
            refreshSeconds: refreshSeconds,
            showUnsigned: showUnsigned,
            showMenuBarPercent: showMenuBarPercent,
            widgetEnabled: widgetEnabled,
            placement: placement.rawValue,
            layout: layout.rawValue,
            dismissOutside: dismissOutside,
            widgetScale: widgetScale,
            edgeInset: edgeInset,
            showRingPercent: showRingPercent,
            positionLocked: positionLocked,
            snapToEdges: snapToEdges,
            useCustomOrigin: useCustomOrigin,
            customX: customX,
            customY: customY,
            widgetOpacity: widgetOpacity,
            showRemaining: showRemaining,
            usageAlerts: usageAlerts,
            launchAtLogin: SMAppService.mainApp.status == .enabled,
            enabled: enabledRaw,
            hotkeyWidget: hotkeyWidget,
            hotkeyDetail: hotkeyDetail,
            alerted: alerted,
            watches: watches,
            showPace: showPace,
            autoHide: autoHide
        )
    }

    func noteUsage(_ snapshot: QuotaSnapshot) {
        guard let window = snapshot.forecastWindow else { return }
        let end = window.resetsAt ?? snapshot.cycleEnd
        guard let end else { return }
        let key = "\(snapshot.provider.rawValue).\(window.id)"
        let endTs = end.timeIntervalSince1970
        if let existing = watches[key], abs(existing.cycleEnd - endTs) < 2 * 86400 {
            return
        }
        watches[key] = CycleWatch(
            cycleEnd: endTs,
            firstAt: Date().timeIntervalSince1970,
            firstPercent: window.clampedPercent
        )
        persist()
    }

    func watch(for snapshot: QuotaSnapshot) -> CycleWatch? {
        guard let window = snapshot.forecastWindow else { return nil }
        return watches["\(snapshot.provider.rawValue).\(window.id)"]
    }

    private static func migrateFromDefaults() -> SettingsSnapshot {
        let defaults = UserDefaults.standard
        var enabled: [String: Bool] = [:]
        for id in ProviderID.allCases {
            if defaults.object(forKey: "enabled.\(id.rawValue)") != nil {
                enabled[id.rawValue] = defaults.bool(forKey: "enabled.\(id.rawValue)")
            }
        }
        var alerted: [String: Bool] = [:]
        for id in ProviderID.allCases {
            for level in [70, 90] {
                let key = "alerted.\(id.rawValue).\(level)"
                if defaults.bool(forKey: key) {
                    alerted["\(id.rawValue).\(level)"] = true
                }
            }
        }
        return SettingsSnapshot(
            language: defaults.string(forKey: "language") ?? AppLanguage.system.rawValue,
            refreshSeconds: (defaults.object(forKey: "refreshSeconds") as? Double) ?? 60,
            showUnsigned: defaults.object(forKey: "showUnsigned") as? Bool ?? false,
            showMenuBarPercent: defaults.object(forKey: "showMenuBarPercent") as? Bool ?? true,
            widgetEnabled: defaults.object(forKey: "widgetEnabled") as? Bool ?? true,
            placement: defaults.string(forKey: "placement") ?? WidgetPlacement.topTrailing.rawValue,
            layout: defaults.string(forKey: "layout") ?? WidgetLayout.vertical.rawValue,
            dismissOutside: defaults.object(forKey: "dismissOutside") as? Bool ?? true,
            widgetScale: defaults.object(forKey: "widgetScale") as? Double ?? 1,
            edgeInset: defaults.object(forKey: "edgeInset") as? Double ?? 6,
            showRingPercent: defaults.object(forKey: "showRingPercent") as? Bool ?? true,
            positionLocked: defaults.object(forKey: "positionLocked") as? Bool ?? true,
            snapToEdges: defaults.object(forKey: "snapToEdges") as? Bool ?? true,
            useCustomOrigin: defaults.object(forKey: "useCustomOrigin") as? Bool ?? false,
            customX: defaults.object(forKey: "customX") as? Double ?? 0,
            customY: defaults.object(forKey: "customY") as? Double ?? 0,
            widgetOpacity: defaults.object(forKey: "widgetOpacity") as? Double ?? 1,
            showRemaining: defaults.object(forKey: "showRemaining") as? Bool ?? false,
            usageAlerts: defaults.object(forKey: "usageAlerts") as? Bool ?? false,
            launchAtLogin: SMAppService.mainApp.status == .enabled,
            enabled: enabled,
            hotkeyWidget: loadCombo(key: "hotkeyWidget") ?? .defaultWidget,
            hotkeyDetail: loadCombo(key: "hotkeyDetail") ?? .defaultDetail,
            alerted: alerted
        )
    }

    private static func loadCombo(key: String) -> KeyCombo? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(KeyCombo.self, from: data)
    }
}
