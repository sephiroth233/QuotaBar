import Foundation
import Security

enum SecretAccount: String, CaseIterable, Sendable {
    case deepSeekAPIKey = "deepseek-api-key"
    case openRouterAPIKey = "openrouter-api-key"
    case openRouterManagementKey = "openrouter-management-key"
}

enum KeychainError: LocalizedError, Sendable {
    case invalidData
    case status(OSStatus)

    var errorDescription: String? {
        switch self {
        case .invalidData:
            "钥匙串中的凭据格式无效。"
        case .status(let status):
            SecCopyErrorMessageString(status, nil) as String? ?? "钥匙串操作失败（\(status)）。"
        }
    }
}

final class KeychainStore: @unchecked Sendable {
    private let service: String

    init(service: String = "local.quotabar.app") {
        self.service = service
    }

    func contains(_ account: SecretAccount) -> Bool {
        (try? read(account)) != nil
    }

    func read(_ account: SecretAccount) throws -> String? {
        var query = baseQuery(for: account)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecItemNotFound {
            return nil
        }
        guard status == errSecSuccess else {
            throw KeychainError.status(status)
        }
        guard
            let data = result as? Data,
            let value = String(data: data, encoding: .utf8)
        else {
            throw KeychainError.invalidData
        }
        return value
    }

    func save(_ value: String, for account: SecretAccount) throws {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let data = trimmed.data(using: .utf8) else {
            throw KeychainError.invalidData
        }

        let query = baseQuery(for: account)
        let attributes: [String: Any] = [kSecValueData as String: data]
        let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)

        if updateStatus == errSecItemNotFound {
            var insert = query
            insert[kSecValueData as String] = data
            insert[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
            let addStatus = SecItemAdd(insert as CFDictionary, nil)
            guard addStatus == errSecSuccess else {
                throw KeychainError.status(addStatus)
            }
            return
        }

        guard updateStatus == errSecSuccess else {
            throw KeychainError.status(updateStatus)
        }
    }

    func delete(_ account: SecretAccount) throws {
        let status = SecItemDelete(baseQuery(for: account) as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.status(status)
        }
    }

    private func baseQuery(for account: SecretAccount) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account.rawValue
        ]
    }
}
