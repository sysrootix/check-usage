import Foundation

struct UsageService: Sendable {
    var openRouterKey: String = ""
    var deepSeekKey: String = ""
    var zaiKey: String = ""

    func fetch(_ id: ProviderID) async -> ProviderLoadState {
        do {
            switch id {
            case .claude: return .ready(try await claude())
            case .codex: return .ready(try await codex())
            case .cursor: return .ready(try await cursor())
            case .copilot: return .ready(try await copilot())
            case .gemini: return .ready(try await gemini())
            case .grok: return .ready(try await grok())
            case .antigravity: return .ready(try await antigravity())
            case .opencode: return .ready(try await opencode())
            case .openrouter: return .ready(try await openrouter())
            case .deepseek: return .ready(try await deepseek())
            case .zai: return .ready(try await zai())
            }
        } catch CheckUsageError.missingCredentials {
            return .signedOut
        } catch CheckUsageError.missingAPIKey {
            return .missingKey
        } catch CheckUsageError.unauthorized {
            return .error(L10n.t("unauthorized"))
        } catch CheckUsageError.rateLimited {
            return .error(L10n.t("rate_limited"))
        } catch CheckUsageError.decode {
            return .error(L10n.t("decode_error"))
        } catch {
            return .error(error.localizedDescription)
        }
    }

    private func claude() async throws -> QuotaSnapshot {
        guard let token = claudeToken() else { throw CheckUsageError.missingCredentials }
        let json = try await HTTPClient.jsonObject(
            url: URL(string: "https://api.anthropic.com/api/oauth/usage")!,
            headers: [
                "Authorization": "Bearer \(token)",
                "anthropic-beta": "oauth-2025-04-20",
                "Accept": "application/json",
                "User-Agent": "claude-code/\(claudeVersion())",
            ]
        )
        var snapshot = UsageParsers.claude(json)
        if let plan = claudePlan() {
            snapshot = snapshot.with(planName: plan)
        }
        return snapshot
    }

    private func claudeToken() -> String? {
        if let env = ProcessInfo.processInfo.environment["CLAUDE_CODE_OAUTH_TOKEN"], !env.isEmpty {
            return env
        }
        let blob = SecretStore.keychainPassword(service: "Claude Code-credentials", account: Home.user)
            ?? SecretStore.keychainPassword(service: "Claude Code-credentials")
        let json = blob.flatMap(SecretStore.jsonObject(from:))
            ?? SecretStore.readJSONFile(Home.path(".claude", ".credentials.json"))
        return json?.path("claudeAiOauth", "accessToken")?.string
    }

    private func claudePlan() -> String? {
        let json = SecretStore.readJSONFile(Home.path(".claude.json"))
        let type = json?.path("oauthAccount", "organizationType")?.string
        let tier = json?.path("oauthAccount", "organizationRateLimitTier")?.string
        if let type, let tier { return "\(type) · \(tier)" }
        return type ?? tier
    }

    private func claudeVersion() -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-lc", "claude --version 2>/dev/null | head -1"]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()
        try? process.run()
        DispatchQueue.global().asyncAfter(deadline: .now() + 1.2) {
            if process.isRunning { process.terminate() }
        }
        process.waitUntilExit()
        let text = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        let version = text.split(whereSeparator: { !$0.isNumber && $0 != "." }).first.map(String.init)
        return version ?? "2.1.251"
    }

    private func codex() async throws -> QuotaSnapshot {
        guard let token = codexAccessToken() else { throw CheckUsageError.missingCredentials }
        let account = codexAccountID()
        var headers = [
            "Authorization": "Bearer \(token)",
            "Accept": "application/json",
            "User-Agent": "codex-cli",
        ]
        if let account {
            headers["ChatGPT-Account-Id"] = account
        }
        let urls = [
            "https://chatgpt.com/backend-api/wham/usage",
            "https://chatgpt.com/backend-api/codex/usage",
        ]
        var lastError: Error = CheckUsageError.missingCredentials
        for url in urls {
            do {
                let json = try await HTTPClient.jsonObject(url: URL(string: url)!, headers: headers)
                return UsageParsers.codex(json)
            } catch {
                lastError = error
            }
        }
        throw lastError
    }

    private func codexAuth() -> JSONValue? {
        SecretStore.readJSONFile(Home.path(".codex", "auth.json"))
            ?? SecretStore.readJSONFile(Home.path(".config", "codex", "auth.json"))
            ?? SecretStore.keychainPassword(service: "Codex Auth").flatMap(SecretStore.jsonObject(from:))
    }

    private func codexAccessToken() -> String? {
        if let json = codexAuth() {
            return json.path("tokens", "access_token")?.string ?? json["access_token"]?.string
        }
        return SecretStore.keychainPassword(service: "Codex Auth")
    }

    private func codexAccountID() -> String? {
        codexAuth()?["tokens"]?["account_id"]?.string
    }

    private func cursor() async throws -> QuotaSnapshot {
        guard let token = cursorToken() else { throw CheckUsageError.missingCredentials }
        let headers = [
            "Authorization": "Bearer \(token)",
            "Content-Type": "application/json",
            "Connect-Protocol-Version": "1",
        ]
        let usageURL = URL(string: "https://api2.cursor.sh/aiserver.v1.DashboardService/GetCurrentPeriodUsage")!
        let planURL = URL(string: "https://api2.cursor.sh/aiserver.v1.DashboardService/GetPlanInfo")!
        let empty = "{}".data(using: .utf8)
        let usage = try await HTTPClient.jsonObject(url: usageURL, method: "POST", headers: headers, body: empty)
        let plan = try? await HTTPClient.jsonObject(url: planURL, method: "POST", headers: headers, body: empty)
        var snapshot = UsageParsers.cursor(usage, plan: plan)
        let planName = plan?.path("planInfo", "planName")?.string ?? cursorMembership()
        snapshot = snapshot.with(planName: planName)
        return snapshot
    }

    private func cursorToken() -> String? {
        let db = Home.path("Library", "Application Support", "Cursor", "User", "globalStorage", "state.vscdb")
        if let value = SecretStore.sqliteValue(db: db, sql: "SELECT value FROM ItemTable WHERE key = 'cursorAuth/accessToken' LIMIT 1") {
            return value
        }
        return SecretStore.keychainPassword(service: "cursor-access-token", account: "cursor-user")
    }

    private func cursorMembership() -> String? {
        let db = Home.path("Library", "Application Support", "Cursor", "User", "globalStorage", "state.vscdb")
        return SecretStore.sqliteValue(db: db, sql: "SELECT value FROM ItemTable WHERE key = 'cursorAuth/stripeMembershipType' LIMIT 1")
    }

    private func copilot() async throws -> QuotaSnapshot {
        guard let token = copilotToken() else { throw CheckUsageError.missingCredentials }
        let json = try await HTTPClient.jsonObject(
            url: URL(string: "https://api.github.com/copilot_internal/user")!,
            headers: [
                "Authorization": "token \(token)",
                "Accept": "application/json",
                "Editor-Version": "vscode/1.96.2",
                "Editor-Plugin-Version": "copilot-chat/0.26.7",
                "User-Agent": "GitHubCopilotChat/0.26.7",
                "X-Github-Api-Version": "2025-04-01",
            ]
        )
        return UsageParsers.copilot(json)
    }

    private func copilotToken() -> String? {
        if let env = ProcessInfo.processInfo.environment["GH_TOKEN"] ?? ProcessInfo.processInfo.environment["GITHUB_TOKEN"], !env.isEmpty {
            return env
        }
        if let apps = SecretStore.readJSONFile(Home.path(".config", "github-copilot", "apps.json"))?.object {
            for (_, value) in apps {
                if let token = value["oauth_token"]?.string { return token }
            }
        }
        if let hosts = try? String(contentsOfFile: Home.path(".config", "gh", "hosts.yml"), encoding: .utf8) {
            for line in hosts.split(separator: "\n") {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                if trimmed.hasPrefix("oauth_token:") {
                    return trimmed.replacingOccurrences(of: "oauth_token:", with: "").trimmingCharacters(in: .whitespaces)
                }
            }
        }
        return SecretStore.keychainPassword(service: "gh:github.com")
            ?? SecretStore.keychainPassword(service: "gh:github.com", account: "user")
    }

    private func gemini() async throws -> QuotaSnapshot {
        guard let token = geminiToken() else { throw CheckUsageError.missingCredentials }
        let project = SecretStore.readJSONFile(Home.path(".gemini", "settings.json"))?["project"]?.string
        var body: [String: Any] = ["userAgent": "CheckUsage/1.0"]
        if let project { body["project"] = project }
        let data = try JSONSerialization.data(withJSONObject: body)
        let json = try await HTTPClient.jsonObject(
            url: URL(string: "https://cloudcode-pa.googleapis.com/v1internal:retrieveUserQuota")!,
            method: "POST",
            headers: [
                "Authorization": "Bearer \(token)",
                "Content-Type": "application/json",
            ],
            body: data
        )
        return UsageParsers.gemini(json)
    }

    private func geminiToken() -> String? {
        if let file = SecretStore.readJSONFile(Home.path(".gemini", "oauth_creds.json")) {
            return file["access_token"]?.string
        }
        return SecretStore.keychainPassword(service: "gemini-cli-oauth", account: "main-account")
            .flatMap { SecretStore.jsonObject(from: $0)?["access_token"]?.string ?? $0 }
    }

    private func grok() async throws -> QuotaSnapshot {
        guard let token = grokToken() else { throw CheckUsageError.missingCredentials }
        let json = try await HTTPClient.jsonObject(
            url: URL(string: "https://cli-chat-proxy.grok.com/v1/billing?format=credits")!,
            headers: [
                "Authorization": "Bearer \(token)",
                "X-XAI-Token-Auth": "xai-grok-cli",
                "Accept": "application/json",
            ]
        )
        var snapshot = UsageParsers.grok(json)
        if let settings = try? await HTTPClient.jsonObject(
            url: URL(string: "https://cli-chat-proxy.grok.com/v1/settings")!,
            headers: [
                "Authorization": "Bearer \(token)",
                "X-XAI-Token-Auth": "xai-grok-cli",
                "Accept": "application/json",
            ]
        ), let plan = settings["subscription_tier_display"]?.string {
            snapshot = snapshot.with(planName: plan)
        }
        return snapshot
    }

    private func grokToken() -> String? {
        guard let json = SecretStore.readJSONFile(Home.path(".grok", "auth.json")) else { return nil }
        if let direct = json["access_token"]?.string ?? json["key"]?.string { return direct }
        if let object = json.object {
            for (_, value) in object {
                if let token = value["key"]?.string ?? value["access_token"]?.string {
                    return token
                }
            }
        }
        return nil
    }

    private func antigravity() async throws -> QuotaSnapshot {
        guard let token = antigravityToken() ?? geminiToken() else { throw CheckUsageError.missingCredentials }
        let urls = [
            "https://daily-cloudcode-pa.googleapis.com/v1internal:retrieveUserQuotaSummary",
            "https://cloudcode-pa.googleapis.com/v1internal:retrieveUserQuotaSummary",
        ]
        var lastError: Error = CheckUsageError.missingCredentials
        for url in urls {
            do {
                let json = try await HTTPClient.jsonObject(
                    url: URL(string: url)!,
                    method: "POST",
                    headers: [
                        "Authorization": "Bearer \(token)",
                        "Content-Type": "application/json",
                    ],
                    body: "{}".data(using: .utf8)
                )
                var snapshot = UsageParsers.gemini(json)
                snapshot = snapshot.with(planName: snapshot.planName)
                return snapshot
            } catch {
                lastError = error
            }
        }
        throw lastError
    }

    private func antigravityToken() -> String? {
        guard let raw = SecretStore.keychainPassword(service: "gemini", account: "antigravity") else { return nil }
        let cleaned = raw.hasPrefix("go-keyring-base64:") ? String(raw.dropFirst("go-keyring-base64:".count)) : raw
        if let data = Data(base64Encoded: cleaned), let text = String(data: data, encoding: .utf8), let json = SecretStore.jsonObject(from: text) {
            return json.path("token", "access_token")?.string ?? json["access_token"]?.string
        }
        return SecretStore.jsonObject(from: raw)?.path("token", "access_token")?.string
    }

    private func opencode() async throws -> QuotaSnapshot {
        guard let token = openCodeToken() else { throw CheckUsageError.missingCredentials }
        let json = try await HTTPClient.jsonObject(
            url: URL(string: "https://opencode.ai/zen/go/v1/usage")!,
            headers: [
                "Authorization": "Bearer \(token)",
                "Accept": "application/json",
            ]
        )
        return UsageParsers.openCode(json)
    }

    private func openCodeToken() -> String? {
        let json = SecretStore.readJSONFile(Home.path(".local", "share", "opencode", "auth.json"))
        return json?["opencode-go"]?.string
            ?? json?["opencode-go"]?["key"]?.string
            ?? json?["apiKey"]?.string
    }

    private func openrouter() async throws -> QuotaSnapshot {
        let key = openRouterKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else { throw CheckUsageError.missingAPIKey }
        let headers = [
            "Authorization": "Bearer \(key)",
            "Accept": "application/json",
        ]
        let credits = try await HTTPClient.jsonObject(url: URL(string: "https://openrouter.ai/api/v1/credits")!, headers: headers)
        let info = try? await HTTPClient.jsonObject(url: URL(string: "https://openrouter.ai/api/v1/key")!, headers: headers)
        return UsageParsers.openRouter(credits: credits, key: info)
    }

    private func deepseek() async throws -> QuotaSnapshot {
        let key = deepSeekKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else { throw CheckUsageError.missingAPIKey }
        let json = try await HTTPClient.jsonObject(
            url: URL(string: "https://api.deepseek.com/user/balance")!,
            headers: [
                "Authorization": "Bearer \(key)",
                "Accept": "application/json",
            ]
        )
        return UsageParsers.deepSeek(json)
    }

    private func zai() async throws -> QuotaSnapshot {
        let key = zaiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else { throw CheckUsageError.missingAPIKey }
        let json = try await HTTPClient.jsonObject(
            url: URL(string: "https://api.z.ai/api/monitor/usage/quota/limit")!,
            headers: [
                "Authorization": "Bearer \(key)",
                "Accept": "application/json",
            ]
        )
        return UsageParsers.zai(json)
    }
}
