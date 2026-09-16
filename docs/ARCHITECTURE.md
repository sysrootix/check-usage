# Architecture

CheckUsage is a single macOS app target (`LSUIElement` — no Dock icon) plus a unit-test bundle. XcodeGen generates `CheckUsage.xcodeproj` from [`project.yml`](../project.yml). **Makefile targets are the source of truth** for local and CI builds (`make test`, `make app`, `make zip`).

```
Sources/CheckUsage
├── App/          lifecycle, menubar extra, refresh loop, panel chrome
├── Providers/    HTTP fetch + credential lookup; pure JSON parsers
├── Services/     Keychain/files, HTTP, settings, hotkeys, alerts
├── Models/       ProviderID, snapshots, burn forecast, layout math
├── UI/           edge pill, detail popover, Settings
└── L10n/         string tables (system language or a Settings lock)
```

## App

- [`CheckUsageApp`](../Sources/CheckUsage/App/CheckUsageApp.swift) — `MenuBarExtra`, accessory activation policy
- [`AppModel`](../Sources/CheckUsage/App/AppModel.swift) — enabled providers, refresh timer, worst remaining percent
- [`PanelController`](../Sources/CheckUsage/App/PanelController.swift) / [`WidgetChrome`](../Sources/CheckUsage/App/WidgetChrome.swift) — borderless edge window and popover placement

The app never scrapes local chat transcripts. It only asks each provider’s usage endpoint and renders the result.

## Providers

[`UsageService`](../Sources/CheckUsage/Providers/UsageService.swift) is the only type that talks to the network. For each `ProviderID` it:

1. Reads credentials that the **official app or CLI already stored** (or a key the user pasted in Settings)
2. Calls that provider’s usage URL
3. Hands the JSON to [`UsageParsers`](../Sources/CheckUsage/Providers/UsageParsers.swift)

Parsers are pure: `JSONValue` in, `QuotaSnapshot` out. No `URLSession`, no Keychain. That is why tests can cover Claude / Cursor / Codex / Copilot shapes without live network.

Most subscription meters use **unofficial** endpoints the official clients already call. They can change without notice. OpenRouter, DeepSeek, and Z.ai use documented APIs.

## Credentials (never stored anew for CLI sessions)

[`SecretStore`](../Sources/CheckUsage/Services/SecretStore.swift) only **reads** existing material:

| Provider | Where the token comes from |
|---|---|
| Claude | Keychain `Claude Code-credentials` or `~/.claude/.credentials.json` |
| Codex | `~/.codex/auth.json` or Keychain `Codex Auth` |
| Cursor | `state.vscdb` (`cursorAuth/accessToken`) or Keychain `cursor-access-token` |
| Copilot | `GH_TOKEN` / `~/.config/github-copilot/apps.json` / `gh` hosts.yml / Keychain `gh:github.com` |
| Gemini | `~/.gemini/oauth_creds.json` or Keychain `gemini-cli-oauth` |
| Grok | `~/.grok/auth.json` |
| Antigravity | Keychain `gemini` / `antigravity` (falls back to Gemini) |
| OpenCode | `~/.local/share/opencode/auth.json` |
| OpenRouter, DeepSeek, Z.ai | Keychain service `app.checkusage.secrets` (user-pasted in Settings) |

CheckUsage does **not** refresh OAuth tokens that belong to Claude Code / Codex / Cursor. If a session expires, sign in again in the official app. Tokens are sent only to the issuer. Never log them.

Settings themselves live in `~/Library/Application Support/CheckUsage/settings.json` ([`SettingsFile`](../Sources/CheckUsage/Services/SettingsFile.swift) / [`SettingsStore`](../Sources/CheckUsage/Services/SettingsStore.swift)). Reinstalling the `.app` does not delete that file.

## UI / Settings

- [`EdgePanelView`](../Sources/CheckUsage/UI/EdgePanelView.swift) — rings on the screen edge
- [`DetailPopoverView`](../Sources/CheckUsage/UI/DetailPopoverView.swift) — session / weekly / plan windows, reset copy, spend-pace card
- [`SettingsView`](../Sources/CheckUsage/UI/SettingsView.swift) — widget, providers, hotkeys, API keys, About

About shows `CFBundleShortVersionString` from the bundle (see [`AppInfo`](../Sources/CheckUsage/App/AppInfo.swift)) and links to GitHub, Issues, and the license.

Forecast math is isolated in [`BurnForecast`](../Sources/CheckUsage/Models/BurnForecast.swift). Reset phrasing is [`ResetCopy`](../Sources/CheckUsage/L10n/L10n.swift).

## Adding a provider

Follow [CONTRIBUTING.md](../CONTRIBUTING.md): new `ProviderID`, parser + fixture (no network), fetch in `UsageService` using credentials the official app already stored, Simple Icons SVG, no token logging.

## Tests

`Tests/CheckUsageTests` covers parsers, forecast, reset copy, settings file I/O, and layout math. Run `make test` on a Mac with Xcode 16+. Linux CI cannot run `xcodebuild`; GitHub Actions on `macos-15` is the gate.
