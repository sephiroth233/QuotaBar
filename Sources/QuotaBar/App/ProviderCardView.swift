import SwiftUI

struct ProviderCardView: View {
    let provider: ProviderID
    let snapshot: ProviderSnapshot?
    let errorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: provider.symbolName)
                    .foregroundStyle(QuotaTheme.color(for: provider))
                    .frame(width: 18)

                Text(provider.displayName)
                    .font(.headline)

                Spacer()

                if let plan = snapshot?.plan {
                    Text(plan)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.secondary.opacity(0.1), in: Capsule())
                }

                Circle()
                    .fill(QuotaTheme.color(for: snapshot?.health ?? .unavailable))
                    .frame(width: 7, height: 7)
            }

            if let snapshot {
                snapshotContent(snapshot)
            } else {
                unavailableContent
            }
        }
        .glassCard()
    }

    @ViewBuilder
    private func snapshotContent(_ snapshot: ProviderSnapshot) -> some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(snapshot.headline.label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let detail = snapshot.headline.detail {
                    Text(detail)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            Spacer()
            Text(snapshot.headline.value)
                .font(.title2.weight(.semibold))
                .monospacedDigit()
        }

        if let progress = snapshot.progress {
            VStack(alignment: .leading, spacing: 5) {
                ProgressView(value: progress.clampedRemainingFraction)
                    .tint(QuotaTheme.color(for: snapshot.health))
                HStack {
                    Text(progress.label)
                    Spacer()
                    Text(MetricFormatting.percentage(from: progress.clampedRemainingFraction))
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
        }

        ForEach(Array(snapshot.metrics.enumerated()), id: \.offset) { _, metric in
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 1) {
                    Text(metric.label)
                    if let detail = metric.detail {
                        Text(detail)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
                Spacer()
                Text(metric.value)
                    .fontWeight(.medium)
                    .monospacedDigit()
            }
            .font(.caption)
            .foregroundStyle(.secondary)
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
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
