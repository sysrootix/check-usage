import XCTest
@testable import CheckUsage

final class AppInfoTests: XCTestCase {
    override func tearDown() {
        L10n.language = .en
        super.tearDown()
    }

    func testPublicLinksStayOnGitHub() {
        XCTAssertEqual(AppInfo.githubURL.host, "github.com")
        XCTAssertEqual(AppInfo.githubURL.path, "/sysrootix/check-usage")
        XCTAssertEqual(AppInfo.issuesURL.path, "/sysrootix/check-usage/issues")
        XCTAssertTrue(AppInfo.licenseURL.path.hasSuffix("/LICENSE"))
        XCTAssertFalse(AppInfo.shortVersion.isEmpty)
    }

    func testAboutKeysExistInEveryLanguage() {
        let keys = ["github_repo", "github_issues", "github_license"]
        for language in [AppLanguage.en, .ru, .zhHans, .ja, .de, .es, .fr, .ptBR, .ko] {
            L10n.language = language
            for key in keys {
                let value = L10n.t(key)
                XCTAssertNotEqual(value, key, "missing \(key) for \(language.rawValue)")
                XCTAssertFalse(value.isEmpty)
            }
        }
        L10n.language = .en
    }
}