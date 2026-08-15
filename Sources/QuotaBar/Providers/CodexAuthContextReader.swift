import Foundation

struct CodexAuthContext: Sendable {
    let accessToken: String
    let accountID: String?
}

struct CodexAuthContextReader: Sendable {
    let authFileURL: URL

    init(authFileURL: URL? = nil) {
        self.authFileURL = authFileURL ?? FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".codex", isDirectory: true)
            .appendingPathComponent("auth.json", isDirectory: false)
    }

    func read() throws -> CodexAuthContext {
        let url = authFileURL
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw ProviderError.signedOut("未找到 Codex 登录，请先登录 Codex Desktop。")
        }

        let data = try Data(contentsOf: url, options: [.mappedIfSafe])
        guard
            let root = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let token = findString(keys: ["access_token", "accessToken"], in: root),
            !token.isEmpty
        else {
            throw ProviderError.signedOut("Codex 登录数据不可用，请重新登录 Codex Desktop。")
        }

        let accountID = findString(
            keys: ["account_id", "accountId", "chatgpt_account_id"],
            in: root
        )
        return CodexAuthContext(accessToken: token, accountID: accountID)
    }

    private func findString(keys: Set<String>, in value: Any) -> String? {
        if let dictionary = value as? [String: Any] {
            for key in keys {
                if let string = dictionary[key] as? String, !string.isEmpty {
                    return string
                }
            }
            for child in dictionary.values {
                if let match = findString(keys: keys, in: child) {
                    return match
                }
            }
        } else if let array = value as? [Any] {
            for child in array {
                if let match = findString(keys: keys, in: child) {
                    return match
                }
            }
        }
        return nil
    }
}
