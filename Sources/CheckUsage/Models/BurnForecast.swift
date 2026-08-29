import Foundation

enum PaceKind: String, Sendable, Equatable {
    case unknown
    case comfortable
    case onTrack
    case hot
    case burning
    case depleted
}

struct BurnForecast: Equatable, Sendable {
    var usedPercent: Double
    var dailyBurn: Double
    var daysElapsed: Double
    var daysLeftInCycle: Double
    var cycleStart: Date
    var cycleEnd: Date
    var projectedEmpty: Date?
    var expectedPercentByNow: Double
    var kind: PaceKind

    static func inferredStart(end: Date, now: Date = Date()) -> Date {
        let left = end.timeIntervalSince(now)
        if left <= 6 * 3600 {
            return end.addingTimeInterval(-5 * 3600)
        }
        if left <= 8 * 86400 {
            return end.addingTimeInterval(-7 * 86400)
        }
        return Calendar.current.date(byAdding: .month, value: -1, to: end)
            ?? end.addingTimeInterval(-30 * 86400)
    }

    static func make(
        usedPercent: Double,
        cycleStart: Date?,
        cycleEnd: Date?,
        now: Date = Date(),
        firstSeen: Date? = nil,
        firstPercent: Double? = nil
    ) -> BurnForecast? {
        guard let end = cycleEnd, end > now.addingTimeInterval(-3600) else { return nil }
        let inferred = inferredStart(end: end, now: now)
        let displayStart = cycleStart ?? firstSeen ?? inferred
        let mathStart = min(displayStart, now.addingTimeInterval(-4 * 3600))
        let elapsed = max(now.timeIntervalSince(mathStart), 4 * 3600)
        let cycleLen = max(end.timeIntervalSince(mathStart), 86400)
        let used = min(100, max(0, usedPercent))
        let daysUsed = elapsed / 86400
        let expected = min(100, 100 * elapsed / cycleLen)

        let daily: Double
        if cycleStart == nil,
           let firstSeen,
           let firstPercent,
           now.timeIntervalSince(firstSeen) >= 12 * 3600,
           used >= firstPercent
        {
            let observedDays = max(now.timeIntervalSince(firstSeen) / 86400, 4.0 / 24)
            daily = (used - firstPercent) / observedDays
        } else {
            daily = used / daysUsed
        }

        let remaining = max(0, 100 - used)
        let projected: Date?
        if used >= 99.5 {
            projected = now
        } else if daily > 0.05 {
            projected = now.addingTimeInterval((remaining / daily) * 86400)
        } else {
            projected = nil
        }

        let kind: PaceKind
        let ratio = used / max(expected, 1)
        if used >= 96 {
            kind = .depleted
        } else if used < 1.5, elapsed < 12 * 3600 {
            kind = .unknown
        } else if let projected, projected < end.addingTimeInterval(-2 * 86400), ratio >= 1.15 {
            kind = ratio >= 1.7 ? .burning : .hot
        } else if ratio < 0.8 {
            kind = .comfortable
        } else if ratio < 1.2 {
            kind = .onTrack
        } else if ratio < 1.7 {
            kind = .hot
        } else {
            kind = .burning
        }

        return BurnForecast(
            usedPercent: used,
            dailyBurn: daily,
            daysElapsed: daysUsed,
            daysLeftInCycle: max(0, end.timeIntervalSince(now) / 86400),
            cycleStart: displayStart,
            cycleEnd: end,
            projectedEmpty: projected,
            expectedPercentByNow: expected,
            kind: kind
        )
    }

    var tone: UsageTone {
        switch kind {
        case .comfortable, .onTrack, .unknown: .good
        case .hot: .warn
        case .burning, .depleted: .critical
        }
    }

    func headline() -> String {
        switch kind {
        case .unknown:
            return L10n.t("forecast_unknown")
        case .depleted:
            return L10n.t("forecast_empty")
        case .comfortable, .onTrack:
            return L10n.format("forecast_ok", DateCopy.short(cycleEnd))
        case .hot, .burning:
            if let projectedEmpty, projectedEmpty < cycleEnd {
                let early = max(1, Int(cycleEnd.timeIntervalSince(projectedEmpty) / 86400))
                return L10n.format("forecast_early", DateCopy.short(projectedEmpty), L10n.format("days_short", early))
            }
            return L10n.format("forecast_ok", DateCopy.short(cycleEnd))
        }
    }

    func tip() -> String {
        switch kind {
        case .unknown: L10n.t("tip_unknown")
        case .comfortable: L10n.t("tip_ok")
        case .onTrack: L10n.t("tip_track")
        case .hot: L10n.t("tip_hot")
        case .burning: L10n.t("tip_burn")
        case .depleted: L10n.t("tip_dead")
        }
    }

    func spentLine() -> String {
        L10n.format(
            "spent_pace",
            String(format: "%.0f%%", usedPercent),
            DateCopy.span(daysElapsed * 86400),
            String(format: "%.1f%%", dailyBurn)
        )
    }
}

enum DateCopy {
    static func short(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: L10n.resolvedCode)
        formatter.setLocalizedDateFormatFromTemplate("MMMd")
        return formatter.string(from: date)
    }

    static func span(_ interval: TimeInterval) -> String {
        if interval < 3600 {
            return L10n.format("minutes_short", max(1, Int(interval / 60)))
        }
        if interval < 36 * 3600 {
            return L10n.format("hours_short", max(1, Int((interval / 3600).rounded())))
        }
        return L10n.format("days_short", max(1, Int((interval / 86400).rounded())))
    }
}

struct CycleWatch: Codable, Equatable, Sendable {
    var cycleEnd: TimeInterval
    var firstAt: TimeInterval
    var firstPercent: Double
}
