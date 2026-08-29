# CheckUsage

**Idioma:** [English](../../README.md) · [Русский](ru.md) · [简体中文](zh-Hans.md) · [日本語](ja.md) · [Deutsch](de.md) · [Español](es.md) · [Français](fr.md) · [Português (Brasil)](pt-BR.md) · [한국어](ko.md)

Limites das ferramentas de IA em que você já entrou neste Mac — uma **pílula** fina na borda, anéis e um popover de detalhe. Sem outro login. Sem telemetria.

<p align="center">
  <img src="../screenshot.png" alt="Pílula CheckUsage e popover de limites do Cursor" width="720">
</p>

O CheckUsage fica na barra de menus e pode pregar uma pílula escura em qualquer borda. Cada anel é a marca real do provedor. Passe o mouse para espiar; clique para fixar. O popover mostra sessão / semana / plano, quando reinicia e um cartão de ritmo: quanto do ciclo já foi, se você está adiantado e em que data esse ritmo esgotaria o limite.

**Padrão:** canto superior direito e **travada**, fecha ao clicar fora, `⌥⌘U` mostra/oculta o widget, `⌥⌘L` abre os últimos limites. Destrave para arrastar — ela gruda na borda. O reset do Cursor é a data de cobrança mensal, não “este sábado”.

## O que é

Um instrumento de um olhar para quem roda vários agentes de IA num Mac. O pior restante pode ir na barra. Os anéis, na borda. O detalhe, no hover ou no clique. Não é livro de custos nem lê chats locais.

## O que lê

| Provedor | Fonte | Login reutilizado |
|---|---|---|
| Claude | `GET /api/oauth/usage` | Keychain do Claude Code |
| Codex | ChatGPT `wham/usage` | `~/.codex/auth.json` ou Keychain do Codex |
| Cursor | Painel `GetCurrentPeriodUsage` | Cursor `state.vscdb` / Keychain do CLI |
| Copilot | GitHub `copilot_internal/user` | `gh` / token do editor Copilot |
| Gemini CLI | Cloud Code `retrieveUserQuota` | `~/.gemini/oauth_creds.json` |
| Grok | Proxy de cobrança do CLI | `~/.grok/auth.json` |
| Antigravity | Resumo de cota Cloud Code | Keychain `gemini` / `antigravity` |
| OpenCode | Uso do OpenCode Go | `~/.local/share/opencode/auth.json` |
| OpenRouter | Oficiais `/credits` + `/key` | Chave API em Ajustes |
| DeepSeek | Oficial `/user/balance` | Chave API em Ajustes |
| Z.ai / GLM | Endpoint de cota | Chave API em Ajustes |

Ferramentas desconectadas ficam ocultas até ligar **Mostrar ferramentas desconectadas**.

A maioria dos medidores de assinatura são endpoints **não oficiais** que os apps oficiais já chamam. Podem mudar. OpenRouter, DeepSeek e Z.ai usam APIs documentadas.

## Requisitos

- macOS 14 ou mais novo
- Xcode 16+ / Swift 6 (para compilar)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)
- CLIs ou apps oficiais já autenticados

## Instalação

### Opção A — Release no GitHub

1. Abra o último [Release](https://github.com/sysrootix/check-usage/releases).
2. Baixe `CheckUsage.app.zip`, descompacte e arraste **CheckUsage** para `/Applications`.
3. Primeira abertura: clique com o botão direito → **Abrir** (assinatura ad-hoc). O macOS pode pedir rede e Keychain — **Sempre permitir** em Claude / `gh` para atualizar em segundo plano.

### Opção B — Compilar do código

```bash
git clone https://github.com/sysrootix/check-usage.git
cd check-usage
make app
open dist/CheckUsage.app
```

Coloque em `/Applications` se quiser **Abrir no login**.

## Primeiro uso

1. Deixe as CLIs/apps oficiais conectadas (Claude Code, Cursor, `gh auth login`, `codex login`, …).
2. Abra o CheckUsage. Aparecem anéis do que já estiver autenticado.
3. Passe o mouse para espiar. Clique para fixar. Clique na mesa ou Escape fecha (ou deixe grudento em Ajustes).
4. O `↗` do popover abre o painel do provedor.
5. Clique com o direito na pílula ou no item da barra: ajustes / atualizar / sair.
6. Destrave para arrastar a outra borda. `⌥⌘U` esconde; `⌥⌘L` abre os últimos limites mesmo sem a pílula.

Reset curto (`51m`, `3h`) só se a janela tiver menos de seis horas. A partir de 90% o anel pulsa. Avisos opcionais em 70% e 90% uma vez por ciclo de cobrança.

## Idiomas

Segue o do sistema ou um travamento em Ajustes:

English · Русский · 简体中文 · 日本語 · Deutsch · Español · Français · Português (Brasil) · 한국어

## Privacidade

- Tokens não saem deste Mac, exceto para quem os emitiu.
- Não renovamos tokens OAuth do Claude Code / Codex / Cursor. Sessão expirada: entre de novo no app oficial.
- Chaves API coladas vão para o Keychain `app.checkusage.secrets`.
- Sem analytics, sem crash reporter, sem contas.
- Ajustes: `~/Library/Application Support/CheckUsage/settings.json`. Reinstalar o app não apaga esse arquivo.

## Desenvolvimento

```bash
make project
make test
make app
```

Veja [CONTRIBUTING.md](../../CONTRIBUTING.md).

## Licença

MIT. Nomes e marcas dos provedores pertencem aos donos. Marcas do painel: SVGs do [Simple Icons](https://simpleicons.org).
