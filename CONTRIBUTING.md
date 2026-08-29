# Contributing

## Add a provider

1. Add a case to `ProviderID`.
2. Parse the JSON in `UsageParsers` — keep network out of the parser.
3. Fetch in `UsageService` using credentials the official app already stored. Do not invent a new login flow unless the provider only has API keys.
4. Add a Simple Icons SVG in `Resources/Logos` and a fallback mark in `ProviderMark`.
5. Add a fixture test with a real-looking payload.
6. Never log tokens, cookies, or Keychain blobs.

## Localization

Strings live in `L10n.swift`. Add the same key to every language table. If you skip a language, English is the fallback.

## Build

```bash
make test
make app
```
