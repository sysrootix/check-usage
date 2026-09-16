# Security policy

## Reporting a vulnerability

Please report security issues **privately** to **sysrootix@gmail.com**.

Do not open a public GitHub issue, pull request, or discussion that includes:

- access tokens, refresh tokens, cookies, or API keys
- Keychain dumps or `security find-generic-password` output
- contents of `auth.json`, `.credentials.json`, `hosts.yml`, or `state.vscdb`
- crash logs or screenshots that show a live credential

Include enough detail to reproduce the issue (affected version, macOS version, provider if relevant, and a **redacted** fixture). Encrypted mail is welcome but not required.

You should hear back within a few days. If the report is in scope, a fix will be prepared before any public write-up.

## What this app does with secrets

CheckUsage is a local menubar widget. It **reuses** sessions the official Claude / Cursor / Codex / Copilot / Gemini / Grok (and related) apps already stored on this Mac. It does **not** create a new login for those tools and it does **not** refresh their OAuth tokens.

- Tokens are sent only to the provider that issued them.
- Pasted OpenRouter / DeepSeek / Z.ai keys are stored in the Keychain service `app.checkusage.secrets`.
- Usage JSON is parsed in-process. Tokens must never be logged, written to Settings, or uploaded as CI artifacts.

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for the credential-read map.

## In scope

- Token, cookie, or API-key leakage (logs, settings files, crash reports, GitHub artifacts)
- Sending a credential to a host other than the issuing provider
- Reading local files beyond the documented credential locations
- Privilege issues in the shipped `.app` that expose Keychain items to other apps unintentionally

## Out of scope

- **Keychain reuse itself.** Reading `Claude Code-credentials`, Cursor `state.vscdb`, `gh` / Codex / Gemini files is the product. That is not a vulnerability unless those secrets leave the machine incorrectly.
- **Unofficial usage APIs** changing, rate-limiting, or returning wrong numbers. Most subscription meters call the same unofficial endpoints the official apps already call. They can break without notice. File a regular bug (no secrets) if a parser needs an update.
- Quota accuracy or billing disputes with a provider
- Ad-hoc code signing / Gatekeeper prompts (the public build is not Developer ID notarized)
- Social engineering, phishing the maintainer, or issues that require a stolen Mac unlock

## Maintainer rules

- Never commit secrets. `.env`, keychains, and provisioning profiles are gitignored.
- CI must not print tokens. Test fixtures must be synthetic.
- Parser unit tests must not touch the network.
