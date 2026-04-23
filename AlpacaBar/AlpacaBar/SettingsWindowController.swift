import AppKit
import SwiftUI

class SettingsWindowController: NSWindowController {
    static var shared: SettingsWindowController?

    static func open(account: AccountViewModel) {
        if let existing = shared {
            existing.window?.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        let view = SettingsView(account: account)
        let hosting = NSHostingController(rootView: view)
        let window = NSWindow(contentViewController: hosting)
        window.title = "AlpacaBar Settings"
        window.styleMask = [.titled, .closable]
        window.setContentSize(NSSize(width: 420, height: 460))
        window.center()
        window.isReleasedWhenClosed = false
        let controller = SettingsWindowController(window: window)
        shared = controller
        controller.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    override func windowDidLoad() {
        super.windowDidLoad()
    }
}
