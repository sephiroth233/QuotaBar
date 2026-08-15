import SwiftUI

struct ProviderCardView: View {
    let provider: ProviderID
    let snapshot: ProviderSnapshot?
    let errorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                ProviderBrandIcon(
                    provider: provider,
                    size: provider == .codex ? 20 : 23
                )
                .frame(width: 26, height: 26)

                Text(provider.displayName)
                    .font(.system(size: 14, weight: .semibold))
                    .lineLimit(1)

                Spacer()

                if let plan = snapshot?.plan {
                    Text(plan)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(.primary.opacity(0.06), in: Capsule())
                }

                Circle()
                    .fill(QuotaTheme.color(for: snapshot?.health ?? .unavailable))
                    .frame(width: 7, height: 7)
                    .accessibilityLabel(providerStatusLabel)
                    .accessibilityHidden(snapshot == nil && errorMessage == nil)
            }

            Divider()

            if let snapshot {
                snapshotContent(snapshot)
            } else {
                unavailableContent
            }
        }
        .nativeSection()
    }

    @ViewBuilder
    private func snapshotContent(_ snapshot: ProviderSnapshot) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(snapshot.headline.label)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                if let detail = snapshot.headline.detail {
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 12)
            Text(snapshot.headline.value)
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.82)
        }

        if let progress = snapshot.progress {
            VStack(alignment: .leading, spacing: 6) {
                if provider != .codex {
                    HStack {
                        Text(progress.label)
                        Spacer()
                        Text(MetricFormatting.percentage(from: progress.clampedRemainingFraction))
                            .fontWeight(.medium)
                            .monospacedDigit()
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(.primary.opacity(0.09))
                        Capsule()
                            .fill(QuotaTheme.color(for: snapshot.health))
                            .frame(width: proxy.size.width * progress.clampedRemainingFraction)
                    }
                }
                .frame(height: provider == .codex ? 7 : 5)
            }
            .padding(.top, provider == .codex ? 2 : 0)
        }

        VStack(spacing: 0) {
            ForEach(Array(snapshot.metrics.enumerated()), id: \.offset) { index, metric in
                if index > 0 {
                    Divider().opacity(0.45)
                }

                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(metric.label)
                            .foregroundStyle(.secondary)
                        if let detail = metric.detail {
                            Text(detail)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer(minLength: 12)
                    Text(metric.value)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                        .monospacedDigit()
                        .lineLimit(1)
                }
                .font(.callout)
                .padding(.vertical, 6)
            }
        }

        if let errorMessage {
            Label(errorMessage, systemImage: "exclamationmark.triangle")
                .font(.caption2)
                .foregroundStyle(.orange)
                .lineLimit(2)
        }
    }

    private var unavailableContent: some View {
        HStack(alignment: .top, spacing: 9) {
            Image(systemName: "minus.circle")
                .foregroundStyle(.secondary)
            Text(errorMessage ?? "等待首次刷新…")
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var providerStatusLabel: String {
        guard let health = snapshot?.health else { return "不可用" }
        return switch health {
        case .healthy: "正常"
        case .warning: "需要关注"
        case .critical: "额度偏低"
        case .unavailable: "不可用"
        }
    }
}
