import Foundation

struct OpenRouterProvider: QuotaProvider {
    let id = ProviderID.openRouter

    private let keychain: KeychainStore
    private let client: SecureHTTPClient

    init(keychain: KeychainStore, client: SecureHTTPClient) {
        self.keychain = keychain
        self.client = client
    }

    func fetchSnapshot() async throws -> ProviderSnapshot {
        let apiKey = try keychain.read(.openRouterAPIKey)
        let managementKey = try keychain.read(.openRouterManagementKey)

        guard apiKey != nil || managementKey != nil else {
            throw ProviderError.missingCredential("OpenRouter API Key")
        }

        var keyInfo: OpenRouterKeyInfo?
        var accountCredits: OpenRouterCredits?
        var accountCreditFailed = false

        if let apiKey, !apiKey.isEmpty {
            keyInfo = try await fetchKeyInfo(apiKey: apiKey)
        }

        if let managementKey, !managementKey.isEmpty {
            do {
                accountCredits = try await fetchCredits(managementKey: managementKey)
            } catch {
                if keyInfo == nil { throw error }
                accountCreditFailed = true
            }
        }

        let accountRemaining = accountCredits.map { $0.totalCredits - $0.totalUsage }
        let keyRemaining = keyInfo?.limitRemaining
        let headlineValue: String
        let headlineDetail: String

        if let accountRemaining {
            headlineValue = MetricFormatting.money(accountRemaining, currency: "USD")
            headlineDetail = "账户可用余额"
        } else if let keyRemaining {
            headlineValue = MetricFormatting.money(keyRemaining, currency: "USD")
            headlineDetail = "当前 Key 可用额度"
        } else {
            headlineValue = "未设置上限"
            headlineDetail = "当前 Key"
        }

        var metrics: [DisplayMetric] = []
        if let weekly = keyInfo?.usageWeekly {
            metrics.append(DisplayMetric(label: "本周使用", value: MetricFormatting.money(weekly, currency: "USD")))
        }
        if let totalUsage = accountCredits?.totalUsage {
            metrics.append(DisplayMetric(label: "累计使用", value: MetricFormatting.money(totalUsage, currency: "USD")))
        }
        if accountCreditFailed {
            metrics.append(DisplayMetric(label: "账户余额", value: "查询失败", detail: "检查 Management Key"))
        }

        let progress = keyInfo.flatMap { info -> ProgressMetric? in
            guard let limit = info.limit, limit > 0, let remaining = info.limitRemaining else { return nil }
            return ProgressMetric(
                label: "Key 可用额度",
                remainingFraction: remaining / limit,
                resetAt: nil
            )
        }
        let health = progress.map { MetricFormatting.health(forRemainingFraction: $0.clampedRemainingFraction) }
            ?? (accountCreditFailed ? .warning : .healthy)

        return ProviderSnapshot(
            provider: id,
            health: health,
            headline: DisplayMetric(label: "余额", value: headlineValue, detail: headlineDetail),
            metrics: metrics,
            progress: progress,
            plan: keyInfo?.limitReset?.localizedResetName,
            updatedAt: Date()
        )
    }

    private func fetchKeyInfo(apiKey: String) async throws -> OpenRouterKeyInfo {
        guard let url = URL(string: "https://openrouter.ai/api/v1/key") else {
            throw ProviderError.invalidEndpoint
        }
        let data = try await client.get(url, bearerToken: apiKey)
        return try JSONDecoder().decode(OpenRouterKeyResponse.self, from: data).data
    }

    private func fetchCredits(managementKey: String) async throws -> OpenRouterCredits {
        guard let url = URL(string: "https://openrouter.ai/api/v1/credits") else {
            throw ProviderError.invalidEndpoint
        }
        let data = try await client.get(url, bearerToken: managementKey)
        return try JSONDecoder().decode(OpenRouterCreditsResponse.self, from: data).data
    }
}

private struct OpenRouterKeyResponse: Decodable {
    let data: OpenRouterKeyInfo
}

private struct OpenRouterKeyInfo: Decodable {
    let limit: Double?
    let limitRemaining: Double?
    let limitReset: String?
    let usageWeekly: Double?

    enum CodingKeys: String, CodingKey {
        case limit
        case limitRemaining = "limit_remaining"
        case limitReset = "limit_reset"
        case usageWeekly = "usage_weekly"
    }
}

private struct OpenRouterCreditsResponse: Decodable {
    let data: OpenRouterCredits
}

private struct OpenRouterCredits: Decodable {
    let totalCredits: Double
    let totalUsage: Double

    enum CodingKeys: String, CodingKey {
        case totalCredits = "total_credits"
        case totalUsage = "total_usage"
    }
}

private extension String {
    var localizedResetName: String {
        switch lowercased() {
        case "daily": "每日重置"
        case "weekly": "每周重置"
        case "monthly": "每月重置"
        default: self
        }
    }
}
