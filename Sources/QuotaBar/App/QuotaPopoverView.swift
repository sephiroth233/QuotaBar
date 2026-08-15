import AppKit
import SwiftUI

struct QuotaPopoverView: View {
    @ObservedObject var store: QuotaStore
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        VStack(spacing: 0) {
            header

            Divider()

            VStack(spacing: 8) {
                ForEach(store.orderedProviderIDs) { provider in
                    ProviderCardView(
                        provider: provider,
                        snapshot: store.snapshots[provider],
                        errorMessage: store.errors[provider]
                    )
                }
            }
            .padding(10)

            footer
        }
        .frame(width: 374)
        .background {
            NativeVisualEffectBackground(material: .popover)
                .ignoresSafeArea()
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(.primary.opacity(0.075))
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.primary)
            }
            .frame(width: 30, height: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text("QuotaBar")
                    .font(.system(size: 14, weight: .semibold))
                Text(refreshDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                Task { await store.refresh() }
            } label: {
                Group {
                    if store.isRefreshing {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 13, weight: .medium))
                    }
                }
                .frame(width: 24, height: 24)
                .contentShape(Rectangle())
            }
            .buttonStyle(.borderless)
            .controlSize(.small)
            .disabled(store.isRefreshing)
            .help("刷新全部渠道")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    private var footer: some View {
        VStack(spacing: 0) {
            Divider()

            HStack(spacing: 10) {
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

                Divider()
                    .frame(height: 14)

                Button("退出") {
                    NSApplication.shared.terminate(nil)
                }
            }
            .buttonStyle(.borderless)
            .controlSize(.small)
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
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
