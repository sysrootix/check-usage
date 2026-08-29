import AppKit
import Foundation

let sizes = [16, 32, 64, 128, 256, 512, 1024]
let out = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "Resources/Assets.xcassets/AppIcon.appiconset")

func draw(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()
    let rect = NSRect(x: 0, y: 0, width: size, height: size)
    let radius = size * 0.22
    NSColor(calibratedRed: 0.08, green: 0.08, blue: 0.09, alpha: 1).setFill()
    NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius).fill()

    let inset = size * 0.16
    let ring = NSBezierPath(ovalIn: rect.insetBy(dx: inset, dy: inset))
    ring.lineWidth = max(1.2, size * 0.07)
    NSColor(calibratedRed: 1, green: 0.55, blue: 0.18, alpha: 1).setStroke()
    ring.stroke()

    let star = NSBezierPath()
    let c = NSPoint(x: size / 2, y: size / 2)
    let outer = size * 0.22
    let inner = size * 0.08
    for i in 0..<8 {
        let angle = Double(i) * .pi / 4 - .pi / 2
        let radius = i.isMultiple(of: 2) ? outer : inner
        let point = NSPoint(x: c.x + CGFloat(cos(angle)) * radius, y: c.y + CGFloat(sin(angle)) * radius)
        if i == 0 { star.move(to: point) } else { star.line(to: point) }
    }
    star.close()
    NSColor.white.setFill()
    star.fill()
    image.unlockFocus()
    return image
}

func write(_ image: NSImage, size: Int, to url: URL) {
    let scaled = NSImage(size: NSSize(width: size, height: size))
    scaled.lockFocus()
    image.draw(in: NSRect(x: 0, y: 0, width: size, height: size))
    scaled.unlockFocus()
    guard let tiff = scaled.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff),
          let png = rep.representation(using: .png, properties: [:]) else { return }
    try? png.write(to: url)
}

try? FileManager.default.createDirectory(at: out, withIntermediateDirectories: true)
let master = draw(size: 1024)
for size in sizes {
    write(master, size: size, to: out.appendingPathComponent("icon_\(size).png"))
}

let iconset = FileManager.default.temporaryDirectory.appendingPathComponent("CheckUsage.iconset")
try? FileManager.default.removeItem(at: iconset)
try? FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)
try? FileManager.default.copyItem(at: out.appendingPathComponent("icon_16.png"), to: iconset.appendingPathComponent("icon_16x16.png"))
try? FileManager.default.copyItem(at: out.appendingPathComponent("icon_32.png"), to: iconset.appendingPathComponent("icon_16x16@2x.png"))
try? FileManager.default.copyItem(at: out.appendingPathComponent("icon_32.png"), to: iconset.appendingPathComponent("icon_32x32.png"))
try? FileManager.default.copyItem(at: out.appendingPathComponent("icon_64.png"), to: iconset.appendingPathComponent("icon_32x32@2x.png"))
try? FileManager.default.copyItem(at: out.appendingPathComponent("icon_128.png"), to: iconset.appendingPathComponent("icon_128x128.png"))
try? FileManager.default.copyItem(at: out.appendingPathComponent("icon_256.png"), to: iconset.appendingPathComponent("icon_128x128@2x.png"))
try? FileManager.default.copyItem(at: out.appendingPathComponent("icon_256.png"), to: iconset.appendingPathComponent("icon_256x256.png"))
try? FileManager.default.copyItem(at: out.appendingPathComponent("icon_512.png"), to: iconset.appendingPathComponent("icon_256x256@2x.png"))
try? FileManager.default.copyItem(at: out.appendingPathComponent("icon_512.png"), to: iconset.appendingPathComponent("icon_512x512.png"))
try? FileManager.default.copyItem(at: out.appendingPathComponent("icon_1024.png"), to: iconset.appendingPathComponent("icon_512x512@2x.png"))
let icns = out.deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("AppIcon.icns")
let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
process.arguments = ["-c", "icns", iconset.path, "-o", icns.path]
try? process.run()
process.waitUntilExit()
print("icons -> \(out.path)")
