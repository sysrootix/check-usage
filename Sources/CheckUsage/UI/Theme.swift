import SwiftUI

enum Theme {
    static let panelFill = Color(red: 0.02, green: 0.02, blue: 0.022)
    static let popoverFill = Color(red: 0.048, green: 0.048, blue: 0.052)
    static let track = Color.white.opacity(0.08)
    static let text = Color.white
    static let muted = Color.white.opacity(0.42)
    static let hairline = Color.white.opacity(0.09)
    static let inset = Color.white.opacity(0.06)

    static let good = Color(red: 0.22, green: 0.84, blue: 0.40)
    static let mid = Color(red: 0.91, green: 0.88, blue: 0.22)
    static let warn = Color(red: 1.00, green: 0.50, blue: 0.16)
    static let critical = Color(red: 1.00, green: 0.36, blue: 0.20)

    static let chromePad: CGFloat = 14
    static let pointer: CGFloat = 7
    static let popoverRadius: CGFloat = 18
    static let pillRadius: CGFloat = 22

    static func toneColor(_ tone: UsageTone) -> Color {
        switch tone {
        case .good: good
        case .mid: mid
        case .warn: warn
        case .critical: critical
        }
    }

    static func tone(_ percent: Double) -> Color {
        switch UsageTone.from(percent: percent) {
        case .good: good
        case .mid: mid
        case .warn: warn
        case .critical: critical
        }
    }

    static let panelWidth: CGFloat = 78
    static let ringSize: CGFloat = 46
    static let itemHeight: CGFloat = 78
    static let popoverWidth: CGFloat = 292
    static let peekVisible: CGFloat = 16
    static let peekLength: CGFloat = 46
}
