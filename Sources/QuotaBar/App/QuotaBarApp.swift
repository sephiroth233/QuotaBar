import AppKit
import SwiftUI

final class QuotaBarAppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        Task { @MainActor in
            AppInstaller.installIfNeeded()
        }
    }
}

@main
struct QuotaBarApplication: App {
    @NSApplicationDelegateAdaptor(QuotaBarAppDelegate.self) private var appDelegate
    @StateObject private var store = QuotaStore()

    var body: some Scene {
        MenuBarExtra {
            QuotaPopoverView(store: store)
        } label: {
            Label(store.menuBarTitle, systemImage: store.menuBarSymbolName)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(store: store)
        }
    }
}
