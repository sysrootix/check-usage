import XCTest
@testable import CheckUsage

final class UsageParserTests: XCTestCase {
    func testClaudeLimitsArray() throws {
        let json = try JSONValue.parse(Data("""
        {
          "five_hour": { "utilization": 73, "resets_at": "2026-08-29T10:00:00Z" },
          "seven_day": { "utilization": 7, "resets_at": "2026-09-04T14:00:00Z" },
          "limits": [
            { "kind": "session", "percent": 73, "resets_at": "2026-08-29T10:00:00Z" },
            { "kind": "weekly_all", "percent": 7, "resets_at": "2026-09-04T14:00:00Z" },
            { "kind": "weekly_scoped", "percent": 12, "scope": { "model": { "display_name": "Fable" } } }
          ]
        }
        """.utf8))
        let snapshot = UsageParsers.claude(json)
        XCTAssertEqual(snapshot.windows.count, 3)
        XCTAssertEqual(snapshot.primaryPercent, 73, accuracy: 0.01)
        XCTAssertEqual(snapshot.windows[1].usedPercent, 7, accuracy: 0.01)
        XCTAssertEqual(snapshot.windows[2].title, "Fable")
        XCTAssertNotNil(snapshot.cycleEnd)
        XCTAssertNotNil(snapshot.cycleStart)
        XCTAssertEqual(snapshot.forecastWindow?.id.hasPrefix("weekly_all") ?? false, true)
    }

    func testClaudeFlatWindows() throws {
        let json = try JSONValue.parse(Data("""
        {
          "five_hour": { "utilization": 41, "resets_at": "2026-08-29T10:00:00Z" },
          "seven_day": { "utilization": 19, "resets_at": "2026-09-04T14:00:00Z" }
        }
        """.utf8))
        let snapshot = UsageParsers.claude(json)
        XCTAssertEqual(snapshot.windows.count, 2)
        XCTAssertEqual(snapshot.windows[0].usedPercent, 41, accuracy: 0.01)
    }

    func testCodexWindows() throws {
        let json = try JSONValue.parse(Data("""
        {
          "plan_type": "plus",
          "rate_limit": {
            "primary_window": { "used_percent": 21, "limit_window_seconds": 18000, "reset_at": 1782770922 },
            "secondary_window": { "used_percent": 4, "limit_window_seconds": 604800, "reset_at": 1783357722 }
          }
        }
        """.utf8))
        let snapshot = UsageParsers.codex(json)
        XCTAssertEqual(snapshot.planName, "plus")
        XCTAssertEqual(snapshot.windows[0].usedPercent, 21, accuracy: 0.01)
        XCTAssertEqual(snapshot.windows.count, 2)
        XCTAssertNotNil(snapshot.windows[0].resetsAt)
    }

    func testCursorPercents() throws {
        let json = try JSONValue.parse(Data("""
        {
          "billingCycleEnd": 1783357722000,
          "planUsage": { "totalPercentUsed": 52, "autoPercentUsed": 10, "apiPercentUsed": 8, "totalSpend": 1288, "limit": 2000 }
        }
        """.utf8))
        let snapshot = UsageParsers.cursor(json)
        XCTAssertEqual(snapshot.primaryPercent, 52, accuracy: 0.01)
        XCTAssertEqual(snapshot.windows.count, 3)
        XCTAssertNil(snapshot.windows[0].footnote)
        XCTAssertNil(snapshot.windows[0].hint)
        XCTAssertNotNil(snapshot.cycleEnd)
        XCTAssertNotNil(snapshot.cycleStart)
    }

    func testCursorBillingDatesAndSubscription() throws {
        let iso = ISO8601DateFormatter()
        let fetched = iso.date(from: "2026-08-15T12:00:00Z")!
        let json = try JSONValue.parse(Data("""
        {
          "billingCycleStart": "2026-08-01T00:00:00Z",
          "billingCycleEnd": "2026-09-01T00:00:00Z",
          "planUsage": { "totalPercentUsed": 12 }
        }
        """.utf8))
        let plan = try JSONValue.parse(Data("""
        { "planInfo": { "subscriptionStart": "2026-03-12T00:00:00Z" } }
        """.utf8))
        let snapshot = UsageParsers.cursor(json, plan: plan, fetchedAt: fetched)
        XCTAssertEqual(snapshot.cycleStart, DateParser.iso("2026-08-01T00:00:00Z"))
        XCTAssertEqual(snapshot.cycleEnd, DateParser.iso("2026-09-01T00:00:00Z"))
        XCTAssertEqual(snapshot.subscribedAt, DateParser.iso("2026-03-12T00:00:00Z"))
        XCTAssertEqual(snapshot.forecastWindow?.id, "total")
    }

    func testCopilotRemainingToUsed() throws {
        let json = try JSONValue.parse(Data("""
        {
          "copilot_plan": "pro",
          "quota_reset_date": "2026-09-01T00:00:00Z",
          "quota_snapshots": {
            "premium_interactions": { "percent_remaining": 40, "entitlement": 300, "remaining": 120 }
          }
        }
        """.utf8))
        let snapshot = UsageParsers.copilot(json)
        XCTAssertEqual(snapshot.primaryPercent, 60, accuracy: 0.01)
        XCTAssertEqual(snapshot.planName, "pro")
    }

    func testGeminiRemainingFraction() throws {
        let json = try JSONValue.parse(Data("""
        {
          "groups": [{
            "buckets": [
              { "bucketId": "gemini-5h", "remainingFraction": 0.27, "resetTime": "2026-08-29T10:00:00Z" },
              { "bucketId": "gemini-weekly", "remainingFraction": 0.93, "resetTime": "2026-09-04T00:00:00Z" }
            ]
          }]
        }
        """.utf8))
        let snapshot = UsageParsers.gemini(json)
        XCTAssertEqual(snapshot.windows[0].usedPercent, 73, accuracy: 0.1)
        XCTAssertEqual(snapshot.windows[1].usedPercent, 7, accuracy: 0.1)
    }

    func testGrokMissingPercentIsZero() throws {
        let json = try JSONValue.parse(Data("""
        { "config": { "currentPeriod": { "type": "USAGE_PERIOD_TYPE_WEEKLY", "end": "2026-09-04T00:00:00Z" } } }
        """.utf8))
        let snapshot = UsageParsers.grok(json)
        XCTAssertEqual(snapshot.primaryPercent, 0, accuracy: 0.01)
    }

    func testOpenRouterCredits() throws {
        let credits = try JSONValue.parse(Data("""
        { "data": { "total_credits": 100, "total_usage": 25 } }
        """.utf8))
        let snapshot = UsageParsers.openRouter(credits: credits, key: nil)
        XCTAssertEqual(snapshot.primaryPercent, 25, accuracy: 0.01)
    }

    func testCursorSpendOverIncludedCap() {
        L10n.language = .en
        let copy = UsageParsers.dollarFootnote(used: 40888, limit: 40000)
        XCTAssertEqual(copy, "Spent $408.88 of $400.00 · $8.88 over")
    }

    func testCursorBonusIsNotOverage() throws {
        L10n.language = .en
        let json = try JSONValue.parse(Data("""
        {
          "planUsage": {
            "totalPercentUsed": 12.2,
            "autoPercentUsed": 14.2,
            "apiPercentUsed": 0.08,
            "totalSpend": 42753,
            "includedSpend": 40000,
            "bonusSpend": 2753,
            "limit": 40000
          },
          "spendLimitUsage": {}
        }
        """.utf8))
        let snapshot = UsageParsers.cursor(json)
        XCTAssertEqual(snapshot.primaryPercent, 12.2, accuracy: 0.01)
        XCTAssertEqual(snapshot.windows[2].usedPercent, 1, accuracy: 0.01)
        XCTAssertNil(snapshot.windows[0].footnote)
    }

    func testCursorOnDemandIsSeparateFromBonus() throws {
        L10n.language = .en
        let json = try JSONValue.parse(Data("""
        {
          "planUsage": {
            "totalPercentUsed": 100,
            "includedSpend": 40000,
            "bonusSpend": 0,
            "limit": 40000
          },
          "spendLimitUsage": { "individualUsed": 2183 }
        }
        """.utf8))
        let snapshot = UsageParsers.cursor(json)
        XCTAssertEqual(snapshot.primaryPercent, 100, accuracy: 0.01)
        XCTAssertTrue(snapshot.windows[0].footnote?.contains("On-demand") == true, snapshot.windows[0].footnote ?? "")
        XCTAssertTrue(snapshot.windows[0].footnote?.contains("21.83") == true, snapshot.windows[0].footnote ?? "")
    }

    func testToneThresholds() {
        XCTAssertEqual(UsageTone.from(percent: 21), .good)
        XCTAssertEqual(UsageTone.from(percent: 52), .mid)
        XCTAssertEqual(UsageTone.from(percent: 73), .warn)
        XCTAssertEqual(UsageTone.from(percent: 95), .critical)
    }

    func testClaudeOpusSonnetAndExtraUsage() throws {
        L10n.language = .en
        let json = try JSONValue.parse(Data("""
        {
          "five_hour": { "utilization": 88.4, "resets_at": "2026-08-29T10:00:00Z" },
          "seven_day": { "utilization": 31.2, "resets_at": "2026-09-04T14:00:00Z" },
          "seven_day_opus": { "utilization": 64, "resets_at": "2026-09-04T14:00:00Z" },
          "seven_day_sonnet": { "percent": 9, "resets_at": "2026-09-04T14:00:00Z" },
          "extra_usage": { "is_enabled": true, "used_credits": 1250, "monthly_limit": 5000 }
        }
        """.utf8))
        let snapshot = UsageParsers.claude(json)
        XCTAssertEqual(snapshot.windows.count, 5)
        XCTAssertEqual(snapshot.windows[0].usedPercent, 88.4, accuracy: 0.01)
        XCTAssertEqual(snapshot.windows[2].title, "Weekly Opus")
        XCTAssertEqual(snapshot.windows[3].usedPercent, 9, accuracy: 0.01)
        XCTAssertEqual(snapshot.windows[4].id, "extra")
        XCTAssertEqual(snapshot.windows[4].usedPercent, 25, accuracy: 0.01)
        XCTAssertEqual(snapshot.windows[4].footnote, "$12.50 / $50.00")
    }

    func testClaudeDisabledExtraUsageIsIgnored() throws {
        let json = try JSONValue.parse(Data("""
        {
          "five_hour": { "utilization": 10 },
          "extra_usage": { "is_enabled": false, "used_credits": 99, "monthly_limit": 5000 }
        }
        """.utf8))
        let snapshot = UsageParsers.claude(json)
        XCTAssertEqual(snapshot.windows.count, 1)
        XCTAssertFalse(snapshot.windows.contains(where: { $0.id == "extra" }))
    }

    func testCodexCamelCaseExtrasAndCredits() throws {
        L10n.language = .en
        let json = try JSONValue.parse(Data("""
        {
          "plan_type": "pro",
          "rateLimits": {
            "primary": { "usedPercent": 67.5, "windowDurationMins": 300, "resetsAt": 1782770922 },
            "secondary": { "used_percent": 18, "limit_window_seconds": 604800, "reset_after_seconds": 400000 }
          },
          "additional_rate_limits": [
            { "limit_name": "code_review", "primary_window": { "used_percent": 5, "limit_window_seconds": 86400 } }
          ],
          "credits": { "has_credits": true, "balance": 42 }
        }
        """.utf8))
        let snapshot = UsageParsers.codex(json)
        XCTAssertEqual(snapshot.planName, "pro")
        XCTAssertEqual(snapshot.windows.count, 4)
        XCTAssertEqual(snapshot.windows[0].usedPercent, 67.5, accuracy: 0.01)
        XCTAssertEqual(snapshot.windows[0].title, "Current session")
        XCTAssertEqual(snapshot.windows[1].title, "Weekly")
        XCTAssertNotNil(snapshot.windows[1].resetsAt)
        XCTAssertEqual(snapshot.windows[2].title, "code_review")
        XCTAssertEqual(snapshot.windows[2].usedPercent, 5, accuracy: 0.01)
        XCTAssertEqual(snapshot.windows[3].id, "credits")
        XCTAssertEqual(snapshot.windows[3].footnote, "42")
    }

    func testCursorIndividualUsageAndMillisCycle() throws {
        let fetched = DateParser.iso("2026-08-15T12:00:00Z")!
        let json = try JSONValue.parse(Data("""
        {
          "billingCycleEndMs": 1788220800000,
          "periodStart": "2026-08-01T00:00:00Z",
          "planName": "Pro",
          "individualUsage": {
            "plan": { "used": 800, "limit": 2000 }
          }
        }
        """.utf8))
        let snapshot = UsageParsers.cursor(json, fetchedAt: fetched)
        XCTAssertEqual(snapshot.planName, "Pro")
        XCTAssertEqual(snapshot.primaryPercent, 40, accuracy: 0.01)
        XCTAssertEqual(snapshot.windows.count, 1)
        XCTAssertEqual(snapshot.cycleStart, DateParser.iso("2026-08-01T00:00:00Z"))
        XCTAssertEqual(snapshot.cycleEnd, DateParser.iso("2026-09-01T00:00:00Z"))
        XCTAssertEqual(snapshot.forecastWindow?.id, "total")
    }

    func testCursorTinyPercentIsAtLeastOne() {
        XCTAssertEqual(UsageParsers.cursorVisiblePercent(0.4), 1, accuracy: 0.01)
        XCTAssertEqual(UsageParsers.cursorVisiblePercent(0), 0, accuracy: 0.01)
        XCTAssertEqual(UsageParsers.cursorVisiblePercent(12.2), 12.2, accuracy: 0.01)
    }

    func testCopilotChatCompletionsAndEntitlementFallback() throws {
        L10n.language = .en
        let json = try JSONValue.parse(Data("""
        {
          "copilot_plan": "pro+",
          "quota_reset_date": "2026-09-01T00:00:00Z",
          "quota_snapshots": {
            "premium_interactions": { "entitlement": 1500, "remaining": 375 },
            "chat": { "percent_remaining": 80, "unlimited": false },
            "completions": { "unlimited": true, "percent_remaining": 100 }
          }
        }
        """.utf8))
        let snapshot = UsageParsers.copilot(json)
        XCTAssertEqual(snapshot.planName, "pro+")
        XCTAssertEqual(snapshot.windows.count, 2)
        XCTAssertEqual(snapshot.primaryPercent, 75, accuracy: 0.01)
        XCTAssertEqual(snapshot.windows[0].title, "Premium")
        XCTAssertEqual(snapshot.windows[1].title, "Chat")
        XCTAssertEqual(snapshot.windows[1].usedPercent, 20, accuracy: 0.01)
        XCTAssertEqual(snapshot.forecastWindow?.id, "premium")
        XCTAssertNotNil(snapshot.cycleEnd)
    }

    func testCopilotEmptySnapshotsStaySignedInShape() throws {
        let json = try JSONValue.parse(Data("""
        { "copilot_plan": "free", "quota_snapshots": {} }
        """.utf8))
        let snapshot = UsageParsers.copilot(json)
        XCTAssertEqual(snapshot.planName, "free")
        XCTAssertTrue(snapshot.windows.isEmpty)
        XCTAssertEqual(snapshot.primaryPercent, 0, accuracy: 0.01)
    }
}
