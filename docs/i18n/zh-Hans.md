# CheckUsage

**语言：** [English](../../README.md) · [Русский](ru.md) · [简体中文](zh-Hans.md) · [日本語](ja.md) · [Deutsch](de.md) · [Español](es.md) · [Français](fr.md) · [Português (Brasil)](pt-BR.md) · [한국어](ko.md)

查看 Mac 上**已经登录**的 AI 工具额度 — 贴在屏幕边缘的细长**胶囊**和圆环，点开即可看明细。无需再登一次。无遥测。

<p align="center">
  <img src="../screenshot.jpg" alt="CheckUsage 胶囊与 Cursor 额度弹层" width="720">
</p>

CheckUsage 在菜单栏运行，也可把深色胶囊钉在任意边缘。每个圆环都是真实的服务商标识。悬停预览，单击固定。弹层显示会话 / 每周 / 套餐用量、重置时间，以及消耗节奏：本周期已用多少、是否超前、按此速度会在哪一天用完。

**默认：** 右上角、**锁定位置**、点击外部关闭，`⌥⌘U` 显示/隐藏胶囊，`⌥⌘L` 打开上次额度。解锁后可拖动并吸附到边缘。Cursor 的重置是月度账单日，不是「本周六」。

**状态：** 持续维护。非官方用量接口可能随时失效，见 [SECURITY.md](../../SECURITY.md) 与 [CHANGELOG.md](../../CHANGELOG.md)。

## 这是什么

给同时跑多个 AI 编程助手的人用的一眼仪表。菜单栏可显示最紧的剩余百分比。圆环在边缘。细节靠悬停或点击。它不是账单本，也不会去扫本地聊天记录。

## 读取来源

| 服务 | 数据来源 | 复用的登录 |
|---|---|---|
| Claude | `GET /api/oauth/usage` | Claude Code 钥匙串 |
| Codex | ChatGPT `wham/usage` | `~/.codex/auth.json` 或 Codex 钥匙串 |
| Cursor | 控制台 `GetCurrentPeriodUsage` | Cursor `state.vscdb` / CLI 钥匙串 |
| Copilot | GitHub `copilot_internal/user` | `gh` / Copilot 编辑器令牌 |
| Gemini CLI | Cloud Code `retrieveUserQuota` | `~/.gemini/oauth_creds.json` |
| Grok | CLI 计费代理 | `~/.grok/auth.json` |
| Antigravity | Cloud Code 配额摘要 | 钥匙串 `gemini` / `antigravity` |
| OpenCode | OpenCode Go 用量 | `~/.local/share/opencode/auth.json` |
| OpenRouter | 官方 `/credits` + `/key` | 设置里的 API 密钥 |
| DeepSeek | 官方 `/user/balance` | 设置里的 API 密钥 |
| Z.ai / GLM | 配额接口 | 设置里的 API 密钥 |

未登录的工具默认隐藏，除非打开**显示未登录的服务**。

多数订阅计量是官方应用已经在调用的**非官方**接口，可能随时变更。OpenRouter、DeepSeek、Z.ai 使用文档中的 API。

## 系统要求

- macOS 14 或更高
- 从源码构建需要 Xcode 16+ / Swift 6
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)（`brew install xcodegen`）
- 你关心的工具已在官方 CLI 或应用中登录

## 安装

### 方式 A — GitHub Release

1. 打开最新 [Release](https://github.com/sysrootix/check-usage/releases)。
2. 下载 `CheckUsage.app.zip`，解压后把 **CheckUsage** 拖到 `/Applications`。
3. 首次启动：右键 → **打开**（ad-hoc 签名）。系统可能询问网络和钥匙串 — 对 Claude / `gh` 选**始终允许**，以便后台刷新。

### 方式 B — 从源码构建

```bash
git clone https://github.com/sysrootix/check-usage.git
cd check-usage
make app
open dist/CheckUsage.app
```

若要登录时启动，请把应用放到 `/Applications`。

## 第一次使用

1. 保持官方 CLI/应用已登录（Claude Code、Cursor、`gh auth login`、`codex login` …）。
2. 启动 CheckUsage，已认证的服务会显示圆环。
3. 悬停预览，单击固定。点桌面或按 Escape 关闭（也可在设置里保持常开）。
4. 弹层上的 `↗` 打开该服务的控制台。
5. 右键胶囊或菜单栏项：设置 / 刷新 / 退出。
6. 解锁后可拖到其他边缘。`⌥⌘U` 隐藏；`⌥⌘L` 即使胶囊关闭也能打开上次额度。

仅当窗口不足 6 小时时，圆环下才显示短重置（`51m`、`3h`）。达到 90% 会脉冲。可选通知在 70% / 90% 每个账期各一次。

## 界面语言

跟随系统，或在设置中锁定：

English · Русский · 简体中文 · 日本語 · Deutsch · Español · Français · Português (Brasil) · 한국어

## 隐私

- 令牌只发往签发它的服务，不离开这台 Mac 去别处。
- 不会刷新 Claude Code / Codex / Cursor 的 OAuth 令牌。过期请在官方应用重新登录。
- 粘贴的 API 密钥存在钥匙串服务 `app.checkusage.secrets`。
- 无分析、无崩溃上报、无账号。
- 设置文件：`~/Library/Application Support/CheckUsage/settings.json`。重装应用不会删除它。

## 开发

```bash
make project
make test
make app
```

见 [CONTRIBUTING.md](../../CONTRIBUTING.md)。

## 文档

[架构](../ARCHITECTURE.md) · [贡献](../../CONTRIBUTING.md) · [安全](../../SECURITY.md) · [Changelog](../../CHANGELOG.md) · [Issues / 路线图](https://github.com/sysrootix/check-usage/issues)

## 许可

MIT。服务商名称与标识归其所有者。面板图标来自 [Simple Icons](https://simpleicons.org)。
