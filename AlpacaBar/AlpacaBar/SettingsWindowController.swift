import AppKit
import SwiftUI

class SettingsWindowController: NSWindowController, NSWindowDelegate {
    static var shared: SettingsWindowController?

    static func open(account: AccountViewModel) {
        // Slight delay so the menu bar popup dismisses first
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            if let existing = shared {
                existing.window?.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
                return
            }

            let view = SettingsView(account: account)
            let hosting = NSHostingController(rootView: view)

            let window = NSPanel(
                contentRect: NSRect(x: 0, y: 0, width: 420, height: 460),
                styleMask: [.titled, .closable, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            window.title = "AlpacaBar Settings"
            window.contentViewController = hosting
            window.isReleasedWhenClosed = false
            window.level = .floating
            window.center()
            window.hidesOnDeactivate = false
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

            let controller = SettingsWindowController(window: window)
            window.delegate = controller
            shared = controller
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    func windowWillClose(_ notification: Notification) {
        SettingsWindowController.shared = nil
    }
}
