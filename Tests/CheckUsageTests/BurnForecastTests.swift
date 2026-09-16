import XCTest
@testable import CheckUsage

final class BurnForecastTests: XCTestCase {
    func testTenPercentFirstDayBurnsThroughMonthly() {
        let now = Date(timeIntervalSince1970: 1_788_249_600)
        let start = now.addingTimeInterval(-1 * 86400)
        let end = now.addingTimeInterval(29 * 86400)
        let forecast = BurnForecast.make(usedPercent: 10, cycleStart: start, cycleEnd: end, now: now)
        XCTAssertEqual(forecast?.kind, .burning)
        XCTAssertEqual(forecast?.dailyBurn ?? 0, 10, accuracy: 0.2)
        XCTAssertNotNil(forecast?.projectedEmpty)
        XCTAssertLessThan(forecast!.projectedEmpty!, end.addingTimeInterval(-2 * 86400))
    }

    func testTenPercentHalfwayIsComfortable() {
        let now = Date(timeIntervalSince1970: 1_788_249_600)
        let start = now.addingTimeInterval(-15 * 86400)
        let end = now.addingTimeInterval(15 * 86400)
        let forecast = BurnForecast.make(usedPercent: 10, cycleStart: start, cycleEnd: end, now: now)
        XCTAssertEqual(forecast?.kind, .comfortable)
    }

    func testNearlyEmptyIsDepleted() {
        let now = Date(timeIntervalSince1970: 1_788_249_600)
        let start = now.addingTimeInterval(-10 * 86400)
        let end = now.addingTimeInterval(20 * 86400)
        let forecast = BurnForecast.make(usedPercent: 99, cycleStart: start, cycleEnd: end, now: now)
        XCTAssertEqual(forecast?.kind, .depleted)
        XCTAssertNotNil(forecast?.projectedEmpty)
    }

    func testTinySampleIsUnknown() {
        let now = Date(timeIntervalSince1970: 1_788_249_600)
        let start = now.addingTimeInterval(-6 * 3600)
        let end = now.addingTimeInterval(29 * 86400)
        let forecast = BurnForecast.make(usedPercent: 1.0, cycleStart: start, cycleEnd: end, now: now)
        XCTAssertEqual(forecast?.kind, .unknown)
    }

    func testInferredStartUsesWeekWhenEndIsClose() {
        let now = Date(timeIntervalSince1970: 1_788_249_600)
        let end = now.addingTimeInterval(6 * 86400)
        let start = BurnForecast.inferredStart(end: end, now: now)
        XCTAssertEqual(start.timeIntervalSince(end), -7 * 86400, accuracy: 1)
    }

    func testPastCycleReturnsNil() {
        let now = Date(timeIntervalSince1970: 1_788_249_600)
        let start = now.addingTimeInterval(-40 * 86400)
        let end = now.addingTimeInterval(-2 * 86400)
        XCTAssertNil(BurnForecast.make(usedPercent: 40, cycleStart: start, cycleEnd: end, now: now))
    }

    func testHalfwayFiftyPercentIsOnTrack() {
        let now = Date(timeIntervalSince1970: 1_788_249_600)
        let start = now.addingTimeInterval(-15 * 86400)
        let end = now.addingTimeInterval(15 * 86400)
        let forecast = BurnForecast.make(usedPercent: 50, cycleStart: start, cycleEnd: end, now: now)
        XCTAssertEqual(forecast?.kind, .onTrack)
        XCTAssertEqual(forecast?.expectedPercentByNow ?? 0, 50, accuracy: 3)
        XCTAssertEqual(forecast?.tone, .good)
    }

    func testHalfwaySeventyPercentIsHot() {
        let now = Date(timeIntervalSince1970: 1_788_249_600)
        let start = now.addingTimeInterval(-15 * 86400)
        let end = now.addingTimeInterval(15 * 86400)
        let forecast = BurnForecast.make(usedPercent: 70, cycleStart: start, cycleEnd: end, now: now)
        XCTAssertEqual(forecast?.kind, .hot)
        XCTAssertEqual(forecast?.tone, .warn)
        XCTAssertNotNil(forecast?.projectedEmpty)
    }

    func testObservedDeltaWithoutCycleStart() {
        let now = Date(timeIntervalSince1970: 1_788_249_600)
        let firstSeen = now.addingTimeInterval(-2 * 86400)
        let end = now.addingTimeInterval(28 * 86400)
        let forecast = BurnForecast.make(
            usedPercent: 20,
            cycleStart: nil,
            cycleEnd: end,
            now: now,
            firstSeen: firstSeen,
            firstPercent: 5
        )
        XCTAssertNotNil(forecast)
        XCTAssertEqual(forecast?.dailyBurn ?? 0, 7.5, accuracy: 0.2)
    }

    func testInferredStartUsesFiveHourWindow() {
        let now = Date(timeIntervalSince1970: 1_788_249_600)
        let end = now.addingTimeInterval(4 * 3600)
        let start = BurnForecast.inferredStart(end: end, now: now)
        XCTAssertEqual(start.timeIntervalSince(end), -5 * 3600, accuracy: 1)
    }

    func testCycleEndedWithinGraceStillForecasts() {
        let now = Date(timeIntervalSince1970: 1_788_249_600)
        let start = now.addingTimeInterval(-30 * 86400)
        let end = now.addingTimeInterval(-20 * 60)
        let forecast = BurnForecast.make(usedPercent: 40, cycleStart: start, cycleEnd: end, now: now)
        XCTAssertNotNil(forecast)
    }

    func testExactlyEmptyMarksDepletedNow() {
        let now = Date(timeIntervalSince1970: 1_788_249_600)
        let start = now.addingTimeInterval(-10 * 86400)
        let end = now.addingTimeInterval(20 * 86400)
        let forecast = BurnForecast.make(usedPercent: 100, cycleStart: start, cycleEnd: end, now: now)
        XCTAssertEqual(forecast?.kind, .depleted)
        XCTAssertEqual(forecast?.projectedEmpty, now)
        XCTAssertEqual(forecast?.tone, .critical)
    }
}
