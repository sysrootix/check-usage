# CheckUsage

**Idioma:** [English](../../README.md) · [Русский](ru.md) · [简体中文](zh-Hans.md) · [日本語](ja.md) · [Deutsch](de.md) · [Español](es.md) · [Français](fr.md) · [Português (Brasil)](pt-BR.md) · [한국어](ko.md)

Límites de las herramientas de IA en las que ya has iniciado sesión en el Mac — una **píldora** fina en el borde con anillos y un popover de detalle. Sin otro login. Sin telemetría.

<p align="center">
  <img src="../screenshot.jpg" alt="Píldora CheckUsage y popover de límites de Cursor" width="720">
</p>

CheckUsage vive en la barra de menú y puede fijar una píldora oscura en cualquier borde. Cada anillo es la marca real del proveedor. Al pasar el ratón se asoma; al clic se fija. El popover muestra sesión / semana / plan, cuándo se reinicia y una tarjeta de ritmo: cuánto ciclo se ha gastado, si vas por delante y en qué fecha se agotaría a este ritmo.

**Por defecto:** arriba a la derecha y **bloqueada**, se cierra al clic fuera, `⌥⌘U` muestra/oculta el widget, `⌥⌘L` abre los últimos límites. Desbloquea para arrastrar; se ajusta al borde. El reinicio de Cursor es la fecha de facturación mensual, no «este sábado».

**Estado:** se mantiene activamente. Los medidores no oficiales pueden romperse sin aviso; véase [SECURITY.md](../../SECURITY.md) y [CHANGELOG.md](../../CHANGELOG.md).

## Qué es

Un instrumento de un vistazo para quien corre varios agentes de IA en un Mac. El peor resto puede ir en la barra. Los anillos, en el borde. El detalle, al pasar o al clic. No es un libro de costes ni lee chats locales.

## Qué lee

| Proveedor | Fuente | Sesión que reutiliza |
|---|---|---|
| Claude | `GET /api/oauth/usage` | Llavero de Claude Code |
| Codex | ChatGPT `wham/usage` | `~/.codex/auth.json` o llavero de Codex |
| Cursor | Panel `GetCurrentPeriodUsage` | Cursor `state.vscdb` / llavero CLI |
| Copilot | GitHub `copilot_internal/user` | `gh` / token del editor Copilot |
| Gemini CLI | Cloud Code `retrieveUserQuota` | `~/.gemini/oauth_creds.json` |
| Grok | Proxy de facturación CLI | `~/.grok/auth.json` |
| Antigravity | Resumen de cuota Cloud Code | Llavero `gemini` / `antigravity` |
| OpenCode | Uso de OpenCode Go | `~/.local/share/opencode/auth.json` |
| OpenRouter | Oficiales `/credits` + `/key` | Clave API en Ajustes |
| DeepSeek | Oficial `/user/balance` | Clave API en Ajustes |
| Z.ai / GLM | Endpoint de cuota | Clave API en Ajustes |

Las herramientas sin sesión se ocultan hasta que actives **Mostrar herramientas sin sesión**.

La mayoría de contadores de suscripción son endpoints **no oficiales** que ya llaman las apps oficiales. Pueden cambiar. OpenRouter, DeepSeek y Z.ai usan APIs documentadas.

## Requisitos

- macOS 14 o posterior
- Xcode 16+ / Swift 6 (para compilar)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)
- CLIs o apps oficiales ya autenticadas

## Instalación

### Opción A — Release en GitHub

1. Abre el último [Release](https://github.com/sysrootix/check-usage/releases).
2. Descarga `CheckUsage.app.zip`, descomprime y arrastra **CheckUsage** a `/Applications`.
3. Primer arranque: clic derecho → **Abrir** (firma ad-hoc). macOS puede pedir red y llavero — **Permitir siempre** en Claude / `gh` para refrescar en segundo plano.

### Opción B — Compilar desde el código

```bash
git clone https://github.com/sysrootix/check-usage.git
cd check-usage
make app
open dist/CheckUsage.app
```

Llévala a `/Applications` si quieres **Abrir al iniciar sesión**.

## Primer uso

1. Deja las CLIs/apps oficiales conectadas (Claude Code, Cursor, `gh auth login`, `codex login`, …).
2. Lanza CheckUsage. Aparecen anillos de lo que ya esté autenticado.
3. Pasa el ratón para asomarte. Clic para fijar. Clic en el escritorio o Escape cierra (o déjalo fijo en Ajustes).
4. El `↗` del popover abre el panel del proveedor.
5. Clic derecho en la píldora o el ítem de menú: ajustes / actualizar / salir.
6. Desbloquea para arrastrar a otro borde. `⌥⌘U` oculta; `⌥⌘L` abre los últimos límites aunque no esté la píldora.

El reset corto (`51m`, `3h`) solo si la ventana dura menos de seis horas. Desde el 90% el anillo pulsa. Avisos opcionales al 70% y 90% una vez por ciclo de facturación.

## Idiomas

Sigue el del sistema o un bloqueo en Ajustes:

English · Русский · 简体中文 · 日本語 · Deutsch · Español · Français · Português (Brasil) · 한국어

## Privacidad

- Los tokens no salen de este Mac salvo hacia quien los emitió.
- No se renuevan tokens OAuth de Claude Code / Codex / Cursor. Si caduca la sesión, entra de nuevo en la app oficial.
- Las claves API pegadas van al llavero `app.checkusage.secrets`.
- Sin analítica, sin informes de fallo, sin cuentas.
- Ajustes: `~/Library/Application Support/CheckUsage/settings.json`. Reinstalar no borra ese archivo.

## Desarrollo

```bash
make project
make test
make app
```

Ver [CONTRIBUTING.md](../../CONTRIBUTING.md).

## Documentación

[Arquitectura](../ARCHITECTURE.md) · [Contributing](../../CONTRIBUTING.md) · [Seguridad](../../SECURITY.md) · [Changelog](../../CHANGELOG.md) · [Issues / hoja de ruta](https://github.com/sysrootix/check-usage/issues)

## Licencia

MIT. Nombres y marcas de los proveedores pertenecen a sus dueños. Las marcas del panel usan SVG de [Simple Icons](https://simpleicons.org).
