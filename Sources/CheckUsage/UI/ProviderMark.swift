import SwiftUI

struct ProviderMark: View {
    let id: ProviderID
    var size: CGFloat = 20

    var body: some View {
        Canvas { context, canvasSize in
            let rect = CGRect(origin: .zero, size: canvasSize)
            draw(id, in: &context, rect: rect)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }

    private func draw(_ id: ProviderID, in context: inout GraphicsContext, rect: CGRect) {
        let color = Color.white
        switch id {
        case .claude:
            var star = Path()
            let c = CGPoint(x: rect.midX, y: rect.midY)
            let outer = rect.width * 0.48
            let inner = rect.width * 0.18
            for i in 0..<8 {
                let angle = Double(i) * .pi / 4 - .pi / 2
                let radius = i.isMultiple(of: 2) ? outer : inner
                let point = CGPoint(x: c.x + CGFloat(cos(angle)) * radius, y: c.y + CGFloat(sin(angle)) * radius)
                if i == 0 { star.move(to: point) } else { star.addLine(to: point) }
            }
            star.closeSubpath()
            context.fill(star, with: .color(color))
        case .codex:
            var swirl = Path()
            let c = CGPoint(x: rect.midX, y: rect.midY)
            for i in 0..<3 {
                let start = Double(i) * 2.2
                swirl.addArc(
                    center: c,
                    radius: rect.width * (0.16 + CGFloat(i) * 0.12),
                    startAngle: .radians(start),
                    endAngle: .radians(start + 4.0),
                    clockwise: false
                )
            }
            context.stroke(swirl, with: .color(color), style: StrokeStyle(lineWidth: 1.7, lineCap: .round))
        case .cursor:
            var diamond = Path()
            let inset = rect.insetBy(dx: rect.width * 0.18, dy: rect.height * 0.10)
            diamond.move(to: CGPoint(x: inset.midX, y: inset.minY))
            diamond.addLine(to: CGPoint(x: inset.maxX, y: inset.midY))
            diamond.addLine(to: CGPoint(x: inset.midX, y: inset.maxY))
            diamond.addLine(to: CGPoint(x: inset.minX, y: inset.midY))
            diamond.closeSubpath()
            context.stroke(diamond, with: .color(color), style: StrokeStyle(lineWidth: 1.6, lineJoin: .round))
            var inner = Path()
            let small = inset.insetBy(dx: 4, dy: 5)
            inner.move(to: CGPoint(x: small.midX, y: small.minY))
            inner.addLine(to: CGPoint(x: small.maxX, y: small.midY))
            inner.addLine(to: CGPoint(x: small.midX, y: small.maxY))
            inner.addLine(to: CGPoint(x: small.minX, y: small.midY))
            inner.closeSubpath()
            context.stroke(inner, with: .color(color.opacity(0.7)), style: StrokeStyle(lineWidth: 1.2))
        case .copilot:
            let left = Path(ellipseIn: CGRect(x: rect.minX + 1, y: rect.midY - 6, width: 9, height: 12))
            let right = Path(ellipseIn: CGRect(x: rect.maxX - 10, y: rect.midY - 6, width: 9, height: 12))
            context.stroke(left, with: .color(color), lineWidth: 1.6)
            context.stroke(right, with: .color(color), lineWidth: 1.6)
        case .gemini:
            var spark = Path()
            let c = CGPoint(x: rect.midX, y: rect.midY)
            for i in 0..<4 {
                let angle = Double(i) * .pi / 2
                let tip = CGPoint(x: c.x + CGFloat(cos(angle)) * rect.width * 0.46, y: c.y + CGFloat(sin(angle)) * rect.width * 0.46)
                spark.move(to: c)
                spark.addLine(to: tip)
            }
            context.stroke(spark, with: .color(color), style: StrokeStyle(lineWidth: 1.8, lineCap: .round))
        case .grok:
            var x = Path()
            x.move(to: CGPoint(x: rect.minX + 4, y: rect.minY + 4))
            x.addLine(to: CGPoint(x: rect.maxX - 4, y: rect.maxY - 4))
            x.move(to: CGPoint(x: rect.maxX - 4, y: rect.minY + 4))
            x.addLine(to: CGPoint(x: rect.minX + 4, y: rect.maxY - 4))
            context.stroke(x, with: .color(color), style: StrokeStyle(lineWidth: 2, lineCap: .round))
        case .antigravity:
            var a = Path()
            a.move(to: CGPoint(x: rect.midX, y: rect.minY + 2))
            a.addLine(to: CGPoint(x: rect.minX + 3, y: rect.maxY - 2))
            a.move(to: CGPoint(x: rect.midX, y: rect.minY + 2))
            a.addLine(to: CGPoint(x: rect.maxX - 3, y: rect.maxY - 2))
            a.move(to: CGPoint(x: rect.minX + 7, y: rect.midY + 3))
            a.addLine(to: CGPoint(x: rect.maxX - 7, y: rect.midY + 3))
            context.stroke(a, with: .color(color), style: StrokeStyle(lineWidth: 1.6, lineCap: .round))
        case .opencode:
            context.stroke(Path(roundedRect: rect.insetBy(dx: 3, dy: 3), cornerRadius: 3), with: .color(color), lineWidth: 1.5)
            context.stroke(Path(CGRect(x: rect.midX - 3, y: rect.midY - 3, width: 6, height: 6)), with: .color(color), lineWidth: 1.2)
        case .openrouter:
            var arrows = Path()
            arrows.move(to: CGPoint(x: rect.minX + 3, y: rect.midY))
            arrows.addLine(to: CGPoint(x: rect.maxX - 3, y: rect.midY))
            arrows.move(to: CGPoint(x: rect.maxX - 8, y: rect.midY - 5))
            arrows.addLine(to: CGPoint(x: rect.maxX - 3, y: rect.midY))
            arrows.addLine(to: CGPoint(x: rect.maxX - 8, y: rect.midY + 5))
            context.stroke(arrows, with: .color(color), style: StrokeStyle(lineWidth: 1.6, lineCap: .round, lineJoin: .round))
        case .deepseek:
            context.stroke(Path(ellipseIn: rect.insetBy(dx: 3, dy: 3)), with: .color(color), lineWidth: 1.6)
            context.fill(Path(ellipseIn: CGRect(x: rect.midX - 2, y: rect.midY - 2, width: 4, height: 4)), with: .color(color))
        case .zai:
            var z = Path()
            z.move(to: CGPoint(x: rect.minX + 4, y: rect.minY + 5))
            z.addLine(to: CGPoint(x: rect.maxX - 4, y: rect.minY + 5))
            z.addLine(to: CGPoint(x: rect.minX + 4, y: rect.maxY - 5))
            z.addLine(to: CGPoint(x: rect.maxX - 4, y: rect.maxY - 5))
            context.stroke(z, with: .color(color), style: StrokeStyle(lineWidth: 1.7, lineCap: .round, lineJoin: .round))
        }
    }
}

struct UsageRing: View {
    let percent: Double
    let tone: Color
    var empty: Bool = false
    var size: CGFloat = Theme.ringSize
    var selected: Bool = false

    @State private var pulse = false

    var body: some View {
        let stroke = max(3.2, size * 0.088)
        let progress = empty ? 0 : CGFloat(min(1, max(0, percent / 100)))
        let critical = !empty && percent >= 90
        return ZStack {
            Circle()
                .stroke(Color.white.opacity(0.045), lineWidth: stroke + 2.4)
            Circle()
                .stroke(Theme.track, lineWidth: stroke)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    tone.opacity(empty ? 0.22 : 1),
                    style: StrokeStyle(lineWidth: stroke, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: empty ? .clear : tone.opacity(critical && pulse ? 0.88 : 0.5), radius: critical && pulse ? 8 : 5, y: 0)
                .animation(.easeOut(duration: 0.55), value: percent)
            if selected {
                Circle()
                    .stroke(Color.white.opacity(0.16), lineWidth: 1)
                    .padding(-4)
            }
        }
        .frame(width: size, height: size)
        .onAppear { startPulse(critical) }
        .onChange(of: percent) { _, _ in
            startPulse(critical)
        }
    }

    private func startPulse(_ critical: Bool) {
        if critical {
            withAnimation(.easeInOut(duration: 1.05).repeatForever(autoreverses: true)) {
                pulse = true
            }
        } else {
            withAnimation(.easeOut(duration: 0.2)) {
                pulse = false
            }
        }
    }
}

struct UsageBar: View {
    let percent: Double
    let tone: Color

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Theme.track)
                Capsule()
                    .fill(tone)
                    .frame(width: max(5, geo.size.width * CGFloat(min(1, max(0, percent / 100)))))
                    .shadow(color: tone.opacity(0.35), radius: 3, y: 0)
                    .animation(.easeOut(duration: 0.5), value: percent)
            }
        }
        .frame(height: 4)
    }
}
