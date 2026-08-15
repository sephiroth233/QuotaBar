import Foundation

@MainActor
final class QuotaStore: ObservableObject {
    @Published private(set) var snapshots: [ProviderID: ProviderSnapshot] = [:]
    @Published private(set) var errors: [ProviderID: String] = [:]
    @Published private(set) var isRefreshing = false
    @Published private(set) var lastRefresh: Date?

    let keychain: KeychainStore

    private let providers: [any QuotaProvider]
    private var refreshLoop: Task<Void, Never>?

    init() {
        let keychain = KeychainStore()
        let client = SecureHTTPClient()
        self.keychain = keychain
        providers = [
            CodexProvider(authReader: CodexAuthContextReader(), client: client),
            OpenRouterProvider(keychain: keychain, client: client),
            DeepSeekProvider(keychain: keychain, client: client)
        ]

        refreshLoop = Task { [weak self] in
            guard let self else { return }
            await refresh()
            while !Task.isCancelled {
                let minutes = UserDefaults.standard.double(forKey: "refreshIntervalMinutes")
                let effectiveMinutes = minutes > 0 ? minutes : 10
                try? await Task.sleep(for: .seconds(effectiveMinutes * 60))
                guard !Task.isCancelled else { return }
                await refresh()
            }
        }
    }

    deinit {
        refreshLoop?.cancel()
    }

    var orderedProviderIDs: [ProviderID] {
        [.codex, .openRouter, .deepSeek]
    }

    var menuBarTitle: String {
        if let snapshot = snapshots[.codex], let progress = snapshot.progress {
            return MetricFormatting.percentage(from: progress.clampedRemainingFraction)
        }

        if let snapshot = snapshots[.openRouter] {
            return snapshot.headline.value
        }

        if let snapshot = snapshots[.deepSeek] {
            return snapshot.headline.value
        }

        return "--"
    }

    var menuBarSymbolName: String {
        if snapshots[.codex]?.progress != nil {
            return ProviderID.codex.symbolName
        }
        if snapshots[.openRouter] != nil {
            return ProviderID.openRouter.symbolName
        }
        if snapshots[.deepSeek] != nil {
            return ProviderID.deepSeek.symbolName
        }
        return "gauge"
    }

    var overallHealth: ProviderHealth {
        let healthValues = orderedProviderIDs.compactMap { snapshots[$0]?.health }
        if healthValues.contains(.critical) { return .critical }
        if healthValues.contains(.warning) { return .warning }
        if healthValues.contains(.healthy) { return .healthy }
        return .unavailable
    }

    func refresh() async {
        guard !isRefreshing else { return }
        isRefreshing = true

        await withTaskGroup(of: ProviderFetchResult.self) { group in
            for provider in providers {
                group.addTask {
                    await provider.fetchResult()
                }
            }

            for await result in group {
                if let snapshot = result.snapshot {
                    snapshots[result.provider] = snapshot
                    errors[result.provider] = nil
                } else if let errorMessage = result.errorMessage {
                    errors[result.provider] = errorMessage
                }
            }
        }

        lastRefresh = Date()
        isRefreshing = false
    }

    func credentialIsConfigured(_ account: SecretAccount) -> Bool {
        keychain.contains(account)
    }

    func saveCredential(_ value: String, for account: SecretAccount) throws {
        try keychain.save(value, for: account)
        Task { await refresh() }
    }

    func deleteCredential(_ account: SecretAccount) throws {
        try keychain.delete(account)
        Task { await refresh() }
    }
}
