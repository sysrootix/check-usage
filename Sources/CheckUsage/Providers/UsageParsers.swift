import Foundation

enum UsageParsers {
    static func claude(_ json: JSONValue, fetchedAt: Date = Date()) -> QuotaSnapshot {
        var windows: [QuotaWindow] = []

        if let limits = json["limits"]?.array, !limits.isEmpty {
            for (index, limit) in limits.enumerated() {
                let kind = limit["kind"]?.string ?? "limit"
                let percent = limit["percent"]?.double ?? 0
                let title = claudeTitle(
                    kind: kind,
                    displayName: limit.path("scope", "model", "display_name")?.string
                )
                windows.append(
                    QuotaWindow(
                        id: "\(kind)-\(index)",
                        title: title,
                        usedPercent: percent,
                        resetsAt: DateParser.parse(limit["resets_at"]),
                        footnote: nil
                    )
                )
            }
        } else {
            if let five = json["five_hour"], five.object != nil {
                windows.append(window(id: "five_hour", title: L10n.t("current_session"), node: five))
            }
            if let week = json["seven_day"], week.object != nil {
                windows.append(window(id: "seven_day", title: L10n.t("all_models"), node: week))
            }
            if let opus = json["seven_day_opus"], opus.object != nil {
                windows.append(window(id: "seven_day_opus", title: L10n.t("weekly_opus"), node: opus))
            }
            if let sonnet = json["seven_day_sonnet"], sonnet.object != nil {
                windows.append(window(id: "seven_day_sonnet", title: L10n.t("weekly_sonnet"), node: sonnet))
            }
        }

        if windows.isEmpty {
            if let five = json["five_hour"] {
                windows.append(window(id: "five_hour", title: L10n.t("current_session"), node: five))
            }
            if let week = json["seven_day"] {
                windows.append(window(id: "seven_day", title: L10n.t("all_models"), node: week))
            }
        }

        if let extra = json["extra_usage"], extra["is_enabled"]?.bool == true {
            let used = extra["used_credits"]?.double ?? 0
            let limit = extra["monthly_limit"]?.double ?? 0
            if limit > 0 {
                windows.append(
                    QuotaWindow(
                        id: "extra",
                        title: L10n.t("extra_usage"),
                        usedPercent: used / limit * 100,
                        resetsAt: nil,
                        footnote: String(format: "$%.2f / $%.2f", used / 100, limit / 100)
                    )
                )
            }
        }

        let long = windows.max(by: { ($0.resetsAt ?? .distantPast) < ($1.resetsAt ?? .distantPast) })
        return QuotaSnapshot(
            provider: .claude,
            planName: nil,
            windows: windows,
            fetchedAt: fetchedAt,
            cycleStart: long?.resetsAt.map { BurnForecast.inferredStart(end: $0, now: fetchedAt) },
            cycleEnd: long?.resetsAt
        ).attachingCycle(now: fetchedAt)
    }

    static func claudeTitle(kind: String, displayName: String?) -> String {
        switch kind {
        case "session": return L10n.t("current_session")
        case "weekly_all": return L10n.t("all_models")
        case "weekly_scoped":
            return displayName.map { $0 } ?? L10n.t("weekly")
        default:
            return displayName ?? L10n.t("weekly")
        }
    }

    static func codex(_ json: JSONValue, fetchedAt: Date = Date()) -> QuotaSnapshot {
        let rate = json["rate_limit"] ?? json["rateLimits"] ?? json
        var windows: [QuotaWindow] = []

        if let primary = rate["primary_window"] ?? rate["primary"] {
            windows.append(codexWindow(id: "primary", node: primary))
        }
        if let secondary = rate["secondary_window"] ?? rate["secondary"] {
            windows.append(codexWindow(id: "secondary", node: secondary))
        }
        if let extras = json["additional_rate_limits"]?.array {
            for (index, extra) in extras.enumerated() {
                let name = extra["limit_name"]?.string ?? extra["name"]?.string ?? L10n.t("weekly")
                let inner = extra["rate_limit"]?["primary_window"] ?? extra["primary_window"] ?? extra
                windows.append(codexWindow(id: "extra-\(index)", node: inner, title: name))
            }
        }
        if let credits = json["credits"] ?? rate["credits"], credits["has_credits"]?.bool == true || credits["hasCredits"]?.bool == true {
            if credits["unlimited"]?.bool != true, let balance = credits["balance"]?.double {
                windows.append(
                    QuotaWindow(
                        id: "credits",
                        title: L10n.t("credits"),
                        usedPercent: 0,
                        resetsAt: nil,
                        footnote: String(format: "%.0f", balance)
                    )
                )
            }
        }
        let plan = json["plan_type"]?.string ?? rate["planType"]?.string
        return QuotaSnapshot(provider: .codex, planName: plan, windows: windows, fetchedAt: fetchedAt)
            .attachingCycle(now: fetchedAt)
    }

    static func cursor(_ json: JSONValue, plan: JSONValue? = nil, fetchedAt: Date = Date()) -> QuotaSnapshot {
        let usage = json["planUsage"] ?? json.path("individualUsage", "plan") ?? json
        var windows: [QuotaWindow] = []
        let cycleEnd = cursorCycleEnd(usageJSON: json, plan: plan, now: fetchedAt)
        let limit = usage["limit"]?.double
            ?? plan?.path("planInfo", "includedAmountCents")?.double
        if let percent = cursorPlanPercent(usage: usage, limit: limit) {
            windows.append(
                QuotaWindow(
                    id: "total",
                    title: L10n.t("included_plan"),
                    usedPercent: percent,
                    resetsAt: cycleEnd,
                    footnote: cursorOnDemandFootnote(json["spendLimitUsage"]),
                    hint: nil
                )
            )
        }
        if let auto = usage["autoPercentUsed"]?.double {
            windows.append(
                QuotaWindow(
                    id: "auto",
                    title: L10n.t("auto_models"),
                    usedPercent: cursorVisiblePercent(auto),
                    resetsAt: cycleEnd,
                    footnote: nil
                )
            )
        }
        if let api = usage["apiPercentUsed"]?.double {
            windows.append(
                QuotaWindow(
                    id: "api",
                    title: L10n.t("named_models"),
                    usedPercent: cursorVisiblePercent(api),
                    resetsAt: cycleEnd,
                    footnote: nil
                )
            )
        }
        return QuotaSnapshot(
            provider: .cursor,
            planName: json["planName"]?.string,
            windows: windows,
            fetchedAt: fetchedAt,
            cycleStart: cursorCycleStart(usageJSON: json, plan: plan, end: cycleEnd, now: fetchedAt),
            cycleEnd: cycleEnd,
            subscribedAt: cursorSubscribedAt(plan)
        )
    }

    static func copilot(_ json: JSONValue, fetchedAt: Date = Date()) -> QuotaSnapshot {
        let reset = DateParser.parse(json["quota_reset_date"])
        var windows: [QuotaWindow] = []
        if let premium = json.path("quota_snapshots", "premium_interactions") {
            windows.append(copilotWindow(id: "premium", title: L10n.t("premium"), node: premium, reset: reset))
        }
        if let chat = json.path("quota_snapshots", "chat"), chat["unlimited"]?.bool != true {
            windows.append(copilotWindow(id: "chat", title: "Chat", node: chat, reset: reset))
        }
        if let completions = json.path("quota_snapshots", "completions"), completions["unlimited"]?.bool != true {
            windows.append(copilotWindow(id: "completions", title: "Completions", node: completions, reset: reset))
        }
        return QuotaSnapshot(
            provider: .copilot,
            planName: json["copilot_plan"]?.string,
            windows: windows,
            fetchedAt: fetchedAt,
            cycleStart: reset.map { BurnForecast.inferredStart(end: $0, now: fetchedAt) },
            cycleEnd: reset
        )
    }

    static func gemini(_ json: JSONValue, fetchedAt: Date = Date()) -> QuotaSnapshot {
        var windows: [QuotaWindow] = []
        let groups = json["groups"]?.array ?? [json]
        for group in groups {
            let buckets = group["buckets"]?.array ?? []
            for bucket in buckets {
                let id = bucket["bucketId"]?.string ?? bucket["modelId"]?.string ?? UUID().uuidString
                let remaining = bucket["remainingFraction"]?.double ?? 0
                windows.append(
                    QuotaWindow(
                        id: id,
                        title: geminiTitle(id),
                        usedPercent: (1 - remaining) * 100,
                        resetsAt: DateParser.parse(bucket["resetTime"]),
                        footnote: nil
                    )
                )
            }
        }
        return QuotaSnapshot(provider: .gemini, planName: json.path("currentTier", "name")?.string, windows: windows, fetchedAt: fetchedAt)
            .attachingCycle(now: fetchedAt)
    }

    static func grok(_ json: JSONValue, fetchedAt: Date = Date()) -> QuotaSnapshot {
        let config = json["config"] ?? json
        let used = config["creditUsagePercent"]?.double ?? 0
        let end = DateParser.parse(config.path("currentPeriod", "end"))
        let start = DateParser.parse(config.path("currentPeriod", "start"))
        let window = QuotaWindow(id: "weekly", title: L10n.t("weekly"), usedPercent: used, resetsAt: end, footnote: nil)
        return QuotaSnapshot(
            provider: .grok,
            planName: json["subscription_tier_display"]?.string,
            windows: [window],
            fetchedAt: fetchedAt,
            cycleStart: start,
            cycleEnd: end
        ).attachingCycle(now: fetchedAt)
    }

    static func openRouter(credits: JSONValue, key: JSONValue?, fetchedAt: Date = Date()) -> QuotaSnapshot {
        var windows: [QuotaWindow] = []
        let data = credits["data"] ?? credits
        let total = data["total_credits"]?.double ?? 0
        let used = data["total_usage"]?.double ?? 0
        if total > 0 {
            windows.append(
                QuotaWindow(
                    id: "credits",
                    title: L10n.t("credits"),
                    usedPercent: used / total * 100,
                    resetsAt: nil,
                    footnote: String(format: "$%.2f / $%.2f", used, total)
                )
            )
        }
        if let keyData = key?["data"] ?? key, let remaining = keyData["limit_remaining"]?.double, let limit = keyData["limit"]?.double, limit > 0 {
            windows.append(
                QuotaWindow(
                    id: "key",
                    title: L10n.t("monthly"),
                    usedPercent: (limit - remaining) / limit * 100,
                    resetsAt: nil,
                    footnote: nil
                )
            )
        }
        let plan = key?["data"]?["is_free_tier"]?.bool == true ? "Free" : "Pay as you go"
        return QuotaSnapshot(provider: .openrouter, planName: plan, windows: windows, fetchedAt: fetchedAt)
    }

    static func deepSeek(_ json: JSONValue, fetchedAt: Date = Date()) -> QuotaSnapshot {
        let infos = json["balance_infos"]?.array ?? []
        let usd = infos.first(where: { $0["currency"]?.string == "USD" }) ?? infos.first
        let total = usd?["total_balance"]?.double ?? 0
        let window = QuotaWindow(
            id: "balance",
            title: L10n.t("credits"),
            usedPercent: 0,
            resetsAt: nil,
            footnote: String(format: "$%.2f", total)
        )
        return QuotaSnapshot(provider: .deepseek, planName: nil, windows: [window], fetchedAt: fetchedAt)
    }

    static func openCode(_ json: JSONValue, fetchedAt: Date = Date()) -> QuotaSnapshot {
        let usage = json["usage"] ?? json
        var windows: [QuotaWindow] = []
        for key in ["rolling", "weekly", "monthly"] {
            if let node = usage[key] {
                let title = key == "rolling" ? L10n.t("current_session") : L10n.t(key)
                windows.append(
                    QuotaWindow(
                        id: key,
                        title: title,
                        usedPercent: node["percent"]?.double ?? 0,
                        resetsAt: DateParser.parse(node["resetsAt"] ?? node["resets_at"]),
                        footnote: nil
                    )
                )
            }
        }
        return QuotaSnapshot(provider: .opencode, planName: nil, windows: windows, fetchedAt: fetchedAt)
            .attachingCycle(now: fetchedAt)
    }

    static func zai(_ json: JSONValue, fetchedAt: Date = Date()) -> QuotaSnapshot {
        var windows: [QuotaWindow] = []
        let limits = json["limits"]?.array ?? json["data"]?["limits"]?.array ?? []
        for (index, limit) in limits.enumerated() {
            let kind = limit["type"]?.string ?? limit["limit_type"]?.string ?? "limit"
            let used = limit["used_percent"]?.double ?? limit["percent"]?.double ?? 0
            windows.append(
                QuotaWindow(
                    id: "\(kind)-\(index)",
                    title: zaiTitle(kind),
                    usedPercent: used,
                    resetsAt: DateParser.parse(limit["reset_at"] ?? limit["resetAt"]),
                    footnote: nil
                )
            )
        }
        return QuotaSnapshot(provider: .zai, planName: nil, windows: windows, fetchedAt: fetchedAt)
            .attachingCycle(now: fetchedAt)
    }

    private static func window(id: String, title: String, node: JSONValue) -> QuotaWindow {
        QuotaWindow(
            id: id,
            title: title,
            usedPercent: node["utilization"]?.double ?? node["percent"]?.double ?? 0,
            resetsAt: DateParser.parse(node["resets_at"]),
            footnote: nil
        )
    }

    private static func codexWindow(id: String, node: JSONValue, title: String? = nil) -> QuotaWindow {
        let seconds = node["limit_window_seconds"]?.double ?? ((node["windowDurationMins"]?.double ?? 0) * 60)
        let resolved = title ?? windowTitle(seconds: seconds)
        let reset = DateParser.parse(node["reset_at"] ?? node["resetsAt"])
            ?? node["reset_after_seconds"]?.double.map { Date().addingTimeInterval($0) }
        return QuotaWindow(
            id: id,
            title: resolved,
            usedPercent: node["used_percent"]?.double ?? node["usedPercent"]?.double ?? 0,
            resetsAt: reset,
            footnote: nil
        )
    }

    private static func copilotWindow(id: String, title: String, node: JSONValue, reset: Date?) -> QuotaWindow {
        let remaining = node["percent_remaining"]?.double
        let used: Double
        if let remaining {
            used = 100 - remaining
        } else if let entitlement = node["entitlement"]?.double, entitlement > 0, let left = node["remaining"]?.double {
            used = (entitlement - left) / entitlement * 100
        } else {
            used = 0
        }
        return QuotaWindow(id: id, title: title, usedPercent: used, resetsAt: reset, footnote: nil)
    }

    private static func windowTitle(seconds: Double) -> String {
        switch seconds {
        case 1_6000...20_000: L10n.t("current_session")
        case 80_000...90_000: L10n.t("daily")
        case 500_000...700_000: L10n.t("weekly")
        default: L10n.t("plan")
        }
    }

    private static func geminiTitle(_ id: String) -> String {
        if id.contains("5h") { return L10n.t("five_hour") }
        if id.contains("weekly") { return L10n.t("weekly") }
        return id
    }

    private static func zaiTitle(_ kind: String) -> String {
        switch kind.uppercased() {
        case "CREDIT_LIMIT", "TOKENS_LIMIT": L10n.t("weekly")
        case "TIME_LIMIT": L10n.t("monthly")
        default: kind
        }
    }

    static func cursorCycleStart(usageJSON: JSONValue, plan: JSONValue?, end: Date?, now: Date = Date()) -> Date? {
        let candidates: [JSONValue?] = [
            usageJSON["billingCycleStart"],
            usageJSON["periodStart"],
            usageJSON.path("planUsage", "billingCycleStart"),
            plan?.path("planInfo", "billingCycleStart"),
            plan?["billingCycleStart"],
        ]
        for candidate in candidates {
            if let date = DateParser.parse(candidate) {
                return date < now ? date : nil
            }
        }
        return end.map { inferredStartForCursor($0, now: now) }
    }

    static func cursorSubscribedAt(_ plan: JSONValue?) -> Date? {
        let candidates: [JSONValue?] = [
            plan?.path("planInfo", "subscriptionStart"),
            plan?.path("planInfo", "startDate"),
            plan?.path("planInfo", "createdAt"),
            plan?["subscriptionStart"],
            plan?["membershipStart"],
        ]
        for candidate in candidates {
            if let date = DateParser.parse(candidate) {
                return date
            }
        }
        return nil
    }

    private static func inferredStartForCursor(_ end: Date, now: Date) -> Date {
        Calendar.current.date(byAdding: .month, value: -1, to: end) ?? BurnForecast.inferredStart(end: end, now: now)
    }

    static func cursorCycleEnd(usageJSON: JSONValue, plan: JSONValue?, now: Date = Date()) -> Date? {
        let candidates: [JSONValue?] = [
            usageJSON["billingCycleEnd"],
            usageJSON["periodEnd"],
            usageJSON["billingCycleEndMs"],
            usageJSON.path("planUsage", "billingCycleEnd"),
            plan?.path("planInfo", "billingCycleEnd"),
            plan?.path("planInfo", "nextResetDate"),
            plan?.path("planInfo", "nextPaymentDate"),
            plan?["billingCycleEnd"],
            plan?["nextPaymentDate"],
        ]
        for candidate in candidates {
            if let date = DateParser.parse(candidate) {
                return upcomingMonthly(date, now: now)
            }
        }
        let starts: [JSONValue?] = [
            usageJSON["billingCycleStart"],
            plan?.path("planInfo", "billingCycleStart"),
            plan?["billingCycleStart"],
        ]
        for start in starts {
            if let date = DateParser.parse(start) {
                if let plusMonth = Calendar.current.date(byAdding: .month, value: 1, to: date) {
                    return upcomingMonthly(plusMonth, now: now)
                }
            }
        }
        return nil
    }

    static func upcomingMonthly(_ date: Date, now: Date = Date()) -> Date {
        var result = date
        let calendar = Calendar.current
        var guardCount = 0
        while result <= now, guardCount < 24 {
            guard let next = calendar.date(byAdding: .month, value: 1, to: result) else { break }
            result = next
            guardCount += 1
        }
        return result
    }

    static func dollarFootnote(used: Double?, limit: Double?) -> String? {
        cursorPlanFootnote(
            included: used,
            bonus: 0,
            limit: limit,
            onDemand: nil
        )
    }

    static func cursorPlanPercent(usage: JSONValue, limit: Double?) -> Double? {
        if let total = usage["totalPercentUsed"]?.double {
            return cursorVisiblePercent(total)
        }
        if let used = usage["used"]?.double, let limit, limit > 0 {
            return cursorVisiblePercent(used / limit * 100)
        }
        return nil
    }

    static func cursorVisiblePercent(_ raw: Double) -> Double {
        if raw > 0, raw < 1 { return 1 }
        return raw
    }

    static func cursorOnDemandFootnote(_ node: JSONValue?) -> String? {
        guard let cents = onDemandCents(node), cents > 0.5 else { return nil }
        return L10n.format("cursor_ondemand", money(cents / 100))
    }

    static func cursorPlanFootnote(
        included: Double?,
        bonus: Double,
        limit: Double?,
        onDemand: Double?
    ) -> String? {
        var parts: [String] = []
        if let included, let limit, limit > 0 {
            let spent = included / 100
            let cap = limit / 100
            if included > limit + 0.5 {
                parts.append(L10n.format("spent_over", money(spent), money(cap), money((included - limit) / 100)))
            } else {
                parts.append(L10n.format("spent_of", money(spent), money(cap)))
            }
        }
        if bonus > 0.5 {
            parts.append(L10n.format("cursor_bonus", money(bonus / 100)))
        }
        if let onDemand, onDemand > 0.5 {
            parts.append(L10n.format("cursor_ondemand", money(onDemand / 100)))
        }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    static func onDemandCents(_ node: JSONValue?) -> Double? {
        guard let node else { return nil }
        let keys = ["individualUsed", "totalSpend", "pooledUsed"]
        return keys.compactMap { node[$0]?.double }.first { $0 > 0.5 }
    }

    private static func money(_ value: Double) -> String {
        String(format: "$%.2f", value)
    }
}
