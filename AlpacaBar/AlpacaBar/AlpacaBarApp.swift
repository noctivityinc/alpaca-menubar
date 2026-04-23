import SwiftUI

@main
struct AlpacaBarApp: App {
    @StateObject private var account = AccountViewModel()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
                .environmentObject(account)
        } label: {
            MenuBarLabel()
                .environmentObject(account)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environmentObject(account)
        }
    }
}
