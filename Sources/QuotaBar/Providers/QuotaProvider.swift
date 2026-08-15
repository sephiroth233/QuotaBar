import Foundation

protocol QuotaProvider: Sendable {
    var id: ProviderID { get }
    func fetchSnapshot() async throws -> ProviderSnapshot
}

extension QuotaProvider {
    func fetchResult() async -> ProviderFetchResult {
        do {
            return ProviderFetchResult(
                provider: id,
                snapshot: try await fetchSnapshot(),
                errorMessage: nil
            )
        } catch {
            return ProviderFetchResult(
                provider: id,
                snapshot: nil,
                errorMessage: error.localizedDescription
            )
        }
    }
}

enum MetricFormatting {
    static func money(_ value: Double, currency: String) -> String {
        value.formatted(.currency(code: currency).precision(.fractionLength(2)))
    }

    static func percentage(from fraction: Double) -> String {
        let percent = Int((min(max(fraction, 0), 1) * 100).rounded())
        return "\(percent)%"
    }

    static func relativeReset(_ date: Date, now: Date = Date()) -> String {
        guard date > now else { return "即将重置" }
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: now)
    }

    static func health(forRemainingFraction fraction: Double) -> ProviderHealth {
        switch fraction {
        case 0..<0.2: .critical
        case 0.2..<0.5: .warning
        default: .healthy
        }
    }
}
