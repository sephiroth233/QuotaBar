import Foundation

enum ProviderID: String, CaseIterable, Codable, Hashable, Identifiable, Sendable {
    case codex
    case openRouter
    case deepSeek

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .codex: "Codex"
        case .openRouter: "OpenRouter"
        case .deepSeek: "DeepSeek"
        }
    }

    var symbolName: String {
        switch self {
        case .codex: "chevron.left.forwardslash.chevron.right"
        case .openRouter: "point.3.connected.trianglepath.dotted"
        case .deepSeek: "wave.3.right.circle"
        }
    }

    var brandAssetName: String {
        switch self {
        case .codex: "ChatGPT"
        case .openRouter: "OpenRouter"
        case .deepSeek: "DeepSeek"
        }
    }
}

enum ProviderHealth: String, Codable, Hashable, Sendable {
    case healthy
    case warning
    case critical
    case unavailable
}

struct DisplayMetric: Codable, Hashable, Sendable {
    let label: String
    let value: String
    let detail: String?

    init(label: String, value: String, detail: String? = nil) {
        self.label = label
        self.value = value
        self.detail = detail
    }
}

struct ProgressMetric: Codable, Hashable, Sendable {
    let label: String
    let remainingFraction: Double
    let resetAt: Date?

    var clampedRemainingFraction: Double {
        min(max(remainingFraction, 0), 1)
    }
}

struct ProviderSnapshot: Codable, Hashable, Identifiable, Sendable {
    let provider: ProviderID
    let health: ProviderHealth
    let headline: DisplayMetric
    let metrics: [DisplayMetric]
    let progress: ProgressMetric?
    let plan: String?
    let updatedAt: Date

    var id: ProviderID { provider }
}

struct ProviderFetchResult: Sendable {
    let provider: ProviderID
    let snapshot: ProviderSnapshot?
    let errorMessage: String?
}

enum ProviderError: LocalizedError, Sendable {
    case missingCredential(String)
    case signedOut(String)
    case invalidEndpoint
    case invalidResponse
    case httpStatus(Int)
    case message(String)

    var errorDescription: String? {
        switch self {
        case .missingCredential(let name): "请在设置中配置\(name)。"
        case .signedOut(let message): message
        case .invalidEndpoint: "请求地址未通过安全检查。"
        case .invalidResponse: "服务返回了无法识别的数据。"
        case .httpStatus(401): "认证已过期或密钥无效。"
        case .httpStatus(403): "当前密钥没有查询权限。"
        case .httpStatus(429): "请求过于频繁，请稍后刷新。"
        case .httpStatus(let status): "服务返回 HTTP \(status)。"
        case .message(let message): message
        }
    }
}
