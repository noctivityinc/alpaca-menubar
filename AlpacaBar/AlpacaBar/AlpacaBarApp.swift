import SwiftUI
import AppKit

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
        .menuBarExtraStyle(.menu)
    }
}
