# CheckUsage

**Language:** [English](README.md) · [Русский](docs/i18n/ru.md) · [简体中文](docs/i18n/zh-Hans.md) · [日本語](docs/i18n/ja.md) · [Deutsch](docs/i18n/de.md) · [Español](docs/i18n/es.md) · [Français](docs/i18n/fr.md) · [Português (Brasil)](docs/i18n/pt-BR.md) · [한국어](docs/i18n/ko.md)

Usage limits for the AI tools already signed in on your Mac — a slim **edge pill** with circular rings, plus a detail popover. No extra login. No telemetry.

<p align="center">
  <img src="docs/screenshot.jpg" alt="CheckUsage pill and Cursor limits popover" width="720">
</p>

CheckUsage lives in the menu bar and can pin a dark pill to any screen edge. Each ring is a real provider mark. Hover a ring to peek at the windows; click to pin. The popover shows session / weekly / plan usage, when it resets, and a spend-pace card: how much of the cycle is gone, whether you’re ahead of the plan, and the date this rate would empty the limit.

**Defaults:** widget top-right and **locked**, close on outside click, `⌥⌘U` toggles the widget, `⌥⌘L` opens the last limits. Unlock to drag; it snaps to an edge. Cursor’s reset is the monthly billing date, not “this Saturday”.

## What it is

A glanceable instrument for people who run several AI coding agents on one Mac. Worst remaining percent can sit in the menu bar. Rings sit on the edge. Details open on hover or click. It is not a cost ledger and it does not scrape local chat transcripts.

## What it reads

| Provider | Source of truth | Sign-in it reuses |
|---|---|---|
| Claude | `GET /api/oauth/usage` | Claude Code Keychain |
| Codex | ChatGPT `wham/usage` | `~/.codex/auth.json` or Codex Keychain |
| Cursor | Dashboard `GetCurrentPeriodUsage` | Cursor `state.vscdb` / CLI Keychain |
| Copilot | GitHub `copilot_internal/user` | `gh` / Copilot editor token |
| Gemini CLI | Cloud Code `retrieveUserQuota` | `~/.gemini/oauth_creds.json` |
| Grok | CLI billing proxy | `~/.grok/auth.json` |
| Antigravity | Cloud Code quota summary | Keychain `gemini` / `antigravity` |
| OpenCode | OpenCode Go usage | `~/.local/share/opencode/auth.json` |
| OpenRouter | Official `/credits` + `/key` | API key in Settings |
| DeepSeek | Official `/user/balance` | API key in Settings |
| Z.ai / GLM | Quota limit endpoint | API key in Settings |

Signed-out tools stay hidden unless you turn on **Show signed-out tools**.

Most subscription meters are **unofficial** endpoints the official apps already call. They can change without notice. OpenRouter, DeepSeek, and Z.ai use documented APIs.

## Requirements

- macOS 14 or later
- Xcode 16+ / Swift 6 (to build from source)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)
- The official CLIs or apps already signed in for the tools you care about

## Install

### Option A — GitHub Release

1. Open the latest [Release](https://github.com/sysrootix/check-usage/releases).
2. Download `CheckUsage.app.zip`, unzip, drag **CheckUsage** to `/Applications`.
3. First launch: right-click the app → **Open** (ad-hoc signed). macOS may ask for network and Keychain access — choose **Always Allow** for the Claude / `gh` items so the panel can refresh in the background.

### Option B — Build from source

```bash
git clone https://github.com/sysrootix/check-usage.git
cd check-usage
make app
open dist/CheckUsage.app
```

Drag `dist/CheckUsage.app` to `/Applications` if you want **Open at login**.

## First run

1. Keep the official CLIs/apps signed in (Claude Code, Cursor, `gh auth login`, `codex login`, …).
2. Launch CheckUsage. Rings appear for whatever is already authenticated.
3. Hover a ring for a peek. Click to pin. Click the desktop or press Escape to close (or keep it sticky in Settings).
4. The `↗` button in the popover opens that provider’s dashboard.
5. Right-click the pill, or use the menu bar item, for Settings / refresh / quit.
6. Unlock to drag the pill to another edge. `⌥⌘U` hides it; `⌥⌘L` opens the last limits even if the pill is off.

Short reset copy (`51m`, `3h`) appears on a ring only when that window is under six hours. Rings pulse from 90%. Optional notifications fire at 70% and 90% once per billing cycle.

## Languages

The UI follows the system language, or a lock in Settings:

English · Русский · 简体中文 · 日本語 · Deutsch · Español · Français · Português (Brasil) · 한국어

## Settings

- Show or hide the desktop widget (menu bar + hotkeys still work)
- Tuck the widget off the edge (a peek tab stays; hover to slide it out)
- Position: any edge or corner
- Vertical or horizontal layout
- Size and edge inset
- Lock the widget so a click or hold does not move it
- Snap to edges, or drop it at a free position
- Close the limit window on outside click, or keep it sticky
- Spend pace and forecast
- Optional 70% / 90% notifications
- Remaining % on rings, opacity
- Global hotkeys (record your own)
- Enable / disable providers
- Language
- Refresh interval (30–300s)
- Show signed-out tools
- Percent in the menu bar
- Open at login
- OpenRouter / DeepSeek / Z.ai keys

## Privacy

- Tokens never leave this Mac except to the provider that issued them.
- CheckUsage does not refresh OAuth tokens that belong to Claude Code / Codex / Cursor. If a session expires, sign in again in the official app.
- API keys you paste are stored in the Keychain service `app.checkusage.secrets`.
- No analytics, crash reporters, or accounts.
- Settings live in `~/Library/Application Support/CheckUsage/settings.json`. Reinstalling the app does not delete that file.

## Development

```bash
make project    # regenerate CheckUsage.xcodeproj
make test
make app        # release .app in dist/
```

Parser fixtures live in `Tests/CheckUsageTests`. Provider HTTP is isolated in `UsageService`; JSON shapes are covered without hitting the network.

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

MIT. Provider names and marks belong to their owners. Panel marks use [Simple Icons](https://simpleicons.org) SVGs for identification.
