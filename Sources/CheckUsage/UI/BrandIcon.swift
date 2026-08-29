import AppKit
import SwiftUI

enum BrandImages {
    nonisolated(unsafe) private static var cache: [String: NSImage] = [:]

    static func image(for id: ProviderID) -> NSImage? {
        if let cached = cache[id.rawValue] { return cached }
        guard let url = url(for: id), let loaded = NSImage(contentsOf: url) else { return nil }
        let tinted = tintedWhite(loaded)
        cache[id.rawValue] = tinted
        return tinted
    }

    private static func url(for id: ProviderID) -> URL? {
        let name: String
        switch id {
        case .claude: name = "claude"
        case .codex: name = "openai"
        case .cursor: name = "cursor"
        case .copilot: name = "githubcopilot"
        case .gemini: name = "googlegemini"
        case .grok: name = "grok"
        case .antigravity: name = "antigravity"
        case .opencode: name = "opencode"
        case .openrouter: name = "openrouter"
        case .deepseek: name = "deepseek"
        case .zai: name = "zai"
        }
        let bundle = Bundle.main
        let folders = ["Logos/png", "Logos", "png", nil] as [String?]
        for ext in ["pdf", "png", "svg"] {
            for folder in folders {
                if let folder, let url = bundle.url(forResource: name, withExtension: ext, subdirectory: folder) {
                    return url
                }
                if folder == nil, let url = bundle.url(forResource: name, withExtension: ext) {
                    return url
                }
            }
        }
        return nil
    }

    private static func tintedWhite(_ image: NSImage) -> NSImage {
        let size = NSSize(width: 64, height: 64)
        let output = NSImage(size: size)
        output.lockFocus()
        NSColor.white.set()
        image.draw(in: NSRect(origin: .zero, size: size), from: .zero, operation: .sourceOver, fraction: 1)
        NSRect(origin: .zero, size: size).fill(using: .sourceAtop)
        output.unlockFocus()
        output.isTemplate = true
        return output
    }
}

struct BrandIcon: View {
    let id: ProviderID
    var size: CGFloat = 20

    var body: some View {
        Group {
            if let image = BrandImages.image(for: id) {
                Image(nsImage: image)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
            } else {
                ProviderMark(id: id, size: size)
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}
