import AppKit
import SwiftUI

@MainActor
enum SettingsWindowPresenter {
    static let windowIdentifier = NSUserInterfaceItemIdentifier("QuotaBar.Settings")

    static func configure(_ window: NSWindow) {
        window.identifier = windowIdentifier
        window.collectionBehavior.insert(.moveToActiveSpace)
    }

    static func bringToFrontWhenAvailable() {
        Task { @MainActor in
            for _ in 0..<20 {
                if bringToFront() {
                    return
                }
                try? await Task.sleep(for: .milliseconds(50))
            }
        }
    }

    @discardableResult
    static func bringToFront() -> Bool {
        NSApplication.shared.activate(ignoringOtherApps: true)

        guard let window = settingsWindow else {
            return false
        }

        configure(window)
        window.level = .normal
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
        return true
    }

    private static var settingsWindow: NSWindow? {
        NSApplication.shared.windows.first { window in
            window.identifier == windowIdentifier ||
                window.title == "QuotaBar 设置" ||
                window.title.localizedCaseInsensitiveContains("QuotaBar Settings")
        }
    }
}

struct SettingsWindowMarker: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        SettingsWindowMarkerView()
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}

private final class SettingsWindowMarkerView: NSView {
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        guard let window else { return }
        SettingsWindowPresenter.configure(window)
        SettingsWindowPresenter.bringToFrontWhenAvailable()
    }
}
