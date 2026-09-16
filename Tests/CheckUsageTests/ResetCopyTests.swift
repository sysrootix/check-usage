import XCTest
@testable import CheckUsage

final class ResetCopyTests: XCTestCase {
    override func setUp() {
        super.setUp()
        L10n.language = .en
    }

    func testHoursStayRelative() {
        let now = Date(timeIntervalSince1970: 1_782_950_400)
        let text = ResetCopy.format(reset: now.addingTimeInterval(5 * 3600 + 20 * 60), now: now)
        XCTAssertTrue(text.contains("5"), text)
        XCTAssertFalse(text.contains("Sat"), text)
    }

    func testFewDaysUsesDayCount() {
        let now = Date(timeIntervalSince1970: 1_782_950_400)
        let text = ResetCopy.format(reset: now.addingTimeInterval(3 * 86400 + 3600), now: now)
        XCTAssertTrue(text.contains("3"), text)
        XCTAssertFalse(text.contains("Sat"), text)
        XCTAssertFalse(text.contains("Mon"), text)
    }

    func testMonthAwayUsesCalendarDate() {
        let now = Date(timeIntervalSince1970: 1_782_950_400)
        let text = ResetCopy.format(reset: now.addingTimeInterval(28 * 86400), now: now)
        XCTAssertFalse(text.contains("Sat"), text)
        XCTAssertFalse(text.contains("Friday"), text)
        XCTAssertTrue(text.contains("Jul") || text.contains("July") || text.contains("30"), text)
    }

    func testCursorCyclePrefersPlanEnd() throws {
        let usage = try JSONValue.parse(Data(#"{ "planUsage": { "totalPercentUsed": 11 } }"#.utf8))
        let plan = try JSONValue.parse(Data(#"{ "planInfo": { "billingCycleEnd": 1785542400000 } }"#.utf8))
        let now = Date(timeIntervalSince1970: 1_782_950_400)
        let end = UsageParsers.cursorCycleEnd(usageJSON: usage, plan: plan, now: now)
        XCTAssertEqual(end?.timeIntervalSince1970 ?? 0, 1_785_542_400, accuracy: 1)
    }

    func testCompactResetOnlyForShortWindows() {
        let now = Date(timeIntervalSince1970: 1_782_950_400)
        XCTAssertEqual(ResetCopy.compact(reset: now.addingTimeInterval(51 * 60), now: now), "51m")
        XCTAssertEqual(ResetCopy.compact(reset: now.addingTimeInterval(3 * 3600), now: now), "3h")
        XCTAssertNil(ResetCopy.compact(reset: now.addingTimeInterval(2 * 86400), now: now))
    }

    func testPastCycleBumpsAMonth() {
        let now = Date(timeIntervalSince1970: 1_782_950_400)
        let past = now.addingTimeInterval(-12 * 86400)
        let next = UsageParsers.upcomingMonthly(past, now: now)
        XCTAssertGreaterThan(next, now)
        XCTAssertLessThan(next.timeIntervalSince(now), 40 * 86400)
    }

    func testPastResetAsksToRefresh() {
        let now = Date(timeIntervalSince1970: 1_782_950_400)
        XCTAssertEqual(ResetCopy.format(reset: now.addingTimeInterval(-60), now: now), "Refresh")
        XCTAssertNil(ResetCopy.compact(reset: now.addingTimeInterval(-60), now: now))
    }

    func testMissingResetCopy() {
        XCTAssertEqual(ResetCopy.format(reset: nil), "No reset time")
        XCTAssertNil(ResetCopy.compact(reset: nil))
    }

    func testMinutesStayRelative() {
        let now = Date(timeIntervalSince1970: 1_782_950_400)
        let text = ResetCopy.format(reset: now.addingTimeInterval(45 * 60), now: now)
        XCTAssertTrue(text.contains("45"), text)
        XCTAssertTrue(text.lowercased().contains("min"), text)
    }

    func testCompactBoundaryIsSixHours() {
        let now = Date(timeIntervalSince1970: 1_782_950_400)
        XCTAssertEqual(ResetCopy.compact(reset: now.addingTimeInterval(30), now: now), "1m")
        XCTAssertEqual(ResetCopy.compact(reset: now.addingTimeInterval(5 * 3600 + 59 * 60), now: now), "5h")
        XCTAssertNil(ResetCopy.compact(reset: now.addingTimeInterval(6 * 3600), now: now))
    }

    func testUpdatedJustNowAndHours() {
        let now = Date(timeIntervalSince1970: 1_782_950_400)
        XCTAssertEqual(ResetCopy.updated(now.addingTimeInterval(-20), now: now), "Just now")
        let hours = ResetCopy.updated(now.addingTimeInterval(-3 * 3600), now: now)
        XCTAssertTrue(hours.contains("3"), hours)
    }
}
