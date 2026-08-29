import XCTest
@testable import CheckUsage

final class SettingsFileTests: XCTestCase {
    private var folder: URL!

    override func setUp() {
        super.setUp()
        folder = FileManager.default.temporaryDirectory.appendingPathComponent("checkusage-settings-\(UUID().uuidString)", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        SettingsFile.overrideURL = folder.appendingPathComponent("settings.json")
    }

    override func tearDown() {
        SettingsFile.overrideURL = nil
        try? FileManager.default.removeItem(at: folder)
        super.tearDown()
    }

    func testRoundTripKeepsScaleAndInset() throws {
        var snapshot = SettingsSnapshot()
        snapshot.widgetScale = 1.3
        snapshot.edgeInset = 18
        snapshot.positionLocked = false
        snapshot.placement = WidgetPlacement.bottomLeading.rawValue
        snapshot.enabled = ["claude": true, "cursor": false]
        try SettingsFile.save(snapshot)

        let loaded = SettingsFile.load()
        XCTAssertEqual(loaded?.widgetScale, 1.3)
        XCTAssertEqual(loaded?.edgeInset, 18)
        XCTAssertEqual(loaded?.positionLocked, false)
        XCTAssertEqual(loaded?.placement, "bottomLeading")
        XCTAssertEqual(loaded?.enabled["cursor"], false)
    }

    func testRoundTripKeepsPaceWatches() throws {
        var snapshot = SettingsSnapshot()
        snapshot.showPace = false
        snapshot.watches = [
            "cursor.total": CycleWatch(cycleEnd: 1_788_220_800, firstAt: 1_785_542_400, firstPercent: 4)
        ]
        try SettingsFile.save(snapshot)
        let loaded = SettingsFile.load()
        XCTAssertEqual(loaded?.showPace, false)
        XCTAssertEqual(loaded?.watches["cursor.total"]?.firstPercent, 4)
        XCTAssertEqual(loaded?.watches["cursor.total"]?.cycleEnd, 1_788_220_800)
    }

    func testMissingFileReturnsNil() {
        XCTAssertNil(SettingsFile.load())
    }

    func testRoundTripKeepsAutoHide() throws {
        var snapshot = SettingsSnapshot()
        snapshot.autoHide = true
        try SettingsFile.save(snapshot)
        XCTAssertEqual(SettingsFile.load()?.autoHide, true)
    }

    func testOldSettingsWithoutAutoHideStillLoad() throws {
        let json = """
        {"version":1,"language":"ru","widgetEnabled":true,"placement":"topTrailing","showPace":true}
        """
        try Data(json.utf8).write(to: SettingsFile.url)
        let loaded = SettingsFile.load()
        XCTAssertEqual(loaded?.language, "ru")
        XCTAssertEqual(loaded?.autoHide, false)
        XCTAssertEqual(loaded?.showPace, true)
    }
}
