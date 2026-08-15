import Darwin
import Foundation

enum SecretAccount: String, CaseIterable, Sendable {
    case deepSeekAPIKey = "deepseek-api-key"
    case openRouterAPIKey = "openrouter-api-key"
    case openRouterManagementKey = "openrouter-management-key"
}

enum LocalCredentialError: LocalizedError, Sendable {
    case invalidValue
    case invalidFile
    case cannotWrite

    var errorDescription: String? {
        switch self {
        case .invalidValue:
            "密钥不能为空。"
        case .invalidFile:
            "本地凭据文件格式无效，请清除后重新配置。"
        case .cannotWrite:
            "无法写入本地凭据文件。"
        }
    }
}

final class LocalCredentialStore: @unchecked Sendable {
    private struct CredentialFile: Codable {
        var version = 1
        var values: [String: String] = [:]
    }

    private let fileManager: FileManager
    private let fileURL: URL
    private let lock = NSLock()

    init(fileManager: FileManager = .default, fileURL: URL? = nil) {
        self.fileManager = fileManager
        self.fileURL = fileURL ?? Self.defaultFileURL(fileManager: fileManager)
    }

    var locationDescription: String {
        "~/Library/Application Support/QuotaBar/credentials.json"
    }

    func contains(_ account: SecretAccount) -> Bool {
        lock.withLock {
            guard let file = try? load() else { return false }
            return !(file.values[account.rawValue]?.isEmpty ?? true)
        }
    }

    func read(_ account: SecretAccount) throws -> String? {
        try lock.withLock {
            try load().values[account.rawValue]
        }
    }

    func save(_ value: String, for account: SecretAccount) throws {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw LocalCredentialError.invalidValue
        }

        try lock.withLock {
            var file = try load()
            file.values[account.rawValue] = trimmed
            try persist(file)
        }
    }

    func delete(_ account: SecretAccount) throws {
        try lock.withLock {
            var file = try load()
            file.values[account.rawValue] = nil

            if file.values.isEmpty {
                if fileManager.fileExists(atPath: fileURL.path) {
                    try fileManager.removeItem(at: fileURL)
                }
            } else {
                try persist(file)
            }
        }
    }

    private func load() throws -> CredentialFile {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return CredentialFile()
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let file = try JSONDecoder().decode(CredentialFile.self, from: data)
            guard file.version == 1 else {
                throw LocalCredentialError.invalidFile
            }
            return file
        } catch let error as LocalCredentialError {
            throw error
        } catch {
            throw LocalCredentialError.invalidFile
        }
    }

    private func persist(_ file: CredentialFile) throws {
        let directoryURL = fileURL.deletingLastPathComponent()
        try fileManager.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true,
            attributes: [.posixPermissions: 0o700]
        )
        try fileManager.setAttributes([.posixPermissions: 0o700], ofItemAtPath: directoryURL.path)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(file)
        let temporaryURL = directoryURL.appendingPathComponent(".credentials-\(UUID().uuidString).tmp")

        guard fileManager.createFile(
            atPath: temporaryURL.path,
            contents: data,
            attributes: [.posixPermissions: 0o600]
        ) else {
            throw LocalCredentialError.cannotWrite
        }

        if Darwin.rename(temporaryURL.path, fileURL.path) != 0 {
            let code = errno
            try? fileManager.removeItem(at: temporaryURL)
            throw NSError(domain: NSPOSIXErrorDomain, code: Int(code))
        }

        try fileManager.setAttributes([.posixPermissions: 0o600], ofItemAtPath: fileURL.path)
    }

    private static func defaultFileURL(fileManager: FileManager) -> URL {
        let applicationSupport = fileManager.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first ?? fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support", isDirectory: true)

        return applicationSupport
            .appendingPathComponent("QuotaBar", isDirectory: true)
            .appendingPathComponent("credentials.json", isDirectory: false)
    }
}
