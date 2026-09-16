## What

<!-- User-visible change in one or two sentences. -->

## Why

<!-- Bug, provider response change, or maintainer hygiene. -->

## How I tested

- [ ] `make test`
- [ ] `make app` (if UI, signing, or the bundle changed)

macOS 14+ / Xcode 16+ required. Linux agents cannot run `xcodebuild`; the `macos-15` CI workflow is the gate.

## Checklist

- [ ] No secrets, tokens, cookies, or Keychain blobs in the diff or screenshots
- [ ] Parser changes include a realistic fixture in `Tests/CheckUsageTests` (no live network)
- [ ] New `L10n` / `ExtraL10n` keys exist in every language table
- [ ] User-facing changes are noted under **Unreleased** in `CHANGELOG.md`
- [ ] I have read [CONTRIBUTING.md](../CONTRIBUTING.md) and [SECURITY.md](../SECURITY.md)
