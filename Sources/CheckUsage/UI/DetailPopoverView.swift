import SwiftUI

struct DetailPopoverView: View {
    let id: ProviderID
    let state: ProviderLoadState
    var anchor: DetailAnchor = .left
    var pointerY: CGFloat = 0.5
    var onRefresh: () -> Void
    var onOpenDashboard: (() -> Void)? = nil

    var body: some View {
        bubble
            .padding(Theme.chromePad)
    }

    private var bubble: some View {
        HStack(alignment: .center, spacing: 0) {
            if anchor == .right {
                pointer
            }
            VStack(spacing: 0) {
                if anchor == .below { pointer }
                card
                if anchor == .above { pointer }
            }
            if anchor == .left {
                pointer
            }
        }
    }

    private var pointer: some View {
        CalloutPointer(edge: anchor, fill: Theme.popoverFill)
            .offset(pointerOffset)
    }

    private var pointerOffset: CGSize {
        switch anchor {
        case .left, .right:
            return CGSize(width: 0, height: (pointerY - 0.5) * 120)
        case .above, .below:
            return .zero
        }
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            content
        }
        .padding(.horizontal, 18)
        .padding(.top, 16)
        .padding(.bottom, 16)
        .frame(width: Theme.popoverWidth, alignment: .leading)
        .background(Theme.popoverFill, in: RoundedRectangle(cornerRadius: Theme.popoverRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.popoverRadius, style: .continuous)
                .stroke(Theme.hairline, lineWidth: 0.7)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.popoverRadius, style: .continuous)
                .stroke(Color.white.opacity(0.04), lineWidth: 0.7)
                .padding(1)
        )
    }

    private var header: some View {
        HStack(spacing: 9) {
            BrandIcon(id: id, size: 17)
            Text(L10n.format("usage_title", id.displayName))
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Theme.text)
                .tracking(-0.25)
            Spacer(minLength: 0)
            if id.dashboardURL != nil {
                Button {
                    onOpenDashboard?()
                } label: {
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Theme.muted)
                        .frame(width: 22, height: 22)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help(L10n.t("open_dashboard"))
            }
            Button(action: onRefresh) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Theme.muted.opacity(0.85))
                    .frame(width: 22, height: 22)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch state {
        case .ready(let snapshot):
            if let plan = snapshot.planName, !plan.isEmpty {
                Text(L10n.format("plan_label", plan))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Theme.muted)
                    .padding(.top, -8)
            }
            VStack(spacing: 16) {
                ForEach(snapshot.windows.prefix(4)) { window in
                    windowRow(window)
                }
            }
            if SettingsStore.shared.showPace, let card = PaceCardModel.make(from: snapshot) {
                PaceCard(model: card)
            }
            Text(ResetCopy.updated(snapshot.fetchedAt))
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(Theme.muted.opacity(0.72))
        case .signedOut:
            emptyCopy(L10n.t("not_signed_in"), L10n.t("sign_in_hint"))
        case .missingKey:
            emptyCopy(L10n.t("missing_key"), L10n.t("api_key_hint"))
        case .error(let message):
            emptyCopy(message, L10n.t("retry"))
        case .loading, .idle:
            emptyCopy(L10n.t("no_data"), nil)
        }
    }

    private func windowRow(_ window: QuotaWindow) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(window.title)
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundStyle(Theme.text.opacity(0.92))
                Spacer(minLength: 8)
                Text(ResetCopy.format(reset: window.resetsAt))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Theme.muted)
            }
            UsageBar(percent: window.clampedPercent, tone: Theme.tone(window.clampedPercent))
                .padding(.top, 1)
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(L10n.format("percent_used", String(format: "%.0f%%", window.clampedPercent)))
                    .font(.system(size: 13, weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(Theme.text)
                Spacer(minLength: 8)
                if let footnote = window.footnote {
                    Text(footnote)
                        .font(.system(size: 10.5, weight: .medium))
                        .foregroundStyle(footnoteTone(window.footnote))
                        .multilineTextAlignment(.trailing)
                }
            }
            if let hint = window.hint {
                Text(hint)
                    .font(.system(size: 10.5))
                    .foregroundStyle(Theme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func footnoteTone(_ footnote: String?) -> Color {
        guard let footnote else { return Theme.muted }
        let hot = ["over", "сверх", "on-demand", "по запросу"]
        if hot.contains(where: { footnote.localizedCaseInsensitiveContains($0) }) {
            return Theme.warn
        }
        return Theme.muted
    }

    private func emptyCopy(_ title: String, _ subtitle: String?) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Theme.text)
            if let subtitle {
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 6)
    }
}

struct PaceCardModel {
    var cycleLine: String
    var spentLine: String
    var expectedLine: String
    var headline: String
    var tip: String
    var usedPercent: Double
    var expectedPercent: Double
    var tone: Color
    var subscribedLine: String?
    var renewsLine: String?

    @MainActor
    static func make(from snapshot: QuotaSnapshot, now: Date = Date()) -> PaceCardModel? {
        guard let window = snapshot.forecastWindow else { return nil }
        let watch = SettingsStore.shared.watch(for: snapshot)
        let firstSeen = watch.map { Date(timeIntervalSince1970: $0.firstAt) }
        let end = snapshot.cycleEnd ?? window.resetsAt
        guard let forecast = BurnForecast.make(
            usedPercent: window.clampedPercent,
            cycleStart: snapshot.cycleStart,
            cycleEnd: end,
            now: now,
            firstSeen: firstSeen,
            firstPercent: watch?.firstPercent
        ) else { return nil }
        var subscribed: String?
        if let subscribedAt = snapshot.subscribedAt {
            subscribed = L10n.format("subscribed_on", DateCopy.short(subscribedAt))
        }
        return PaceCardModel(
            cycleLine: L10n.format("cycle_range", DateCopy.short(forecast.cycleStart), DateCopy.short(forecast.cycleEnd)),
            spentLine: forecast.spentLine(),
            expectedLine: L10n.format("pace_expected", String(format: "%.0f%%", forecast.expectedPercentByNow)),
            headline: forecast.headline(),
            tip: forecast.tip(),
            usedPercent: forecast.usedPercent,
            expectedPercent: forecast.expectedPercentByNow,
            tone: Theme.toneColor(forecast.tone),
            subscribedLine: subscribed,
            renewsLine: snapshot.subscribedAt == nil
                ? nil
                : L10n.format("renews_on", DateCopy.short(forecast.cycleEnd))
        )
    }
}

struct PaceCard: View {
    let model: PaceCardModel

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(alignment: .firstTextBaseline) {
                Text(L10n.t("pace_title"))
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Theme.muted)
                    .textCase(.uppercase)
                    .tracking(0.7)
                Spacer(minLength: 8)
                Text(model.cycleLine)
                    .font(.system(size: 10.5, weight: .medium))
                    .foregroundStyle(Theme.muted)
            }
            Text(model.spentLine)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.text)
            PaceCompareBar(used: model.usedPercent, expected: model.expectedPercent, tone: model.tone)
            Text(model.expectedLine)
                .font(.system(size: 10.5))
                .foregroundStyle(Theme.muted)
            Text(model.headline)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(model.tone)
                .fixedSize(horizontal: false, vertical: true)
            Text(model.tip)
                .font(.system(size: 11))
                .foregroundStyle(Theme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 11)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.035), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Theme.hairline.opacity(0.7), lineWidth: 0.6)
        )
    }
}

struct PaceCompareBar: View {
    var used: Double
    var expected: Double
    var tone: Color

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Theme.track)
                Capsule()
                    .fill(tone)
                    .frame(width: max(6, width * CGFloat(min(1, max(0, used / 100)))))
                Capsule()
                    .fill(Color.white.opacity(0.88))
                    .frame(width: 2, height: 11)
                    .offset(x: max(0, min(width - 2, width * CGFloat(min(1, max(0, expected / 100))) - 1)))
            }
        }
        .frame(height: 5)
        .accessibilityLabel(L10n.format("pace_expected", String(format: "%.0f%%", expected)))
    }
}
