import Foundation

enum ProviderID: String, CaseIterable, Identifiable, Codable, Sendable {
    case claude
    case codex
    case cursor
    case copilot
    case gemini
    case grok
    case antigravity
    case opencode
    case openrouter
    case deepseek
    case zai

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .claude: "Claude"
        case .codex: "Codex"
        case .cursor: "Cursor"
        case .copilot: "Copilot"
        case .gemini: "Gemini"
        case .grok: "Grok"
        case .antigravity: "Antigravity"
        case .opencode: "OpenCode"
        case .openrouter: "OpenRouter"
        case .deepseek: "DeepSeek"
        case .zai: "Z.ai"
        }
    }

    var needsAPIKey: Bool {
        switch self {
        case .openrouter, .deepseek, .zai: true
        default: false
        }
    }

    var defaultEnabled: Bool { true }

    var dashboardURL: URL? {
        switch self {
        case .claude: URL(string: "https://claude.ai/settings/usage")
        case .cursor: URL(string: "https://cursor.com/dashboard?tab=usage")
        case .codex: URL(string: "https://chatgpt.com")
        case .copilot: URL(string: "https://github.com/settings/copilot")
        case .gemini, .antigravity: URL(string: "https://one.google.com/ai")
        case .grok: URL(string: "https://grok.x.ai")
        case .openrouter: URL(string: "https://openrouter.ai/settings/credits")
        case .deepseek: URL(string: "https://platform.deepseek.com/usage")
        case .zai: URL(string: "https://open.bigmodel.cn/usercenter/quota")
        case .opencode: nil
        }
    }
}

struct QuotaWindow: Identifiable, Sendable, Equatable {
    let id: String
    let title: String
    let usedPercent: Double
    let resetsAt: Date?
    let footnote: String?
    var hint: String? = nil

    var clampedPercent: Double {
        min(100, max(0, usedPercent))
    }
}

enum ProviderLoadState: Sendable, Equatable {
    case idle
    case loading
    case ready(QuotaSnapshot)
    case signedOut
    case missingKey
    case error(String)

    var snapshot: QuotaSnapshot? {
        if case .ready(let snapshot) = self { return snapshot }
        return nil
    }
}

struct QuotaSnapshot: Sendable, Equatable {
    let provider: ProviderID
    let planName: String?
    let windows: [QuotaWindow]
    let fetchedAt: Date
    var cycleStart: Date? = nil
    var cycleEnd: Date? = nil
    var subscribedAt: Date? = nil

    var primary: QuotaWindow? {
        windows.first
    }

    var primaryPercent: Double {
        primary?.clampedPercent ?? 0
    }

    var forecastWindow: QuotaWindow? {
        let named = ["total", "plan", "monthly", "credits", "premium"]
        if let match = windows.first(where: { window in
            named.contains(window.id) || window.id.hasPrefix("weekly_all")
        }) {
            return match
        }
        if let longest = windows.max(by: { ($0.resetsAt ?? .distantPast) < ($1.resetsAt ?? .distantPast) }),
           longest.resetsAt != nil
        {
            return longest
        }
        return windows.first
    }

    func attachingCycle(now: Date = Date()) -> QuotaSnapshot {
        guard cycleEnd == nil else { return self }
        guard let end = forecastWindow?.resetsAt ?? windows.compactMap(\.resetsAt).max() else {
            return self
        }
        var next = self
        next.cycleEnd = end
        if next.cycleStart == nil {
            next.cycleStart = BurnForecast.inferredStart(end: end, now: now)
        }
        return next
    }

    func with(planName: String?) -> QuotaSnapshot {
        QuotaSnapshot(
            provider: provider,
            planName: planName,
            windows: windows,
            fetchedAt: fetchedAt,
            cycleStart: cycleStart,
            cycleEnd: cycleEnd,
            subscribedAt: subscribedAt
        )
    }
}

enum UsageTone: Sendable {
    case good
    case mid
    case warn
    case critical

    static func from(percent: Double) -> UsageTone {
        switch percent {
        case ..<50: .good
        case ..<70: .mid
        case ..<90: .warn
        default: .critical
        }
    }
}

enum CheckUsageError: Error, LocalizedError {
    case missingCredentials
    case missingAPIKey
    case unauthorized
    case rateLimited(retryAfter: TimeInterval?)
    case unexpectedStatus(Int)
    case decode
    case message(String)

    var errorDescription: String? {
        switch self {
        case .missingCredentials: "not_signed_in"
        case .missingAPIKey: "missing_key"
        case .unauthorized: "unauthorized"
        case .rateLimited: "rate_limited"
        case .unexpectedStatus(let code): "http_\(code)"
        case .decode: "decode_error"
        case .message(let text): text
        }
    }
}
