import AppKit
import Foundation

@MainActor
enum AppInstaller {
    private static let appFileName = "QuotaBar.app"
    private static var isHandlingLaunch = false

    static func installIfNeeded() {
        guard !isHandlingLaunch else { return }
        isHandlingLaunch = true

        let sourceURL = Bundle.main.bundleURL.standardizedFileURL
        guard sourceURL.pathExtension.lowercased() == "app" else {
            return
        }

        let knownDestinations = installationDestinations()
        if knownDestinations.contains(where: { sameLocation($0, sourceURL) }) {
            return
        }

        do {
            let destinationURL = preferredDestination(from: knownDestinations)

            if FileManager.default.fileExists(atPath: destinationURL.path),
               buildNumber(at: destinationURL) >= buildNumber(at: sourceURL) {
                relaunch(from: destinationURL)
                return
            }

            try installBundle(from: sourceURL, to: destinationURL)
            relaunch(from: destinationURL)
        } catch {
            presentInstallationFailure(error)
        }
    }

    private static func installationDestinations() -> [URL] {
        let systemApplications = URL(fileURLWithPath: "/Applications", isDirectory: true)
            .appendingPathComponent(appFileName, isDirectory: true)
        let userApplications = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Applications", isDirectory: true)
            .appendingPathComponent(appFileName, isDirectory: true)
        return [systemApplications, userApplications]
    }

    private static func preferredDestination(from destinations: [URL]) -> URL {
        if let existing = destinations.first(where: {
            FileManager.default.fileExists(atPath: $0.path)
        }) {
            return existing
        }

        let systemDestination = destinations[0]
        let systemDirectory = systemDestination.deletingLastPathComponent()
        if FileManager.default.isWritableFile(atPath: systemDirectory.path) {
            return systemDestination
        }
        return destinations[1]
    }

    private static func installBundle(from sourceURL: URL, to destinationURL: URL) throws {
        let fileManager = FileManager.default
        let destinationDirectory = destinationURL.deletingLastPathComponent()
        try fileManager.createDirectory(
            at: destinationDirectory,
            withIntermediateDirectories: true
        )

        guard fileManager.isWritableFile(atPath: destinationDirectory.path) else {
            throw InstallationError.destinationNotWritable(destinationDirectory.path)
        }

        let stagingURL = destinationDirectory.appendingPathComponent(
            ".QuotaBar-installing-\(UUID().uuidString).app",
            isDirectory: true
        )
        defer {
            if fileManager.fileExists(atPath: stagingURL.path) {
                try? fileManager.removeItem(at: stagingURL)
            }
        }

        try fileManager.copyItem(at: sourceURL, to: stagingURL)

        if fileManager.fileExists(atPath: destinationURL.path) {
            _ = try fileManager.replaceItemAt(
                destinationURL,
                withItemAt: stagingURL,
                backupItemName: nil,
                options: []
            )
        } else {
            try fileManager.moveItem(at: stagingURL, to: destinationURL)
        }
    }

    private static func relaunch(from destinationURL: URL) {
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = false

        Task { @MainActor in
            do {
                _ = try await NSWorkspace.shared.openApplication(
                    at: destinationURL,
                    configuration: configuration
                )
                NSApplication.shared.terminate(nil)
            } catch {
                presentInstallationFailure(error)
            }
        }
    }

    private static func presentInstallationFailure(_ error: Error) {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "QuotaBar 自动安装失败"
        alert.informativeText = "\(error.localizedDescription)\n\n你仍可继续运行当前副本，或手动把 QuotaBar.app 拖入应用程序文件夹。"
        alert.addButton(withTitle: "继续运行")
        alert.runModal()
    }

    private static func buildNumber(at bundleURL: URL) -> Int {
        guard let bundle = Bundle(url: bundleURL) else { return 0 }
        let rawValue = bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String
        return rawValue.flatMap(Int.init) ?? 0
    }

    private static func sameLocation(_ lhs: URL, _ rhs: URL) -> Bool {
        lhs.resolvingSymlinksInPath().standardizedFileURL ==
            rhs.resolvingSymlinksInPath().standardizedFileURL
    }
}

private enum InstallationError: LocalizedError {
    case destinationNotWritable(String)

    var errorDescription: String? {
        switch self {
        case .destinationNotWritable(let path):
            "没有写入 \(path) 的权限。"
        }
    }
}
