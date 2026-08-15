import SwiftUI

@main
struct QuotaBarApplication: App {
    @StateObject private var store = QuotaStore()

    var body: some Scene {
        MenuBarExtra {
            QuotaPopoverView(store: store)
        } label: {
            Label(store.menuBarTitle, systemImage: "gauge")
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(store: store)
        }
    }
}
