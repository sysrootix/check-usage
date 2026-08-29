import AppKit
import SwiftUI

@main
struct CheckUsageApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var model = AppModel.shared
    @StateObject private var settings = SettingsStore.shared

    var body: some Scene {
        MenuBarExtra {
            Button(model.panelVisible && model.settings.widgetEnabled ? L10n.t("hide_panel") : L10n.t("show_panel")) {
                model.togglePanel()
            }
            Button(L10n.t("hotkey_toggle_detail")) {
                PanelController.shared.toggleLastDetail()
            }
            Button(L10n.t("retry")) {
                Task { await model.refresh() }
            }
            Divider()
            Button(L10n.t("open_settings")) {
                NotificationCenter.default.post(name: .checkUsageOpenSettings, object: nil)
            }
            Divider()
            Button(L10n.t("quit")) {
                NSApp.terminate(nil)
            }
        } label: {
            MenuBarLabel(model: model, showPercent: settings.showMenuBarPercent)
        }
        .menuBarExtraStyle(.menu)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        AppModel.shared.start()
        PanelController.shared.start()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if AppModel.shared.settings.widgetEnabled {
            AppModel.shared.panelVisible = true
            PanelController.shared.applyWidgetVisibility()
        } else {
            PanelController.shared.toggleLastDetail()
        }
        return false
    }
}

struct MenuBarLabel: View {
    @ObservedObject var model: AppModel
    var showPercent: Bool

    var body: some View {
        HStack(spacing: 4) {
            if let snapshot = model.worstReady {
                BrandIcon(id: snapshot.provider, size: 12)
            } else {
                Image(systemName: "circle.circle")
            }
            if showPercent, let snapshot = model.worstReady {
                Text(String(format: "%.0f%%", snapshot.primaryPercent))
                    .monospacedDigit()
            }
        }
        .accessibilityLabel(L10n.t("app_name"))
    }
}
