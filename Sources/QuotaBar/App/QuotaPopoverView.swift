import AppKit
import SwiftUI

struct QuotaPopoverView: View {
    @ObservedObject var store: QuotaStore

    var body: some View {
        VStack(spacing: 14) {
            header

            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(store.orderedProviderIDs) { provider in
                        ProviderCardView(
                            provider: provider,
                            snapshot: store.snapshots[provider],
                            errorMessage: store.errors[provider]
                        )
                    }
                }
                .padding(.horizontal, 1)
            }

            footer
        }
        .padding(14)
        .frame(width: 380)
        .frame(maxHeight: 720)
        .background(.regularMaterial)
    }

    private var header: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(.primary.opacity(0.08))
                Image(systemName: "gauge")
                    .font(.system(size: 18, weight: .semibold))
            }
            .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text("QuotaBar")
                    .font(.headline)
                Text(refreshDescription)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                Task { await store.refresh() }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .rotationEffect(.degrees(store.isRefreshing ? 180 : 0))
            }
            .buttonStyle(.borderless)
            .disabled(store.isRefreshing)
            .help("刷新全部渠道")
        }
    }

    private var footer: some View {
        HStack {
            Label(overallStatusText, systemImage: "circle.fill")
                .font(.caption)
                .foregroundStyle(QuotaTheme.color(for: store.overallHealth))

            Spacer()

            SettingsLink {
                Label("设置", systemImage: "gearshape")
            }
            .buttonStyle(.borderless)

            Divider()
                .frame(height: 14)

            Button("退出") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.borderless)
        }
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
