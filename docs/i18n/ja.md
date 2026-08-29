# CheckUsage

**言語:** [English](../../README.md) · [Русский](ru.md) · [简体中文](zh-Hans.md) · [日本語](ja.md) · [Deutsch](de.md) · [Español](es.md) · [Français](fr.md) · [Português (Brasil)](pt-BR.md) · [한국어](ko.md)

すでに Mac にログインしている AI ツールの上限 — 画面端の細い**ピル**とリング、詳細ポップオーバー。追加ログインなし。テレメトリなし。

<p align="center">
  <img src="../screenshot.jpg" alt="CheckUsage のピルと Cursor 上限ポップオーバー" width="720">
</p>

CheckUsage はメニューバーに常駐し、暗いピルを任意の端に固定できます。各リングは実際のプロバイダーマークです。ホバーで覗き、クリックで固定。セッション / 週次 / プラン、リセット時刻、消費ペース（周期の消化、予定より早いか、この速度だといつ尽きるか）を表示します。

**初期値:** 右上・**位置ロック**・外側クリックで閉じる。`⌥⌘U` でウィジェット、`⌥⌘L` で前回の上限。ロックを外すとドラッグでき、端に吸着します。Cursor のリセットは月次の課金日であり、「今週の土曜」ではありません。

## これは何か

複数の AI コーディングエージェントを一台の Mac で使う人向けの、一目で分かる計器です。メニューバーに最も厳しい残量、端にリング、ホバー/クリックで詳細。家計簿でも、ローカルのチャットログを読むツールでもありません。

## 読み取り元

| プロバイダー | データの出所 | 再利用するログイン |
|---|---|---|
| Claude | `GET /api/oauth/usage` | Claude Code のキーチェーン |
| Codex | ChatGPT `wham/usage` | `~/.codex/auth.json` または Codex キーチェーン |
| Cursor | ダッシュボード `GetCurrentPeriodUsage` | Cursor `state.vscdb` / CLI キーチェーン |
| Copilot | GitHub `copilot_internal/user` | `gh` / Copilot エディタトークン |
| Gemini CLI | Cloud Code `retrieveUserQuota` | `~/.gemini/oauth_creds.json` |
| Grok | CLI 課金プロキシ | `~/.grok/auth.json` |
| Antigravity | Cloud Code クォータ要約 | キーチェーン `gemini` / `antigravity` |
| OpenCode | OpenCode Go の使用量 | `~/.local/share/opencode/auth.json` |
| OpenRouter | 公式 `/credits` + `/key` | 設定の API キー |
| DeepSeek | 公式 `/user/balance` | 設定の API キー |
| Z.ai / GLM | クォータ API | 設定の API キー |

未ログインのツールは、**未ログインも表示**をオンにしない限り隠れます。

サブスクリプション計器の多くは、公式アプリが呼んでいる**非公式**エンドポイントです。予告なく変わることがあります。OpenRouter / DeepSeek / Z.ai は公開 API です。

## 要件

- macOS 14 以降
- ソースからビルドする場合は Xcode 16+ / Swift 6
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)（`brew install xcodegen`）
- 使いたいツールの公式 CLI / アプリにログイン済みであること

## インストール

### A — GitHub Release

1. 最新の [Release](https://github.com/sysrootix/check-usage/releases) を開く。
2. `CheckUsage.app.zip` をダウンロードし、解凍して **CheckUsage** を `/Applications` へ。
3. 初回は右クリック → **開く**（アドホック署名）。ネットワークとキーチェーンの許可を求められたら、Claude / `gh` は**常に許可**にするとバックグラウンド更新できます。

### B — ソースからビルド

```bash
git clone https://github.com/sysrootix/check-usage.git
cd check-usage
make app
open dist/CheckUsage.app
```

ログイン時に開くなら `/Applications` へ置いてください。

## 初回

1. 公式 CLI/アプリにログインしたままにする（Claude Code、Cursor、`gh auth login`、`codex login` …）。
2. CheckUsage を起動。認証済みのリングが出ます。
3. ホバーで覗き、クリックで固定。デスクトップをクリックするか Escape で閉じる（設定で常時表示にもできます）。
4. ポップオーバーの `↗` でそのダッシュボードを開く。
5. ピルを右クリック、またはメニューバーから設定 / 更新 / 終了。
6. ロックを外して別の端へドラッグ。`⌥⌘U` で隠す。`⌥⌘L` はピルが無くても前回の上限を開く。

6 時間未満の窓だけ、リング下に短いリセット（`51m`、`3h`）を出します。90% からパルス。任意の通知は 70% / 90% を課金周期ごとに一度。

## 言語

システム言語、または設定で固定：

English · Русский · 简体中文 · 日本語 · Deutsch · Español · Français · Português (Brasil) · 한국어

## プライバシー

- トークンはこの Mac から、発行元のプロバイダー以外へは送られません。
- Claude Code / Codex / Cursor の OAuth トークンは更新しません。切れたら公式アプリで再ログイン。
- 貼り付けた API キーはキーチェーン `app.checkusage.secrets`。
- 分析、クラッシュレポーター、アカウントはありません。
- 設定: `~/Library/Application Support/CheckUsage/settings.json`。アプリを入れ直しても消えません。

## 開発

```bash
make project
make test
make app
```

[CONTRIBUTING.md](../../CONTRIBUTING.md) を参照。

## ライセンス

MIT。プロバイダー名とマークは各社に帰属。パネルのマークは [Simple Icons](https://simpleicons.org) の SVG です。
