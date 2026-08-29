import Foundation

enum AppLanguage: String, CaseIterable, Identifiable, Codable, Sendable {
    case system
    case en
    case ru
    case zhHans = "zh-Hans"
    case ja
    case de
    case es
    case fr
    case ptBR = "pt-BR"
    case ko

    var id: String { rawValue }

    var locale: Locale {
        switch self {
        case .system: .autoupdatingCurrent
        case .en: Locale(identifier: "en")
        case .ru: Locale(identifier: "ru")
        case .zhHans: Locale(identifier: "zh-Hans")
        case .ja: Locale(identifier: "ja")
        case .de: Locale(identifier: "de")
        case .es: Locale(identifier: "es")
        case .fr: Locale(identifier: "fr")
        case .ptBR: Locale(identifier: "pt-BR")
        case .ko: Locale(identifier: "ko")
        }
    }

    var nativeName: String {
        switch self {
        case .system: L10n.t("language_system")
        case .en: "English"
        case .ru: "Русский"
        case .zhHans: "简体中文"
        case .ja: "日本語"
        case .de: "Deutsch"
        case .es: "Español"
        case .fr: "Français"
        case .ptBR: "Português (Brasil)"
        case .ko: "한국어"
        }
    }
}

enum L10n {
    private static let lock = NSLock()
    nonisolated(unsafe) private static var _language: AppLanguage = .system

    static var language: AppLanguage {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _language
        }
        set {
            lock.lock()
            _language = newValue
            lock.unlock()
        }
    }

    private static let table: [String: [String: String]] = [
        "en": [
            "app_name": "CheckUsage",
            "usage_title": "%@ Usage",
            "current_session": "Current session",
            "all_models": "All models",
            "weekly": "Weekly",
            "weekly_opus": "Weekly Opus",
            "weekly_sonnet": "Weekly Sonnet",
            "weekly_fable": "Fable",
            "five_hour": "5-hour window",
            "daily": "Daily",
            "monthly": "Monthly",
            "plan": "Plan",
            "credits": "Credits",
            "extra_usage": "Extra usage",
            "on_demand": "On-demand",
            "auto_models": "Auto",
            "named_models": "Other models",
            "premium": "Premium",
            "used": "Used",
            "percent_used": "%@ Used",
            "remaining": "Remaining",
            "resets_in": "Resets in %@",
            "resets_at": "Resets %@",
            "no_reset": "No reset time",
            "not_signed_in": "Not signed in",
            "missing_key": "Add an API key in Settings",
            "unauthorized": "Session expired — open the official app to sign in again",
            "rate_limited": "Provider is throttling refreshes",
            "decode_error": "Could not read the usage response",
            "no_data": "No usage data",
            "retry": "Refresh",
            "settings": "Settings",
            "quit": "Quit CheckUsage",
            "show_panel": "Show panel",
            "hide_panel": "Hide panel",
            "providers": "Providers",
            "appearance": "Appearance",
            "language": "Language",
            "language_system": "System",
            "refresh_every": "Refresh every",
            "seconds": "seconds",
            "launch_at_login": "Open at login",
            "pin_panel": "Keep panel visible",
            "show_unsigned": "Show signed-out tools",
            "show_menubar_percent": "Show percent in menu bar",
            "api_keys": "API keys",
            "api_key_hint": "Stored only in your Keychain. Never uploaded.",
            "last_updated": "Updated %@",
            "open_settings": "Open Settings…",
            "about": "About",
            "privacy_note": "Tokens stay on this Mac. CheckUsage only talks to the provider that issued them.",
            "minutes_short": "%d min",
            "hours_minutes": "%dh %dm",
            "hours_short": "%dh",
            "sign_in_hint": "Sign in with the official CLI or app, then refresh.",
            "plan_label": "Plan: %@",
        ],
        "ru": [
            "app_name": "CheckUsage",
            "usage_title": "%@ — лимиты",
            "current_session": "Текущая сессия",
            "all_models": "Все модели",
            "weekly": "Неделя",
            "weekly_opus": "Неделя Opus",
            "weekly_sonnet": "Неделя Sonnet",
            "weekly_fable": "Fable",
            "five_hour": "Окно 5 часов",
            "daily": "День",
            "monthly": "Месяц",
            "plan": "План",
            "credits": "Кредиты",
            "extra_usage": "Дополнительно",
            "on_demand": "По запросу",
            "auto_models": "Авто",
            "named_models": "Другие модели",
            "premium": "Premium",
            "used": "Использовано",
            "percent_used": "%@ использовано",
            "remaining": "Осталось",
            "resets_in": "Сброс через %@",
            "resets_at": "Сброс %@",
            "no_reset": "Нет времени сброса",
            "not_signed_in": "Нет входа",
            "missing_key": "Добавьте ключ в Настройках",
            "unauthorized": "Сессия истекла — войдите в официальном приложении",
            "rate_limited": "Провайдер ограничивает обновления",
            "decode_error": "Не удалось прочитать ответ",
            "no_data": "Нет данных",
            "retry": "Обновить",
            "settings": "Настройки",
            "quit": "Выйти из CheckUsage",
            "show_panel": "Показать панель",
            "hide_panel": "Скрыть панель",
            "providers": "Провайдеры",
            "appearance": "Вид",
            "language": "Язык",
            "language_system": "Системный",
            "refresh_every": "Обновлять каждые",
            "seconds": "секунд",
            "launch_at_login": "Запускать при входе",
            "pin_panel": "Держать панель на экране",
            "show_unsigned": "Показывать без входа",
            "show_menubar_percent": "Процент в строке меню",
            "api_keys": "API-ключи",
            "api_key_hint": "Только в связке ключей. Никуда не отправляются.",
            "last_updated": "Обновлено %@",
            "open_settings": "Открыть настройки…",
            "about": "О программе",
            "privacy_note": "Токены остаются на этом Mac. CheckUsage ходит только к тому провайдеру, который их выдал.",
            "minutes_short": "%d мин",
            "hours_minutes": "%d ч %d мин",
            "hours_short": "%d ч",
            "sign_in_hint": "Войдите в официальном CLI или приложении, затем обновите.",
            "plan_label": "План: %@",
        ],
        "zh-Hans": [
            "app_name": "CheckUsage",
            "usage_title": "%@ 用量",
            "current_session": "当前会话",
            "all_models": "全部模型",
            "weekly": "每周",
            "weekly_opus": "每周 Opus",
            "weekly_sonnet": "每周 Sonnet",
            "weekly_fable": "Fable",
            "five_hour": "5 小时窗口",
            "daily": "每日",
            "monthly": "每月",
            "plan": "套餐",
            "credits": "积分",
            "extra_usage": "额外用量",
            "on_demand": "按需",
            "auto_models": "自动模型",
            "named_models": "指定模型",
            "premium": "Premium",
            "used": "已用",
            "percent_used": "已用 %@",
            "remaining": "剩余",
            "resets_in": "%@ 后重置",
            "resets_at": "重置时间 %@",
            "no_reset": "无重置时间",
            "not_signed_in": "未登录",
            "missing_key": "请在设置中添加 API 密钥",
            "unauthorized": "会话已过期，请在官方应用中重新登录",
            "rate_limited": "提供商正在限制刷新",
            "decode_error": "无法解析用量数据",
            "no_data": "暂无数据",
            "retry": "刷新",
            "settings": "设置",
            "quit": "退出 CheckUsage",
            "show_panel": "显示面板",
            "hide_panel": "隐藏面板",
            "providers": "服务",
            "appearance": "外观",
            "language": "语言",
            "language_system": "跟随系统",
            "refresh_every": "刷新间隔",
            "seconds": "秒",
            "launch_at_login": "登录时打开",
            "pin_panel": "保持面板可见",
            "show_unsigned": "显示未登录的服务",
            "show_menubar_percent": "在菜单栏显示百分比",
            "api_keys": "API 密钥",
            "api_key_hint": "仅保存在钥匙串，不会上传。",
            "last_updated": "更新于 %@",
            "open_settings": "打开设置…",
            "about": "关于",
            "privacy_note": "令牌只留在本机。CheckUsage 只会请求签发该令牌的服务。",
            "minutes_short": "%d 分钟",
            "hours_minutes": "%d 小时 %d 分",
            "hours_short": "%d 小时",
            "sign_in_hint": "请先在官方 CLI 或应用中登录，然后刷新。",
            "plan_label": "套餐：%@",
        ],
        "ja": [
            "app_name": "CheckUsage",
            "usage_title": "%@ の使用量",
            "current_session": "現在のセッション",
            "all_models": "全モデル",
            "weekly": "週間",
            "weekly_opus": "週間 Opus",
            "weekly_sonnet": "週間 Sonnet",
            "weekly_fable": "Fable",
            "five_hour": "5時間枠",
            "daily": "日間",
            "monthly": "月間",
            "plan": "プラン",
            "credits": "クレジット",
            "extra_usage": "追加利用",
            "on_demand": "従量",
            "auto_models": "自動モデル",
            "named_models": "指定モデル",
            "premium": "Premium",
            "used": "使用済み",
            "percent_used": "%@ 使用",
            "remaining": "残り",
            "resets_in": "%@ 後にリセット",
            "resets_at": "リセット %@",
            "no_reset": "リセット時刻なし",
            "not_signed_in": "未ログイン",
            "missing_key": "設定で API キーを追加",
            "unauthorized": "セッション期限切れ。公式アプリで再ログイン",
            "rate_limited": "更新が制限されています",
            "decode_error": "使用量を読めませんでした",
            "no_data": "データなし",
            "retry": "更新",
            "settings": "設定",
            "quit": "CheckUsage を終了",
            "show_panel": "パネルを表示",
            "hide_panel": "パネルを隠す",
            "providers": "プロバイダー",
            "appearance": "外観",
            "language": "言語",
            "language_system": "システム",
            "refresh_every": "更新間隔",
            "seconds": "秒",
            "launch_at_login": "ログイン時に開く",
            "pin_panel": "パネルを常に表示",
            "show_unsigned": "未ログインも表示",
            "show_menubar_percent": "メニューバーに％を表示",
            "api_keys": "API キー",
            "api_key_hint": "キーチェーンにのみ保存。送信しません。",
            "last_updated": "更新 %@",
            "open_settings": "設定を開く…",
            "about": "このアプリについて",
            "privacy_note": "トークンはこの Mac に残ります。発行元のサービスにだけ問い合わせます。",
            "minutes_short": "%d分",
            "hours_minutes": "%d時間%d分",
            "hours_short": "%d時間",
            "sign_in_hint": "公式 CLI かアプリでログインしてから更新してください。",
            "plan_label": "プラン: %@",
        ],
        "de": [
            "app_name": "CheckUsage",
            "usage_title": "%@-Nutzung",
            "current_session": "Aktuelle Sitzung",
            "all_models": "Alle Modelle",
            "weekly": "Wöchentlich",
            "weekly_opus": "Wöchentlich Opus",
            "weekly_sonnet": "Wöchentlich Sonnet",
            "weekly_fable": "Fable",
            "five_hour": "5-Stunden-Fenster",
            "daily": "Täglich",
            "monthly": "Monatlich",
            "plan": "Tarif",
            "credits": "Credits",
            "extra_usage": "Zusatzkontingent",
            "on_demand": "On-Demand",
            "auto_models": "Auto-Modelle",
            "named_models": "Benannte Modelle",
            "premium": "Premium",
            "used": "Verbraucht",
            "percent_used": "%@ verbraucht",
            "remaining": "Übrig",
            "resets_in": "Reset in %@",
            "resets_at": "Reset %@",
            "no_reset": "Keine Reset-Zeit",
            "not_signed_in": "Nicht angemeldet",
            "missing_key": "API-Schlüssel in den Einstellungen hinterlegen",
            "unauthorized": "Sitzung abgelaufen – in der offiziellen App anmelden",
            "rate_limited": "Anbieter drosselt Aktualisierungen",
            "decode_error": "Nutzungsantwort unlesbar",
            "no_data": "Keine Daten",
            "retry": "Aktualisieren",
            "settings": "Einstellungen",
            "quit": "CheckUsage beenden",
            "show_panel": "Leiste zeigen",
            "hide_panel": "Leiste ausblenden",
            "providers": "Anbieter",
            "appearance": "Darstellung",
            "language": "Sprache",
            "language_system": "System",
            "refresh_every": "Aktualisieren alle",
            "seconds": "Sekunden",
            "launch_at_login": "Bei Anmeldung öffnen",
            "pin_panel": "Leiste sichtbar halten",
            "show_unsigned": "Abgemeldete Tools zeigen",
            "show_menubar_percent": "Prozent in der Menüleiste",
            "api_keys": "API-Schlüssel",
            "api_key_hint": "Nur im Schlüsselbund. Wird nicht hochgeladen.",
            "last_updated": "Aktualisiert %@",
            "open_settings": "Einstellungen öffnen …",
            "about": "Über",
            "privacy_note": "Tokens bleiben auf diesem Mac. CheckUsage spricht nur den ausstellenden Anbieter an.",
            "minutes_short": "%d Min.",
            "hours_minutes": "%d Std. %d Min.",
            "hours_short": "%d Std.",
            "sign_in_hint": "In der offiziellen CLI oder App anmelden, dann aktualisieren.",
            "plan_label": "Tarif: %@",
        ],
        "es": [
            "app_name": "CheckUsage",
            "usage_title": "Uso de %@",
            "current_session": "Sesión actual",
            "all_models": "Todos los modelos",
            "weekly": "Semanal",
            "weekly_opus": "Opus semanal",
            "weekly_sonnet": "Sonnet semanal",
            "weekly_fable": "Fable",
            "five_hour": "Ventana de 5 horas",
            "daily": "Diario",
            "monthly": "Mensual",
            "plan": "Plan",
            "credits": "Créditos",
            "extra_usage": "Uso extra",
            "on_demand": "Bajo demanda",
            "auto_models": "Modelos auto",
            "named_models": "Modelos con nombre",
            "premium": "Premium",
            "used": "Usado",
            "percent_used": "%@ usado",
            "remaining": "Restante",
            "resets_in": "Se reinicia en %@",
            "resets_at": "Reinicio %@",
            "no_reset": "Sin hora de reinicio",
            "not_signed_in": "Sin sesión",
            "missing_key": "Añade una clave API en Ajustes",
            "unauthorized": "Sesión caducada: entra en la app oficial",
            "rate_limited": "El proveedor limita las actualizaciones",
            "decode_error": "No se pudo leer el uso",
            "no_data": "Sin datos",
            "retry": "Actualizar",
            "settings": "Ajustes",
            "quit": "Salir de CheckUsage",
            "show_panel": "Mostrar panel",
            "hide_panel": "Ocultar panel",
            "providers": "Proveedores",
            "appearance": "Apariencia",
            "language": "Idioma",
            "language_system": "Sistema",
            "refresh_every": "Actualizar cada",
            "seconds": "segundos",
            "launch_at_login": "Abrir al iniciar sesión",
            "pin_panel": "Mantener el panel visible",
            "show_unsigned": "Mostrar herramientas sin sesión",
            "show_menubar_percent": "Mostrar porcentaje en la barra",
            "api_keys": "Claves API",
            "api_key_hint": "Solo en el llavero. No se suben.",
            "last_updated": "Actualizado %@",
            "open_settings": "Abrir ajustes…",
            "about": "Acerca de",
            "privacy_note": "Los tokens se quedan en este Mac. CheckUsage solo habla con quien los emitió.",
            "minutes_short": "%d min",
            "hours_minutes": "%d h %d min",
            "hours_short": "%d h",
            "sign_in_hint": "Inicia sesión en la CLI o app oficial y actualiza.",
            "plan_label": "Plan: %@",
        ],
        "fr": [
            "app_name": "CheckUsage",
            "usage_title": "Usage %@",
            "current_session": "Session en cours",
            "all_models": "Tous les modèles",
            "weekly": "Hebdomadaire",
            "weekly_opus": "Opus hebdo",
            "weekly_sonnet": "Sonnet hebdo",
            "weekly_fable": "Fable",
            "five_hour": "Fenêtre 5 h",
            "daily": "Quotidien",
            "monthly": "Mensuel",
            "plan": "Offre",
            "credits": "Crédits",
            "extra_usage": "Usage extra",
            "on_demand": "À la demande",
            "auto_models": "Modèles auto",
            "named_models": "Modèles nommés",
            "premium": "Premium",
            "used": "Utilisé",
            "percent_used": "%@ utilisé",
            "remaining": "Restant",
            "resets_in": "Réinit. dans %@",
            "resets_at": "Réinit. %@",
            "no_reset": "Pas d’heure de reset",
            "not_signed_in": "Non connecté",
            "missing_key": "Ajoutez une clé API dans Réglages",
            "unauthorized": "Session expirée — reconnectez-vous dans l’app officielle",
            "rate_limited": "Le fournisseur limite les rafraîchissements",
            "decode_error": "Réponse d’usage illisible",
            "no_data": "Aucune donnée",
            "retry": "Actualiser",
            "settings": "Réglages",
            "quit": "Quitter CheckUsage",
            "show_panel": "Afficher le panneau",
            "hide_panel": "Masquer le panneau",
            "providers": "Fournisseurs",
            "appearance": "Apparence",
            "language": "Langue",
            "language_system": "Système",
            "refresh_every": "Actualiser toutes les",
            "seconds": "secondes",
            "launch_at_login": "Ouvrir à la connexion",
            "pin_panel": "Garder le panneau visible",
            "show_unsigned": "Afficher les outils déconnectés",
            "show_menubar_percent": "Afficher le % dans la barre",
            "api_keys": "Clés API",
            "api_key_hint": "Uniquement dans le trousseau. Jamais envoyées ailleurs.",
            "last_updated": "Mis à jour %@",
            "open_settings": "Ouvrir les réglages…",
            "about": "À propos",
            "privacy_note": "Les jetons restent sur ce Mac. CheckUsage n’interroge que l’émetteur.",
            "minutes_short": "%d min",
            "hours_minutes": "%d h %d min",
            "hours_short": "%d h",
            "sign_in_hint": "Connectez-vous via le CLI ou l’app officielle, puis actualisez.",
            "plan_label": "Offre : %@",
        ],
        "pt-BR": [
            "app_name": "CheckUsage",
            "usage_title": "Uso do %@",
            "current_session": "Sessão atual",
            "all_models": "Todos os modelos",
            "weekly": "Semanal",
            "weekly_opus": "Opus semanal",
            "weekly_sonnet": "Sonnet semanal",
            "weekly_fable": "Fable",
            "five_hour": "Janela de 5 horas",
            "daily": "Diário",
            "monthly": "Mensal",
            "plan": "Plano",
            "credits": "Créditos",
            "extra_usage": "Uso extra",
            "on_demand": "Sob demanda",
            "auto_models": "Modelos auto",
            "named_models": "Modelos nomeados",
            "premium": "Premium",
            "used": "Usado",
            "percent_used": "%@ usado",
            "remaining": "Restante",
            "resets_in": "Reinicia em %@",
            "resets_at": "Reinício %@",
            "no_reset": "Sem horário de reset",
            "not_signed_in": "Não conectado",
            "missing_key": "Adicione uma chave API em Ajustes",
            "unauthorized": "Sessão expirada — entre no app oficial",
            "rate_limited": "O provedor está limitando atualizações",
            "decode_error": "Não foi possível ler o uso",
            "no_data": "Sem dados",
            "retry": "Atualizar",
            "settings": "Ajustes",
            "quit": "Sair do CheckUsage",
            "show_panel": "Mostrar painel",
            "hide_panel": "Ocultar painel",
            "providers": "Provedores",
            "appearance": "Aparência",
            "language": "Idioma",
            "language_system": "Sistema",
            "refresh_every": "Atualizar a cada",
            "seconds": "segundos",
            "launch_at_login": "Abrir no login",
            "pin_panel": "Manter o painel visível",
            "show_unsigned": "Mostrar ferramentas desconectadas",
            "show_menubar_percent": "Mostrar porcentagem na barra",
            "api_keys": "Chaves API",
            "api_key_hint": "Só no Keychain. Nada é enviado.",
            "last_updated": "Atualizado %@",
            "open_settings": "Abrir ajustes…",
            "about": "Sobre",
            "privacy_note": "Os tokens ficam neste Mac. O CheckUsage só fala com quem os emitiu.",
            "minutes_short": "%d min",
            "hours_minutes": "%dh %dmin",
            "hours_short": "%dh",
            "sign_in_hint": "Entre no CLI ou app oficial e atualize.",
            "plan_label": "Plano: %@",
        ],
        "ko": [
            "app_name": "CheckUsage",
            "usage_title": "%@ 사용량",
            "current_session": "현재 세션",
            "all_models": "모든 모델",
            "weekly": "주간",
            "weekly_opus": "주간 Opus",
            "weekly_sonnet": "주간 Sonnet",
            "weekly_fable": "Fable",
            "five_hour": "5시간 창",
            "daily": "일간",
            "monthly": "월간",
            "plan": "플랜",
            "credits": "크레딧",
            "extra_usage": "추가 사용량",
            "on_demand": "온디맨드",
            "auto_models": "자동 모델",
            "named_models": "지정 모델",
            "premium": "Premium",
            "used": "사용됨",
            "percent_used": "%@ 사용",
            "remaining": "남음",
            "resets_in": "%@ 후 초기화",
            "resets_at": "초기화 %@",
            "no_reset": "초기화 시간 없음",
            "not_signed_in": "로그인되지 않음",
            "missing_key": "설정에서 API 키를 추가하세요",
            "unauthorized": "세션이 만료됨 — 공식 앱에서 다시 로그인",
            "rate_limited": "제공자가 새로고침을 제한 중",
            "decode_error": "사용량 응답을 읽을 수 없음",
            "no_data": "데이터 없음",
            "retry": "새로고침",
            "settings": "설정",
            "quit": "CheckUsage 종료",
            "show_panel": "패널 표시",
            "hide_panel": "패널 숨기기",
            "providers": "제공자",
            "appearance": "모양",
            "language": "언어",
            "language_system": "시스템",
            "refresh_every": "새로고침 주기",
            "seconds": "초",
            "launch_at_login": "로그인 시 열기",
            "pin_panel": "패널 항상 표시",
            "show_unsigned": "로그아웃된 도구 표시",
            "show_menubar_percent": "메뉴 막대에 비율 표시",
            "api_keys": "API 키",
            "api_key_hint": "키체인에만 저장됩니다. 업로드하지 않습니다.",
            "last_updated": "업데이트 %@",
            "open_settings": "설정 열기…",
            "about": "정보",
            "privacy_note": "토큰은 이 Mac에 남습니다. CheckUsage는 발급한 제공자에게만 요청합니다.",
            "minutes_short": "%d분",
            "hours_minutes": "%d시간 %d분",
            "hours_short": "%d시간",
            "sign_in_hint": "공식 CLI나 앱에서 로그인한 뒤 새로고침하세요.",
            "plan_label": "플랜: %@",
        ],
    ]

    static var resolvedCode: String {
        if language != .system {
            return language.rawValue
        }
        let preferred = Locale.preferredLanguages.first ?? "en"
        if preferred.hasPrefix("zh") { return "zh-Hans" }
        if preferred.hasPrefix("pt") { return "pt-BR" }
        let short = String(preferred.prefix(2))
        if table[short] != nil { return short }
        if table[preferred] != nil { return preferred }
        return "en"
    }

    static func t(_ key: String) -> String {
        let code = resolvedCode
        return ExtraL10n.table[code]?[key]
            ?? table[code]?[key]
            ?? ExtraL10n.table["en"]?[key]
            ?? table["en"]?[key]
            ?? key
    }

    static func format(_ key: String, _ args: CVarArg...) -> String {
        String(format: t(key), locale: language.locale, arguments: args)
    }
}

enum ResetCopy {
    static func format(reset: Date?, now: Date = Date()) -> String {
        guard let reset else { return L10n.t("no_reset") }
        let remaining = reset.timeIntervalSince(now)
        if remaining <= 0 {
            return L10n.t("retry")
        }
        if remaining < 3600 {
            let minutes = max(1, Int(remaining / 60))
            return L10n.format("resets_in", L10n.format("minutes_short", minutes))
        }
        if remaining < 24 * 3600 {
            let hours = Int(remaining / 3600)
            let minutes = Int((remaining.truncatingRemainder(dividingBy: 3600)) / 60)
            let span = minutes == 0
                ? L10n.format("hours_short", hours)
                : L10n.format("hours_minutes", hours, minutes)
            return L10n.format("resets_in", span)
        }
        if remaining < 7 * 24 * 3600 {
            let days = max(1, Int((remaining / 86400).rounded()))
            return L10n.format("resets_in", L10n.format("days_short", days))
        }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: L10n.resolvedCode)
        formatter.setLocalizedDateFormatFromTemplate("MMMd")
        return L10n.format("resets_at", formatter.string(from: reset))
    }

    static func updated(_ date: Date, now: Date = Date()) -> String {
        let elapsed = now.timeIntervalSince(date)
        if elapsed < 45 {
            return L10n.t("just_now")
        }
        if elapsed < 3600 {
            return L10n.format("last_updated", L10n.format("minutes_short", max(1, Int(elapsed / 60))))
        }
        if elapsed < 24 * 3600 {
            return L10n.format("last_updated", L10n.format("hours_short", max(1, Int(elapsed / 3600))))
        }
        return L10n.format("last_updated", L10n.format("days_short", max(1, Int(elapsed / 86400))))
    }

    static let shortWindow: TimeInterval = 6 * 3600

    static func compact(reset: Date?, now: Date = Date()) -> String? {
        guard let reset else { return nil }
        let remaining = reset.timeIntervalSince(now)
        guard remaining > 0, remaining < shortWindow else { return nil }
        if remaining < 3600 {
            return L10n.format("ring_mins", max(1, Int(remaining / 60)))
        }
        return L10n.format("ring_hours", max(1, Int(remaining / 3600)))
    }
}
