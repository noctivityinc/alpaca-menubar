import AppKit
import SwiftUI

class SettingsWindowController: NSWindowController, NSWindowDelegate {
    static var shared: SettingsWindowController?

    static func open(account: AccountViewModel) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if let existing = shared {
                existing.window?.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
                return
            }

            // Switch to regular app so window stays in front
            NSApp.setActivationPolicy(.regular)

            let view = SettingsView(account: account)
            let hosting = NSHostingController(rootView: view)

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
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    func windowWillClose(_ notification: Notification) {
        SettingsWindowController.shared = nil
        // Switch back to accessory (menu bar only, no Dock icon)
        NSApp.setActivationPolicy(.accessory)
    }
}
