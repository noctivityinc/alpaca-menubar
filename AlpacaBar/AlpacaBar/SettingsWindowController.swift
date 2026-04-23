import AppKit
import SwiftUI

class SettingsWindowController: NSWindowController, NSWindowDelegate {
    static var shared: SettingsWindowController?

    static func open(account: AccountViewModel) {
        // Capture outside the async block to avoid layout recursion
        // from within the MenuBarExtra popup
        let view = SettingsView(account: account)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            if let existing = shared {
                bringToFront(existing.window!)
                return
            }

            let hosting = NSHostingController(rootView: view)
            hosting.view.translatesAutoresizingMaskIntoConstraints = false

            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 420, height: 460),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            window.title = "AlpacaBar Settings"
            window.contentViewController = hosting
            window.isReleasedWhenClosed = false
            window.center()

            let controller = SettingsWindowController(window: window)
            window.delegate = controller
            shared = controller

            bringToFront(window)
        }
    }

    private static func bringToFront(_ window: NSWindow) {
        NSApp.unhide(nil)
        NSApp.setActivationPolicy(.regular)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func windowWillClose(_ notification: Notification) {
        SettingsWindowController.shared = nil
        DispatchQueue.main.async {
            NSApp.setActivationPolicy(.accessory)
        }
    }
}
