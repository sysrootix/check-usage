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
}
