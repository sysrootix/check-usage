import Foundation

enum AppInfo {
    static var shortVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
            ?? "1.0.0"
    }

    static let githubURL = URL(string: "https://github.com/sysrootix/check-usage")!
    static let issuesURL = URL(string: "https://github.com/sysrootix/check-usage/issues")!
    static let licenseURL = URL(string: "https://github.com/sysrootix/check-usage/blob/main/LICENSE")!
}
