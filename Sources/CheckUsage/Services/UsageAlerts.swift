import UserNotifications

enum UsageAlerts {
    static func request() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    static func post(provider: ProviderID, window: String?, percent: Double, reset: Date?) {
        let content = UNMutableNotificationContent()
        if let window, !window.isEmpty {
            content.title = L10n.format("alert_title_window", provider.displayName, window)
        } else {
            content.title = L10n.format("alert_title", provider.displayName)
        }
        let used = String(format: "%.0f%%", percent)
        if let reset {
            content.body = L10n.format("alert_body_reset", used, ResetCopy.format(reset: reset))
        } else {
            content.body = L10n.format("alert_body", used)
        }
        content.sound = .default
        let stamp = reset.map { String(Int($0.timeIntervalSince1970 / 3600)) } ?? "0"
        let request = UNNotificationRequest(
            identifier: "checkusage.\(provider.rawValue).\(Int(percent)).\(stamp)",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }
}
