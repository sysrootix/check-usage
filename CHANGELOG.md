# Changelog

All notable changes to CheckUsage are documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project uses [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Community health files: security policy, Contributor Covenant, issue and pull-request templates
- Architecture notes for contributors (`docs/ARCHITECTURE.md`)
- GitHub Actions release workflow: tag `v*` builds `CheckUsage.app.zip` and attaches it to the GitHub Release
- Settings → About links to the public repository, issue tracker, and license
- Additional offline parser fixtures (Claude, Codex, Cursor, Copilot) and forecast / reset-copy edge cases

### Changed

- CI cancels stale runs, keeps `macos-15` + Makefile as the source of truth, and uploads the built app only from `main`

## [1.0.0] - 2026-08-29

First public release.

### Added

- Native Swift 6 menubar extra for macOS 14+: edge pill with provider rings and a detail popover
- Usage meters for Claude, Codex, Cursor, Copilot, Gemini CLI, Grok, Antigravity, OpenCode, OpenRouter, DeepSeek, and Z.ai / GLM
- Reuses official-app sessions (Keychain / local auth files). No extra login. No telemetry
- Spend-pace card and burn forecast against the billing cycle
- Optional 70% / 90% notifications, remaining percent on rings, menu-bar worst remaining percent
- Widget lock, snap-to-edge, tuck-off-edge, custom hotkeys (`⌥⌘U` / `⌥⌘L` by default)
- UI and docs in English, Russian, Simplified Chinese, Japanese, German, Spanish, French, Brazilian Portuguese, and Korean
- `make test` / `make app` and parser fixtures under `Tests/CheckUsageTests`

[Unreleased]: https://github.com/sysrootix/check-usage/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/sysrootix/check-usage/releases/tag/v1.0.0
