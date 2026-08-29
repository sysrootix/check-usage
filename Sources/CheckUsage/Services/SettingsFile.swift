import Foundation

struct SettingsSnapshot: Codable, Equatable, Sendable {
    var version: Int = 1
    var language: String = AppLanguage.system.rawValue
    var refreshSeconds: Double = 60
    var showUnsigned: Bool = false
    var showMenuBarPercent: Bool = true
    var widgetEnabled: Bool = true
    var placement: String = WidgetPlacement.topTrailing.rawValue
    var layout: String = WidgetLayout.vertical.rawValue
    var dismissOutside: Bool = true
    var widgetScale: Double = 1
    var edgeInset: Double = 6
    var showRingPercent: Bool = true
    var positionLocked: Bool = true
    var snapToEdges: Bool = true
    var useCustomOrigin: Bool = false
    var customX: Double = 0
    var customY: Double = 0
    var widgetOpacity: Double = 1
    var showRemaining: Bool = false
    var usageAlerts: Bool = false
    var launchAtLogin: Bool = false
    var enabled: [String: Bool] = [:]
    var hotkeyWidget: KeyCombo? = .defaultWidget
    var hotkeyDetail: KeyCombo? = .defaultDetail
    var alerted: [String: Bool] = [:]
    var watches: [String: CycleWatch] = [:]
    var showPace: Bool = true
    var autoHide: Bool = false

    enum CodingKeys: String, CodingKey {
        case version, language, refreshSeconds, showUnsigned, showMenuBarPercent
        case widgetEnabled, placement, layout, dismissOutside, widgetScale, edgeInset
        case showRingPercent, positionLocked, snapToEdges, useCustomOrigin, customX, customY
        case widgetOpacity, showRemaining, usageAlerts, launchAtLogin, enabled
        case hotkeyWidget, hotkeyDetail, alerted, watches, showPace, autoHide
    }
}

extension SettingsSnapshot {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let blank = SettingsSnapshot()
        version = try c.decodeIfPresent(Int.self, forKey: .version) ?? blank.version
        language = try c.decodeIfPresent(String.self, forKey: .language) ?? blank.language
        refreshSeconds = try c.decodeIfPresent(Double.self, forKey: .refreshSeconds) ?? blank.refreshSeconds
        showUnsigned = try c.decodeIfPresent(Bool.self, forKey: .showUnsigned) ?? blank.showUnsigned
        showMenuBarPercent = try c.decodeIfPresent(Bool.self, forKey: .showMenuBarPercent) ?? blank.showMenuBarPercent
        widgetEnabled = try c.decodeIfPresent(Bool.self, forKey: .widgetEnabled) ?? blank.widgetEnabled
        placement = try c.decodeIfPresent(String.self, forKey: .placement) ?? blank.placement
        layout = try c.decodeIfPresent(String.self, forKey: .layout) ?? blank.layout
        dismissOutside = try c.decodeIfPresent(Bool.self, forKey: .dismissOutside) ?? blank.dismissOutside
        widgetScale = try c.decodeIfPresent(Double.self, forKey: .widgetScale) ?? blank.widgetScale
        edgeInset = try c.decodeIfPresent(Double.self, forKey: .edgeInset) ?? blank.edgeInset
        showRingPercent = try c.decodeIfPresent(Bool.self, forKey: .showRingPercent) ?? blank.showRingPercent
        positionLocked = try c.decodeIfPresent(Bool.self, forKey: .positionLocked) ?? blank.positionLocked
        snapToEdges = try c.decodeIfPresent(Bool.self, forKey: .snapToEdges) ?? blank.snapToEdges
        useCustomOrigin = try c.decodeIfPresent(Bool.self, forKey: .useCustomOrigin) ?? blank.useCustomOrigin
        customX = try c.decodeIfPresent(Double.self, forKey: .customX) ?? blank.customX
        customY = try c.decodeIfPresent(Double.self, forKey: .customY) ?? blank.customY
        widgetOpacity = try c.decodeIfPresent(Double.self, forKey: .widgetOpacity) ?? blank.widgetOpacity
        showRemaining = try c.decodeIfPresent(Bool.self, forKey: .showRemaining) ?? blank.showRemaining
        usageAlerts = try c.decodeIfPresent(Bool.self, forKey: .usageAlerts) ?? blank.usageAlerts
        launchAtLogin = try c.decodeIfPresent(Bool.self, forKey: .launchAtLogin) ?? blank.launchAtLogin
        enabled = try c.decodeIfPresent([String: Bool].self, forKey: .enabled) ?? blank.enabled
        hotkeyWidget = try c.decodeIfPresent(KeyCombo.self, forKey: .hotkeyWidget) ?? blank.hotkeyWidget
        hotkeyDetail = try c.decodeIfPresent(KeyCombo.self, forKey: .hotkeyDetail) ?? blank.hotkeyDetail
        alerted = try c.decodeIfPresent([String: Bool].self, forKey: .alerted) ?? blank.alerted
        watches = try c.decodeIfPresent([String: CycleWatch].self, forKey: .watches) ?? blank.watches
        showPace = try c.decodeIfPresent(Bool.self, forKey: .showPace) ?? blank.showPace
        autoHide = try c.decodeIfPresent(Bool.self, forKey: .autoHide) ?? blank.autoHide
    }
}

enum SettingsFile {
    nonisolated(unsafe) static var overrideURL: URL?

    static var directory: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("CheckUsage", isDirectory: true)
    }

    static var url: URL {
        overrideURL ?? directory.appendingPathComponent("settings.json")
    }

    static func load() -> SettingsSnapshot? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(SettingsSnapshot.self, from: data)
    }

    static func save(_ snapshot: SettingsSnapshot) throws {
        let folder = url.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(snapshot).write(to: url, options: .atomic)
    }
}
