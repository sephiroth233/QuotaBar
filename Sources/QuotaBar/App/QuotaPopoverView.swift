import AppKit
import SwiftUI

struct QuotaPopoverView: View {
    @ObservedObject var store: QuotaStore
    @Environment(\.openSettings) private var openSettings
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 12) {
            header

            VStack(spacing: 9) {
                ForEach(store.orderedProviderIDs) { provider in
                    ProviderCardView(
                        provider: provider,
                        snapshot: store.snapshots[provider],
                        errorMessage: store.errors[provider]
                    )
                }
            }
            .padding(.horizontal, 1)

            footer
        }
        .padding(14)
        .frame(width: 392)
        .background {
            NativeVisualEffectBackground(material: .popover)
                .ignoresSafeArea()
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(.primary.opacity(colorScheme == .dark ? 0.12 : 0.07))
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)
            }
            .frame(width: 34, height: 34)

            VStack(alignment: .leading, spacing: 2) {
                Text("QuotaBar")
                    .font(.system(size: 15, weight: .semibold))
                Text(refreshDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                Task { await store.refresh() }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 13, weight: .semibold))
                    .rotationEffect(.degrees(store.isRefreshing ? 180 : 0))
            }
            .buttonStyle(.plain)
            .padding(7)
            .background(.primary.opacity(0.055), in: Circle())
            .disabled(store.isRefreshing)
            .help("刷新全部渠道")
        }
    }

    private var footer: some View {
        HStack {
            HStack(spacing: 6) {
                Circle()
                    .fill(QuotaTheme.color(for: store.overallHealth))
                    .frame(width: 7, height: 7)
                Text(overallStatusText)
                    .foregroundStyle(.secondary)
            }
            .font(.caption.weight(.medium))

            Spacer()

            Button {
                openSettings()
                SettingsWindowPresenter.bringToFrontWhenAvailable()
            } label: {
                Label("设置", systemImage: "gearshape")
            }
            .buttonStyle(.plain)

            Divider()
                .frame(height: 14)

            Button("退出") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.plain)
        }
        .foregroundStyle(.primary)
    }

    private var refreshDescription: String {
        if store.isRefreshing { return "正在刷新…" }
        guard let lastRefresh = store.lastRefresh else { return "等待首次刷新" }
        return "更新于 \(lastRefresh.formatted(date: .omitted, time: .shortened))"
    }

    private var overallStatusText: String {
        switch store.overallHealth {
        case .healthy: "渠道正常"
        case .warning: "需要关注"
        case .critical: "额度偏低"
        case .unavailable: "尚未配置"
        }
    }
}
