import AppKit
import Carbon

struct KeyCombo: Codable, Equatable, Sendable {
    var keyCode: UInt32
    var carbonModifiers: UInt32

    var display: String {
        var parts = ""
        if carbonModifiers & UInt32(controlKey) != 0 { parts += "⌃" }
        if carbonModifiers & UInt32(optionKey) != 0 { parts += "⌥" }
        if carbonModifiers & UInt32(shiftKey) != 0 { parts += "⇧" }
        if carbonModifiers & UInt32(cmdKey) != 0 { parts += "⌘" }
        parts += Self.name(for: keyCode)
        return parts
    }

    static func from(event: NSEvent) -> KeyCombo? {
        let flags = event.modifierFlags.intersection([.command, .option, .control, .shift])
        guard !flags.isEmpty else { return nil }
        var carbon: UInt32 = 0
        if flags.contains(.control) { carbon |= UInt32(controlKey) }
        if flags.contains(.option) { carbon |= UInt32(optionKey) }
        if flags.contains(.shift) { carbon |= UInt32(shiftKey) }
        if flags.contains(.command) { carbon |= UInt32(cmdKey) }
        return KeyCombo(keyCode: UInt32(event.keyCode), carbonModifiers: carbon)
    }

    static var defaultWidget: KeyCombo {
        KeyCombo(keyCode: 32, carbonModifiers: UInt32(cmdKey | optionKey)) // ⌥⌘U
    }

    static var defaultDetail: KeyCombo {
        KeyCombo(keyCode: 37, carbonModifiers: UInt32(cmdKey | optionKey)) // ⌥⌘L
    }

    private static func name(for keyCode: UInt32) -> String {
        let map: [UInt32: String] = [
            0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X", 8: "C", 9: "V",
            11: "B", 12: "Q", 13: "W", 14: "E", 15: "R", 16: "Y", 17: "T", 31: "O", 32: "U",
            34: "I", 35: "P", 37: "L", 38: "J", 40: "K", 45: "N", 46: "M", 18: "1", 19: "2",
            20: "3", 21: "4", 22: "6", 23: "5", 26: "7", 28: "8", 25: "9", 29: "0",
            36: "⏎", 48: "⇥", 49: "Space", 51: "⌫", 53: "⎋",
        ]
        return map[keyCode] ?? "Key\(keyCode)"
    }
}

final class HotKeyCenter: @unchecked Sendable {
    static let shared = HotKeyCenter()

    var onToggleWidget: (@MainActor () -> Void)?
    var onToggleDetail: (@MainActor () -> Void)?

    private var widgetRef: EventHotKeyRef?
    private var detailRef: EventHotKeyRef?
    private var handler: EventHandlerRef?

    func register(widget: KeyCombo?, detail: KeyCombo?) {
        unregister()
        installHandlerIfNeeded()
        if let widget {
            var ref: EventHotKeyRef?
            RegisterEventHotKey(widget.keyCode, widget.carbonModifiers, EventHotKeyID(signature: 0x43485531, id: 1), GetApplicationEventTarget(), 0, &ref)
            widgetRef = ref
        }
        if let detail {
            var ref: EventHotKeyRef?
            RegisterEventHotKey(detail.keyCode, detail.carbonModifiers, EventHotKeyID(signature: 0x43485532, id: 2), GetApplicationEventTarget(), 0, &ref)
            detailRef = ref
        }
    }

    func unregister() {
        if let widgetRef { UnregisterEventHotKey(widgetRef) }
        if let detailRef { UnregisterEventHotKey(detailRef) }
        widgetRef = nil
        detailRef = nil
    }

    fileprivate func handle(id: UInt32) {
        DispatchQueue.main.async {
            switch id {
            case 1: Task { @MainActor in self.onToggleWidget?() }
            case 2: Task { @MainActor in self.onToggleDetail?() }
            default: break
            }
        }
    }

    private func installHandlerIfNeeded() {
        guard handler == nil else { return }
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let status = InstallEventHandler(GetApplicationEventTarget(), { _, event, _ in
            var hotKeyID = EventHotKeyID()
            GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID), nil, MemoryLayout<EventHotKeyID>.size, nil, &hotKeyID)
            HotKeyCenter.shared.handle(id: hotKeyID.id)
            return noErr
        }, 1, &eventType, nil, &handler)
        if status != noErr {
            handler = nil
        }
    }
}
