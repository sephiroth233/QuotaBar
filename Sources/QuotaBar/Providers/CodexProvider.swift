import Foundation

struct CodexProvider: QuotaProvider {
    let id = ProviderID.codex

    private let authReader: CodexAuthContextReader
    private let client: SecureHTTPClient

    init(authReader: CodexAuthContextReader, client: SecureHTTPClient) {
        self.authReader = authReader
        self.client = client
    }

    func fetchSnapshot() async throws -> ProviderSnapshot {
        let context = try authReader.read()
        let headers = context.accountID.map { ["ChatGPT-Account-Id": $0] } ?? [:]

        async let usageData = fetch(
            "https://chatgpt.com/backend-api/wham/usage",
            context: context,
            headers: headers
        )
        async let resetData = fetch(
            "https://chatgpt.com/backend-api/wham/rate-limit-reset-credits",
            context: context,
            headers: headers
        )

        let usage = try decodeUsage(await usageData)
        let resetCount = try? decodeResetCount(await resetData)
        guard let weekly = usage.weeklyWindow else {
            throw ProviderError.message("Codex 当前没有返回可识别的周额度。")
        }

        let remainingFraction = max(0, min(1, 1 - weekly.usedPercent / 100))
        let resetAt = weekly.resetDate
        var metrics: [DisplayMetric] = []

        if let resetAt {
            metrics.append(
                DisplayMetric(
                    label: "周额度重置",
                    value: MetricFormatting.relativeReset(resetAt),
                    detail: resetAt.formatted(date: .abbreviated, time: .shortened)
                )
            )
        }
        if let resetCount {
            metrics.append(DisplayMetric(label: "Reset 次数", value: "\(resetCount)"))
        }

        return ProviderSnapshot(
            provider: id,
            health: MetricFormatting.health(forRemainingFraction: remainingFraction),
            headline: DisplayMetric(
                label: "Weekly 剩余",
                value: MetricFormatting.percentage(from: remainingFraction),
                detail: weekly.limitReached ? "当前额度已受限" : "本周可用"
            ),
            metrics: metrics,
            progress: ProgressMetric(
                label: "Weekly",
                remainingFraction: remainingFraction,
                resetAt: resetAt
            ),
            plan: usage.planType?.localizedPlanName,
            updatedAt: Date()
        )
    }

    private func fetch(
        _ urlString: String,
        context: CodexAuthContext,
        headers: [String: String]
    ) async throws -> Data {
        guard let url = URL(string: urlString) else {
            throw ProviderError.invalidEndpoint
        }
        return try await client.get(url, bearerToken: context.accessToken, headers: headers)
    }

    private func decodeUsage(_ data: Data) throws -> DecodedCodexUsage {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let response = try decoder.decode(CodexUsageResponse.self, from: data)

        let windows = [
            response.rateLimit?.primaryWindow,
            response.rateLimit?.secondaryWindow
        ].compactMap { $0 }

        let weekly = windows
            .filter { ($0.limitWindowSeconds ?? 0) >= 86_400 }
            .max { ($0.limitWindowSeconds ?? 0) < ($1.limitWindowSeconds ?? 0) }
            ?? windows.max { ($0.limitWindowSeconds ?? 0) < ($1.limitWindowSeconds ?? 0) }

        return DecodedCodexUsage(
            planType: response.planType,
            weeklyWindow: weekly.map {
                DecodedCodexWindow(
                    usedPercent: $0.usedPercent,
                    resetDate: $0.resetDate,
                    limitReached: response.rateLimit?.limitReached ?? false
                )
            }
        )
    }

    private func decodeResetCount(_ data: Data) throws -> Int? {
        let root = try JSONSerialization.jsonObject(with: data)
        return findInteger(
            keys: ["available_count", "total_count", "remaining_count", "count"],
            in: root
        )
    }

    private func findInteger(keys: Set<String>, in value: Any) -> Int? {
        if let dictionary = value as? [String: Any] {
            for key in keys {
                if let number = dictionary[key] as? NSNumber {
                    return number.intValue
                }
            }
            for child in dictionary.values {
                if let match = findInteger(keys: keys, in: child) {
                    return match
                }
            }
        } else if let array = value as? [Any] {
            for child in array {
                if let match = findInteger(keys: keys, in: child) {
                    return match
                }
            }
        }
        return nil
    }
}

private struct CodexUsageResponse: Decodable {
    let planType: String?
    let rateLimit: CodexRateLimit?
}

private struct CodexRateLimit: Decodable {
    let limitReached: Bool?
    let primaryWindow: CodexUsageWindow?
    let secondaryWindow: CodexUsageWindow?
}

private struct CodexUsageWindow: Decodable {
    let usedPercent: Double
    let limitWindowSeconds: Double?
    let resetAfterSeconds: Double?
    let resetAt: Double?

    var resetDate: Date? {
        if let resetAt, resetAt > 0 {
            return Date(timeIntervalSince1970: resetAt)
        }
        if let resetAfterSeconds, resetAfterSeconds > 0 {
            return Date().addingTimeInterval(resetAfterSeconds)
        }
        return nil
    }
}

private struct DecodedCodexUsage {
    let planType: String?
    let weeklyWindow: DecodedCodexWindow?
}

private struct DecodedCodexWindow {
    let usedPercent: Double
    let resetDate: Date?
    let limitReached: Bool
}

private extension String {
    var localizedPlanName: String {
        switch lowercased() {
        case "plus": "Plus"
        case "pro": "Pro"
        case "team": "Team"
        case "business": "Business"
        case "enterprise": "Enterprise"
        case "free": "Free"
        default: capitalized
        }
    }
}
