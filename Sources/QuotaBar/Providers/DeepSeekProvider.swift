import Foundation

struct DeepSeekProvider: QuotaProvider {
    let id = ProviderID.deepSeek

    private let keychain: KeychainStore
    private let client: SecureHTTPClient

    init(keychain: KeychainStore, client: SecureHTTPClient) {
        self.keychain = keychain
        self.client = client
    }

    func fetchSnapshot() async throws -> ProviderSnapshot {
        guard let apiKey = try keychain.read(.deepSeekAPIKey), !apiKey.isEmpty else {
            throw ProviderError.missingCredential("DeepSeek API Key")
        }
        guard let url = URL(string: "https://api.deepseek.com/user/balance") else {
            throw ProviderError.invalidEndpoint
        }

        let data = try await client.get(url, bearerToken: apiKey)
        let response = try JSONDecoder().decode(DeepSeekBalanceResponse.self, from: data)
        guard let primary = response.balanceInfos.first else {
            throw ProviderError.invalidResponse
        }

        let currency = primary.currency.uppercased()
        let total = primary.totalBalance.doubleValue
        let toppedUp = primary.toppedUpBalance.doubleValue
        let granted = primary.grantedBalance.doubleValue

        return ProviderSnapshot(
            provider: id,
            health: response.isAvailable ? .healthy : .critical,
            headline: DisplayMetric(
                label: "总余额",
                value: MetricFormatting.money(total, currency: currency),
                detail: response.isAvailable ? "可用于 API 调用" : "余额不可用"
            ),
            metrics: [
                DisplayMetric(label: "充值余额", value: MetricFormatting.money(toppedUp, currency: currency)),
                DisplayMetric(label: "赠送余额", value: MetricFormatting.money(granted, currency: currency))
            ],
            progress: nil,
            plan: nil,
            updatedAt: Date()
        )
    }
}

private struct DeepSeekBalanceResponse: Decodable {
    let isAvailable: Bool
    let balanceInfos: [DeepSeekBalanceInfo]

    enum CodingKeys: String, CodingKey {
        case isAvailable = "is_available"
        case balanceInfos = "balance_infos"
    }
}

private struct DeepSeekBalanceInfo: Decodable {
    let currency: String
    let totalBalance: String
    let grantedBalance: String
    let toppedUpBalance: String

    enum CodingKeys: String, CodingKey {
        case currency
        case totalBalance = "total_balance"
        case grantedBalance = "granted_balance"
        case toppedUpBalance = "topped_up_balance"
    }
}

private extension String {
    var doubleValue: Double {
        Double(self) ?? 0
    }
}
