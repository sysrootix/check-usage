# CheckUsage

**Sprache:** [English](../../README.md) · [Русский](ru.md) · [简体中文](zh-Hans.md) · [日本語](ja.md) · [Deutsch](de.md) · [Español](es.md) · [Français](fr.md) · [Português (Brasil)](pt-BR.md) · [한국어](ko.md)

Limits der KI-Tools, bei denen Sie auf dem Mac schon angemeldet sind — eine schmale **Pille am Bildschirmrand** mit Ringen und ein Detail-Popover. Kein Extra-Login. Keine Telemetrie.

<p align="center">
  <img src="../screenshot.jpg" alt="CheckUsage-Pille und Cursor-Limit-Popover" width="720">
</p>

CheckUsage sitzt in der Menüleiste und kann eine dunkle Pille an jeder Kante halten. Jeder Ring ist eine echte Anbietermarke. Hover zeigt die Fenster, Klick pinnt sie. Im Popover: Sitzung / Woche / Tarif, Reset-Zeit und ein Tempo-Karte: wie viel vom Zyklus weg ist, ob Sie vorauslaufen, und wann dieses Tempo das Limit leeren würde.

**Standard:** oben rechts und **gesperrt**, Schließen bei Klick daneben, `⌥⌘U` blendet das Widget, `⌥⌘L` öffnet die letzten Limits. Entsperren zum Ziehen — es rastet an einer Kante ein. Cursors Reset ist das monatliche Abrechnungsdatum, nicht „diesen Samstag“.

**Status:** wird aktiv gepflegt. Inoffizielle Zähler können ohne Vorankündigung brechen — siehe [SECURITY.md](../../SECURITY.md) und [CHANGELOG.md](../../CHANGELOG.md).

## Was es ist

Ein Blick-Instrument für alle, die mehrere KI-Coding-Agenten auf einem Mac fahren. Der knappste Rest kann in der Menüleiste stehen. Ringe an der Kante. Details per Hover oder Klick. Kein Kostenbuch, kein Auslesen lokaler Chats.

## Was es liest

| Anbieter | Quelle | Wiederverwendete Anmeldung |
|---|---|---|
| Claude | `GET /api/oauth/usage` | Claude-Code-Schlüsselbund |
| Codex | ChatGPT `wham/usage` | `~/.codex/auth.json` oder Codex-Schlüsselbund |
| Cursor | Dashboard `GetCurrentPeriodUsage` | Cursor `state.vscdb` / CLI-Schlüsselbund |
| Copilot | GitHub `copilot_internal/user` | `gh` / Copilot-Editor-Token |
| Gemini CLI | Cloud Code `retrieveUserQuota` | `~/.gemini/oauth_creds.json` |
| Grok | CLI-Billing-Proxy | `~/.grok/auth.json` |
| Antigravity | Cloud-Code-Quota | Schlüsselbund `gemini` / `antigravity` |
| OpenCode | OpenCode-Go-Nutzung | `~/.local/share/opencode/auth.json` |
| OpenRouter | Offiziell `/credits` + `/key` | API-Schlüssel in den Einstellungen |
| DeepSeek | Offiziell `/user/balance` | API-Schlüssel in den Einstellungen |
| Z.ai / GLM | Quota-Endpunkt | API-Schlüssel in den Einstellungen |

Abgemeldete Tools bleiben verborgen, bis **Abgemeldete Tools zeigen** an ist.

Die meisten Abo-Zähler sind **inoffizielle** Endpunkte, die die offiziellen Apps schon aufrufen. Sie können sich ändern. OpenRouter, DeepSeek und Z.ai nutzen dokumentierte APIs.

## Voraussetzungen

- macOS 14 oder neuer
- Xcode 16+ / Swift 6 (für den Build)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)
- Offizielle CLIs/Apps bereits angemeldet

## Installation

### Variante A — GitHub Release

1. Das neueste [Release](https://github.com/sysrootix/check-usage/releases) öffnen.
2. `CheckUsage.app.zip` laden, entpacken, **CheckUsage** nach `/Applications` ziehen.
3. Erster Start: Rechtsklick → **Öffnen** (Ad-hoc-Signatur). macOS fragt nach Netzwerk und Schlüsselbund — für Claude / `gh` **Immer erlauben**, damit die Leiste im Hintergrund aktualisiert.

### Variante B — Aus dem Quellcode

```bash
git clone https://github.com/sysrootix/check-usage.git
cd check-usage
make app
open dist/CheckUsage.app
```

Nach `/Applications` legen, wenn **Bei Anmeldung öffnen** gewünscht ist.

## Erster Start

1. Offizielle CLIs/Apps angemeldet lassen (Claude Code, Cursor, `gh auth login`, `codex login`, …).
2. CheckUsage starten. Ringe erscheinen für alles, was schon authentifiziert ist.
3. Hover zum Blick, Klick zum Pinnen. Klick auf den Schreibtisch oder Escape schließt (oder in den Einstellungen klebrig lassen).
4. `↗` im Popover öffnet das Dashboard des Anbieters.
5. Rechtsklick auf die Pille oder den Menüleisten-Eintrag: Einstellungen / Aktualisieren / Beenden.
6. Entsperren, um an eine andere Kante zu ziehen. `⌥⌘U` blendet aus; `⌥⌘L` öffnet die letzten Limits auch ohne Pille.

Kurzer Reset (`51m`, `3h`) nur wenn das Fenster unter sechs Stunden liegt. Ab 90% pulsiert der Ring. Optionale Meldungen bei 70% und 90% einmal pro Abrechnungszyklus.

## Sprachen

Systemsprache oder Fixierung in den Einstellungen:

English · Русский · 简体中文 · 日本語 · Deutsch · Español · Français · Português (Brasil) · 한국어

## Datenschutz

- Tokens verlassen diesen Mac nur zum ausstellenden Anbieter.
- OAuth-Tokens von Claude Code / Codex / Cursor werden nicht erneuert. Sitzung abgelaufen — in der offiziellen App neu anmelden.
- Eingefügte API-Schlüssel liegen im Schlüsselbund-Dienst `app.checkusage.secrets`.
- Keine Analytik, keine Crash-Reporter, keine Konten.
- Einstellungen: `~/Library/Application Support/CheckUsage/settings.json`. Neuinstallation löscht die Datei nicht.

## Entwicklung

```bash
make project
make test
make app
```

Siehe [CONTRIBUTING.md](../../CONTRIBUTING.md).

## Dokumentation

[Architektur](../ARCHITECTURE.md) · [Contributing](../../CONTRIBUTING.md) · [Sicherheit](../../SECURITY.md) · [Changelog](../../CHANGELOG.md) · [Issues / Roadmap](https://github.com/sysrootix/check-usage/issues)

## Lizenz

MIT. Namen und Marken der Anbieter gehören ihren Eigentümern. Marken auf der Leiste: SVGs von [Simple Icons](https://simpleicons.org).
