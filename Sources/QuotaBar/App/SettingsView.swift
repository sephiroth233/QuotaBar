import SwiftUI

struct SettingsView: View {
    @ObservedObject var store: QuotaStore
    @AppStorage("refreshIntervalMinutes") private var refreshIntervalMinutes = 10.0

    var body: some View {
        Form {
            Section("刷新") {
                Picker("自动刷新间隔", selection: $refreshIntervalMinutes) {
                    Text("5 分钟").tag(5.0)
                    Text("10 分钟").tag(10.0)
                    Text("15 分钟").tag(15.0)
                    Text("30 分钟").tag(30.0)
                }
                .pickerStyle(.menu)
            }

            Section("Codex") {
                LabeledContent("登录来源", value: "~/.codex/auth.json")
                Text("QuotaBar 只读取当前 Codex Desktop/CLI 登录，不修改或复制其令牌。登录过期时，请在 Codex 中重新登录。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("OpenRouter") {
                SecretEditor(
                    title: "API Key",
                    explanation: "查询当前 Key 的使用量和可用限额。",
                    account: .openRouterAPIKey,
                    store: store
                )
                SecretEditor(
                    title: "Management Key",
                    explanation: "可选，用于查询整个账户的充值余额。",
                    account: .openRouterManagementKey,
                    store: store
                )
            }

            Section("DeepSeek") {
                SecretEditor(
                    title: "API Key",
                    explanation: "查询账户总余额、充值余额和赠送余额。",
                    account: .deepSeekAPIKey,
                    store: store
                )
            }

            Section {
                HStack {
                    Spacer()
                    Button("立即刷新") {
                        Task { await store.refresh() }
                    }
                    .disabled(store.isRefreshing)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
        .frame(width: 520, height: 590)
    }
}

private struct SecretEditor: View {
    let title: String
    let explanation: String
    let account: SecretAccount
    @ObservedObject var store: QuotaStore

    @State private var pendingValue = ""
    @State private var feedback: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Text(title)
                    .fontWeight(.medium)
                Spacer()
                Text(store.credentialIsConfigured(account) ? "已配置" : "未配置")
                    .font(.caption)
                    .foregroundStyle(store.credentialIsConfigured(account) ? .green : .secondary)
            }

            SecureField("输入新的密钥", text: $pendingValue)
                .textFieldStyle(.roundedBorder)

            HStack {
                Text(explanation)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                if store.credentialIsConfigured(account) {
                    Button("清除", role: .destructive) {
                        clear()
                    }
                }
                Button("保存") {
                    save()
                }
                .disabled(pendingValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            if let feedback {
                Text(feedback)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 3)
    }

    private func save() {
        do {
            try store.saveCredential(pendingValue, for: account)
            pendingValue = ""
            feedback = "已安全保存到 macOS 钥匙串。"
        } catch {
            feedback = error.localizedDescription
        }
    }

    private func clear() {
        do {
            try store.deleteCredential(account)
            pendingValue = ""
            feedback = "凭据已从钥匙串清除。"
        } catch {
            feedback = error.localizedDescription
        }
    }
}
