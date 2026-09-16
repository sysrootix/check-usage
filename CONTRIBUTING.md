# Contributing

Please be kind. This project follows the [Contributor Covenant](CODE_OF_CONDUCT.md).
Security reports go to **sysrootix@gmail.com** — see [SECURITY.md](SECURITY.md), not a public issue.

Architecture (App / Providers / parsers / credentials / UI) is in [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

## Branch naming

Use a short prefix and a kebab-case topic:

- `fix/cursor-reset-date`
- `feat/provider-name`
- `docs/architecture`
- `test/codex-fixtures`

Fork, push the branch, and open a pull request against `main`.

## Build

Makefile targets are the source of truth (local and CI):

```bash
make test       # regenerate the Xcode project, run unit tests
make app        # Release .app in dist/
make zip        # dist/CheckUsage.app.zip (used by the release workflow)
```

Requires macOS 14+, Xcode 16+ / Swift 6, and [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`).

## Pull request checklist

- [ ] `make test` passes on your Mac
- [ ] `make app` if you touched UI, resources, or the bundle
- [ ] No secrets (see below)
- [ ] Parser or copy changes have fixtures / unit tests
- [ ] New strings are added to **every** language table in `L10n.swift` / `ExtraL10n.swift` (English is the runtime fallback, not an excuse to skip tables)
- [ ] User-facing changes listed under **Unreleased** in [CHANGELOG.md](CHANGELOG.md)

Use the GitHub PR template. Keep commits short and in English; say *why*, not just *what*.

## Never commit secrets

Do not add tokens, cookies, Keychain dumps, `.env`, `auth.json`, `.credentials.json`, `hosts.yml`, `state.vscdb`, or crash logs that show a live credential. Test payloads must be synthetic. CheckUsage must never log tokens.

If you paste a secret by mistake, rotate it at the provider and tell the maintainer privately ([SECURITY.md](SECURITY.md)).

## Add a provider

1. Add a case to `ProviderID`.
2. Parse the JSON in `UsageParsers` — keep network out of the parser.
3. Fetch in `UsageService` using credentials the official app already stored. Do not invent a new login flow unless the provider only has API keys.
4. Add a Simple Icons SVG in `Resources/Logos` and a fallback mark in `ProviderMark`.
5. Add a fixture test with a real-looking payload.
6. Never log tokens, cookies, or Keychain blobs.

New providers that need reverse-engineering a live unofficial API should be discussed in an issue first. Do not attach credentials.

## Localization

Strings live in `L10n.swift` and `ExtraL10n.swift`. Add the same key to every language table. If you skip a language, English is the fallback.

## Cut a release

1. Move **Unreleased** notes in [CHANGELOG.md](CHANGELOG.md) into a new `## [X.Y.Z] - YYYY-MM-DD` section and add compare links.
2. Bump `CFBundleShortVersionString` / `MARKETING_VERSION` and `CFBundleVersion` / `CURRENT_PROJECT_VERSION` in `Resources/Info.plist` and `project.yml`.
3. Merge to `main`.
4. Tag and push:

```bash
git tag v1.x.x
git push origin v1.x.x
```

(`git push origin main --tags` also works.)

5. [`.github/workflows/release.yml`](.github/workflows/release.yml) runs on `v*` tags: `make zip`, then creates the GitHub Release if it is missing and attaches `CheckUsage.app.zip`.

The public build is **ad-hoc signed**. Notarization / Developer ID is out of scope until an Apple Developer account is configured for this repo.
