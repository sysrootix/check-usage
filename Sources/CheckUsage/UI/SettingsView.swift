import SwiftUI

private enum SettingsSection: String, CaseIterable, Identifiable {
    case widget
    case providers
    case shortcuts
    case keys
    case general

    var id: String { rawValue }

    var titleKey: String {
        switch self {
        case .widget: "widget"
        case .providers: "providers"
        case .shortcuts: "shortcuts"
        case .keys: "api_keys"
        case .general: "appearance"
        }
    }

    var symbol: String {
        switch self {
        case .widget: "rectangle.portrait"
        case .providers: "circle.grid.2x2"
        case .shortcuts: "keyboard"
        case .keys: "key"
        case .general: "slider.horizontal.3"
        }
    }
}

struct SettingsView: View {
    @ObservedObject var settings: SettingsStore
    var onChange: () -> Void
    @State private var section: SettingsSection = .widget

    var body: some View {
        NavigationSplitView {
            List(SettingsSection.allCases, selection: $section) { item in
                Label(L10n.t(item.titleKey), systemImage: item.symbol)
                    .tag(item)
            }
            .listStyle(.sidebar)
            .frame(minWidth: 168)
        } detail: {
            Group {
                switch section {
                case .widget: widgetTab
                case .providers: providersTab
                case .shortcuts: shortcutsTab
                case .keys: keysTab
                case .general: generalTab
                }
            }
            .formStyle(.grouped)
        }
        .frame(minWidth: 640, minHeight: 620)
        .id(settings.language)
        .onChange(of: settings.language) { _, _ in onChange() }
        .onChange(of: settings.refreshSeconds) { _, _ in onChange() }
        .onChange(of: settings.showUnsigned) { _, _ in onChange() }
        .onChange(of: settings.widgetEnabled) { _, _ in onChange() }
        .onChange(of: settings.placement) { _, _ in onChange() }
        .onChange(of: settings.layout) { _, _ in onChange() }
        .onChange(of: settings.widgetScale) { _, _ in onChange() }
        .onChange(of: settings.edgeInset) { _, _ in onChange() }
        .onChange(of: settings.showRingPercent) { _, _ in onChange() }
        .onChange(of: settings.positionLocked) { _, _ in onChange() }
        .onChange(of: settings.snapToEdges) { _, _ in onChange() }
        .onChange(of: settings.widgetOpacity) { _, _ in onChange() }
        .onChange(of: settings.showRemaining) { _, _ in onChange() }
        .onChange(of: settings.usageAlerts) { _, _ in onChange() }
        .onChange(of: settings.autoHide) { _, _ in onChange() }
    }

    private var widgetTab: some View {
        Form {
            Section(L10n.t("widget")) {
                Toggle(L10n.t("widget_enabled"), isOn: $settings.widgetEnabled)
                if !settings.widgetEnabled {
                    Text(L10n.t("widget_hidden_hint"))
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                Toggle(L10n.t("lock_position"), isOn: $settings.positionLocked)
                Text(settings.positionLocked ? L10n.t("lock_help") : L10n.t("snap_help"))
                    .font(.callout)
                    .foregroundStyle(.secondary)
                if !settings.positionLocked {
                    Toggle(L10n.t("snap_edges"), isOn: $settings.snapToEdges)
                }
                Toggle(L10n.t("auto_hide"), isOn: $settings.autoHide)
                if settings.autoHide {
                    Text(L10n.t("auto_hide_help"))
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                VStack(alignment: .leading, spacing: 10) {
                    Text(L10n.t("widget_placement"))
                    PlacementPad(placement: $settings.placement, widgetEnabled: $settings.widgetEnabled)
                    Text(settings.widgetEnabled ? (settings.useCustomOrigin ? L10n.t("drag_hint") : L10n.t(settings.placement.titleKey)) : L10n.t("place_hide"))
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                Picker(L10n.t("widget_layout"), selection: $settings.layout) {
                    ForEach(WidgetLayout.allCases) { layout in
                        Text(L10n.t(layout.titleKey)).tag(layout)
                    }
                }
                Toggle(L10n.t("show_ring_percent"), isOn: $settings.showRingPercent)
                Toggle(L10n.t("show_remaining"), isOn: $settings.showRemaining)
                HStack {
                    Text(L10n.t("scale"))
                    Slider(value: $settings.widgetScale, in: 0.8...1.4, step: 0.1)
                    Text(String(format: "%.0f%%", settings.widgetScale * 100))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                        .frame(width: 48, alignment: .trailing)
                }
                HStack {
                    Text(L10n.t("opacity"))
                    Slider(value: $settings.widgetOpacity, in: 0.45...1, step: 0.05)
                    Text(String(format: "%.0f%%", settings.widgetOpacity * 100))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                        .frame(width: 48, alignment: .trailing)
                }
                HStack {
                    Text(L10n.t("edge_inset"))
                    Slider(value: $settings.edgeInset, in: 2...28, step: 2)
                    Text("\(Int(settings.edgeInset))")
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                        .frame(width: 28, alignment: .trailing)
                }
                Text(settings.positionLocked ? L10n.t("drag_locked") : L10n.t("drag_hint"))
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            Section(L10n.t("dismiss_mode")) {
                Toggle(L10n.t("dismiss_outside"), isOn: $settings.dismissOutside)
                Text(settings.dismissOutside ? L10n.t("dismiss_outside_help") : L10n.t("dismiss_sticky"))
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
    }

    private var providersTab: some View {
        Form {
            Section(L10n.t("providers")) {
                ForEach(ProviderID.allCases) { id in
                    Toggle(isOn: Binding(
                        get: { settings.isEnabled(id) },
                        set: { settings.setEnabled(id, $0); onChange() }
                    )) {
                        HStack(spacing: 8) {
                            BrandIcon(id: id, size: 14)
                                .foregroundStyle(.primary)
                            Text(id.displayName)
                        }
                    }
                }
            }
        }
        .padding()
    }

    private var shortcutsTab: some View {
        Form {
            Section(L10n.t("hotkeys")) {
                HotkeyRow(title: L10n.t("hotkey_toggle_widget"), combo: $settings.hotkeyWidget)
                HotkeyRow(title: L10n.t("hotkey_toggle_detail"), combo: $settings.hotkeyDetail)
                Text(L10n.t("hotkey_help"))
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
    }

    private var keysTab: some View {
        Form {
            Section {
                SecureField("OpenRouter", text: $settings.openRouterKey)
                SecureField("DeepSeek", text: $settings.deepSeekKey)
                SecureField("Z.ai / GLM", text: $settings.zaiKey)
            } footer: {
                Text(L10n.t("api_key_hint"))
            }
        }
        .padding()
        .onDisappear { settings.persistKeys(); onChange() }
    }

    private var generalTab: some View {
        Form {
            Section(L10n.t("language")) {
                Picker(L10n.t("language"), selection: $settings.language) {
                    ForEach(AppLanguage.allCases) { language in
                        Text(language.nativeName).tag(language)
                    }
                }
            }
            Section(L10n.t("appearance")) {
                Toggle(L10n.t("show_unsigned"), isOn: $settings.showUnsigned)
                Toggle(L10n.t("show_menubar_percent"), isOn: $settings.showMenuBarPercent)
                Toggle(L10n.t("show_pace"), isOn: $settings.showPace)
                if settings.showPace {
                    Text(L10n.t("show_pace_help"))
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                Toggle(L10n.t("usage_alerts"), isOn: $settings.usageAlerts)
                if settings.usageAlerts {
                    Text(L10n.t("usage_alerts_help"))
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                Toggle(L10n.t("launch_at_login"), isOn: Binding(
                    get: { settings.launchAtLogin },
                    set: { settings.launchAtLogin = $0 }
                ))
                HStack {
                    Text(L10n.t("refresh_every"))
                    Slider(value: $settings.refreshSeconds, in: 30...300, step: 15)
                    Text("\(Int(settings.refreshSeconds)) \(L10n.t("seconds"))")
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
            }
            Section(L10n.t("about")) {
                LabeledContent("CheckUsage", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                Text(L10n.t("privacy_note"))
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            Section(L10n.t("settings_file")) {
                Text(settings.settingsFilePath)
                    .font(.system(size: 11, design: .monospaced))
                    .textSelection(.enabled)
                    .foregroundStyle(.secondary)
                Text(L10n.t("settings_file_help"))
                    .font(.callout)
                    .foregroundStyle(.secondary)
                Button(L10n.t("reveal_settings")) {
                    settings.revealSettingsFile()
                }
            }
        }
        .padding()
    }
}

private struct PlacementPad: View {
    @Binding var placement: WidgetPlacement
    @Binding var widgetEnabled: Bool
    @ObservedObject private var store = SettingsStore.shared

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 6) {
                cell(.topLeading, "arrow.up.left")
                cell(.topCenter, "arrow.up")
                cell(.topTrailing, "arrow.up.right")
            }
            HStack(spacing: 6) {
                cell(.leadingCenter, "arrow.left")
                hideCell
                cell(.trailingCenter, "arrow.right")
            }
            HStack(spacing: 6) {
                cell(.bottomLeading, "arrow.down.left")
                cell(.bottomCenter, "arrow.down")
                cell(.bottomTrailing, "arrow.down.right")
            }
        }
        .frame(maxWidth: 220)
    }

    private func cell(_ value: WidgetPlacement, _ symbol: String) -> some View {
        let selected = widgetEnabled && placement == value
        return Button {
            widgetEnabled = true
            store.clearCustomOrigin()
            placement = value
        } label: {
            Image(systemName: symbol)
                .font(.system(size: 11, weight: .semibold))
                .frame(maxWidth: .infinity, minHeight: 28)
                .background(selected ? Color.accentColor : Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                .foregroundStyle(selected ? Color.white : Color.primary)
        }
        .buttonStyle(.plain)
        .help(L10n.t(value.titleKey))
        .accessibilityLabel(L10n.t(value.titleKey))
    }

    private var hideCell: some View {
        Button {
            widgetEnabled = false
        } label: {
            Image(systemName: "eye.slash")
                .font(.system(size: 11, weight: .semibold))
                .frame(maxWidth: .infinity, minHeight: 28)
                .background(!widgetEnabled ? Color.accentColor : Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                .foregroundStyle(!widgetEnabled ? Color.white : Color.primary)
        }
        .buttonStyle(.plain)
        .help(L10n.t("place_hide"))
        .accessibilityLabel(L10n.t("place_hide"))
    }
}

private struct HotkeyRow: View {
    let title: String
    @Binding var combo: KeyCombo?
    @State private var recording = false

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Button(recording ? L10n.t("hotkey_recording") : (combo?.display ?? L10n.t("hotkey_press"))) {
                recording = true
            }
            .buttonStyle(.bordered)
            if combo != nil, !recording {
                Button(L10n.t("hotkey_clear")) { combo = nil }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
            }
        }
        .background(HotkeyCatcher(recording: $recording, combo: $combo))
    }
}

private struct HotkeyCatcher: NSViewRepresentable {
    @Binding var recording: Bool
    @Binding var combo: KeyCombo?

    func makeNSView(context: Context) -> CatcherView {
        CatcherView()
    }

    func updateNSView(_ nsView: CatcherView, context: Context) {
        nsView.recording = recording
        nsView.onCombo = { value in
            combo = value
            recording = false
        }
        nsView.onCancel = {
            recording = false
        }
    }
}

final class CatcherView: NSView {
    var recording = false
    var onCombo: ((KeyCombo) -> Void)?
    var onCancel: (() -> Void)?
    private var monitor: Any?

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if monitor == nil {
            monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .leftMouseDown]) { [weak self] event in
                guard let self, self.recording else { return event }
                if event.type == .leftMouseDown {
                    self.onCancel?()
                    return event
                }
                if event.keyCode == 53 {
                    self.onCancel?()
                    return nil
                }
                if let combo = KeyCombo.from(event: event) {
                    self.onCombo?(combo)
                    return nil
                }
                return event
            }
        }
    }
}
