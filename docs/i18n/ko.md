# CheckUsage

**언어:** [English](../../README.md) · [Русский](ru.md) · [简体中文](zh-Hans.md) · [日本語](ja.md) · [Deutsch](de.md) · [Español](es.md) · [Français](fr.md) · [Português (Brasil)](pt-BR.md) · [한국어](ko.md)

이미 이 Mac에 로그인해 둔 AI 도구의 한도 — 화면 가장자리의 얇은 **필**과 링, 상세 팝오버. 추가 로그인 없음. 텔레메트리 없음.

<p align="center">
  <img src="../screenshot.png" alt="CheckUsage 필과 Cursor 한도 팝오버" width="720">
</p>

CheckUsage는 메뉴 막대에 상주하며 어두운 필을 아무 가장자리에나 고정할 수 있습니다. 각 링은 실제 제공자 마크입니다. 올리면 미리 보고, 클릭하면 고정됩니다. 팝오버에는 세션 / 주간 / 플랜, 초기화 시각, 소모 속도 카드가 있습니다. 주기에서 얼마나 썼는지, 예정보다 빠른지, 이 속도라면 언제 바닥날지.

**기본값:** 오른쪽 위, **위치 잠금**, 바깥을 클릭하면 닫힘. `⌥⌘U`는 위젯, `⌥⌘L`은 마지막 한도. 잠금을 풀면 드래그되며 가장자리에 붙습니다. Cursor 초기화는 월간 청구일이며 “이번 토요일”이 아닙니다.

## 무엇인가

한 대의 Mac에서 여러 AI 코딩 에이전트를 쓰는 사람을 위한 한눈에 보는 계기입니다. 가장 빠듯한 잔량은 메뉴 막대에, 링은 가장자리에, 상세는 호버나 클릭으로. 가계부가 아니고 로컬 채팅을 읽지도 않습니다.

## 무엇을 읽나

| 제공자 | 출처 | 재사용하는 로그인 |
|---|---|---|
| Claude | `GET /api/oauth/usage` | Claude Code 키체인 |
| Codex | ChatGPT `wham/usage` | `~/.codex/auth.json` 또는 Codex 키체인 |
| Cursor | 대시보드 `GetCurrentPeriodUsage` | Cursor `state.vscdb` / CLI 키체인 |
| Copilot | GitHub `copilot_internal/user` | `gh` / Copilot 에디터 토큰 |
| Gemini CLI | Cloud Code `retrieveUserQuota` | `~/.gemini/oauth_creds.json` |
| Grok | CLI 결제 프록시 | `~/.grok/auth.json` |
| Antigravity | Cloud Code 할당 요약 | 키체인 `gemini` / `antigravity` |
| OpenCode | OpenCode Go 사용량 | `~/.local/share/opencode/auth.json` |
| OpenRouter | 공식 `/credits` + `/key` | 설정의 API 키 |
| DeepSeek | 공식 `/user/balance` | 설정의 API 키 |
| Z.ai / GLM | 할당량 엔드포인트 | 설정의 API 키 |

로그아웃된 도구는 **로그아웃된 도구 표시**를 켜기 전까지 숨습니다.

구독 미터 대부분은 공식 앱이 이미 호출하는 **비공식** 엔드포인트입니다. 예고 없이 바뀔 수 있습니다. OpenRouter, DeepSeek, Z.ai는 문서화된 API입니다.

## 요구 사항

- macOS 14 이상
- 소스에서 빌드하려면 Xcode 16+ / Swift 6
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)
- 쓸 도구의 공식 CLI/앱에 이미 로그인

## 설치

### 방법 A — GitHub Release

1. 최신 [Release](https://github.com/sysrootix/check-usage/releases)를 엽니다.
2. `CheckUsage.app.zip`을 받아 압축을 풀고 **CheckUsage**를 `/Applications`로 옮깁니다.
3. 처음 실행: 우클릭 → **열기** (애드혹 서명). 네트워크와 키체인 권한을 물으면 Claude / `gh`는 **항상 허용**을 고르세요. 백그라운드 새로고침에 필요합니다.

### 방법 B — 소스에서 빌드

```bash
git clone https://github.com/sysrootix/check-usage.git
cd check-usage
make app
open dist/CheckUsage.app
```

로그인 시 열려면 `/Applications`에 두세요.

## 첫 실행

1. 공식 CLI/앱을 로그인한 채로 둡니다 (Claude Code, Cursor, `gh auth login`, `codex login`, …).
2. CheckUsage를 켭니다. 이미 인증된 링이 나타납니다.
3. 올려서 보고, 클릭해서 고정. 바탕화면 클릭이나 Escape로 닫습니다 (설정에서 고정해 둘 수도 있음).
4. 팝오버의 `↗`는 해당 대시보드를 엽니다.
5. 필을 우클릭하거나 메뉴 막대 항목에서 설정 / 새로고침 / 종료.
6. 잠금을 풀고 다른 가장자리로 드래그. `⌥⌘U`는 숨기고, `⌥⌘L`은 필이 없어도 마지막 한도를 엽니다.

짧은 초기화(`51m`, `3h`)는 창이 6시간 미만일 때만 링 아래에 나옵니다. 90%부터 펄스. 선택 알림은 70% / 90%를 청구 주기마다 한 번씩.

## 언어

시스템 언어를 따르거나 설정에서 고정:

English · Русский · 简体中文 · 日本語 · Deutsch · Español · Français · Português (Brasil) · 한국어

## 개인정보

- 토큰은 이 Mac을 떠나 발급한 제공자에게만 갑니다.
- Claude Code / Codex / Cursor OAuth 토큰은 갱신하지 않습니다. 만료되면 공식 앱에서 다시 로그인하세요.
- 붙여 넣은 API 키는 키체인 서비스 `app.checkusage.secrets`에 있습니다.
- 분석, 크래시 리포터, 계정 없음.
- 설정: `~/Library/Application Support/CheckUsage/settings.json`. 앱을 다시 깔아도 이 파일은 남습니다.

## 개발

```bash
make project
make test
make app
```

[CONTRIBUTING.md](../../CONTRIBUTING.md)를 보세요.

## 라이선스

MIT. 제공자 이름과 마크는 각 소유자에게 있습니다. 패널 마크는 [Simple Icons](https://simpleicons.org) SVG입니다.
