import SwiftUI

struct ProviderCardView: View {
    let provider: ProviderID
    let snapshot: ProviderSnapshot?
    let errorMessage: String?
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(brandTileFill)

                    ProviderBrandIcon(
                        provider: provider,
                        size: provider == .codex ? 26 : 21
                    )
                }
                .frame(width: 34, height: 34)

                Text(provider.displayName)
                    .font(.system(size: 15, weight: .semibold))

                Spacer()

                if let plan = snapshot?.plan {
                    Text(plan)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.primary.opacity(0.72))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.primary.opacity(0.065), in: Capsule())
                }
            }

            if let snapshot {
                Divider().opacity(0.55)
                snapshotContent(snapshot)
            } else {
                Divider().opacity(0.55)
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
                    .font(.callout.weight(.medium))
                    .foregroundStyle(.primary.opacity(0.76))
                if let detail = snapshot.headline.detail {
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Text(snapshot.headline.value)
                .font(.title2.weight(.bold))
                .monospacedDigit()
        }

        if let progress = snapshot.progress {
            VStack(alignment: .leading, spacing: 7) {
                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(.primary.opacity(colorScheme == .dark ? 0.14 : 0.09))
                        Capsule()
                            .fill(QuotaTheme.color(for: snapshot.health))
                            .frame(width: proxy.size.width * progress.clampedRemainingFraction)
                    }
                }
                .frame(height: 6)

                HStack {
                    Text(progress.label)
                    Spacer()
                    Text(MetricFormatting.percentage(from: progress.clampedRemainingFraction))
                        .fontWeight(.semibold)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }

        VStack(spacing: 0) {
            ForEach(Array(snapshot.metrics.enumerated()), id: \.offset) { index, metric in
                if index > 0 {
                    Divider().opacity(0.45)
                }

                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(metric.label)
                            .foregroundStyle(.primary.opacity(0.74))
                        if let detail = metric.detail {
                            Text(detail)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    Text(metric.value)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary.opacity(0.82))
                        .monospacedDigit()
                }
                .font(.callout)
                .padding(.vertical, 7)
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
                .foregroundStyle(.primary.opacity(0.72))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var brandTileFill: Color {
        if colorScheme == .dark {
            return QuotaTheme.color(for: provider).opacity(0.16)
        }
        return QuotaTheme.color(for: provider).opacity(0.10)
    }
}
