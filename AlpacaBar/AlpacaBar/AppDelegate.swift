import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private var statusItem: NSStatusItem?
    private var settingsWindowController: SettingsWindowController?
    private var refreshTimer: Timer?

    let account = AccountViewModel()

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMainMenu()
        setupStatusItem()
        startRefreshTimer()
        account.onUpdate = { [weak self] in
            self?.updateMenuBarTitle()
        }
        account.refresh()

        // Auto-open settings on first launch
        if account.apiKeyId.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.openSettings()
            }
        }
    }

    // MARK: - Main Menu (enables Cmd+V / paste in text fields)

    private func setupMainMenu() {
        let mainMenu = NSMenu()

        let appMenuItem = NSMenuItem()
        mainMenu.addItem(appMenuItem)
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "Quit AlpacaBar", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appMenuItem.submenu = appMenu

        let editMenuItem = NSMenuItem()
        mainMenu.addItem(editMenuItem)
        let editMenu = NSMenu(title: "Edit")
        editMenu.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        editMenu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        editMenu.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        editMenuItem.submenu = editMenu

        NSApp.mainMenu = mainMenu
    }

    // MARK: - Status Item

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem?.button?.title = "📈"
        statusItem?.button?.target = self
        statusItem?.button?.action = #selector(statusItemClicked)

        buildMenu()
    }

    private func buildMenu() {
        let menu = NSMenu()
        menu.addItem(withTitle: "Equity: —", action: nil, keyEquivalent: "").tag = 1
        menu.addItem(withTitle: "Day: —", action: nil, keyEquivalent: "").tag = 2
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "Buying Power: —", action: nil, keyEquivalent: "").tag = 3
        menu.addItem(withTitle: "Cash: —", action: nil, keyEquivalent: "").tag = 4
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "Positions", action: nil, keyEquivalent: "").tag = 5
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "Refresh", action: #selector(refreshClicked), keyEquivalent: "r").target = self
        menu.addItem(withTitle: "Settings…", action: #selector(openSettings), keyEquivalent: ",").target = self
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "Quit AlpacaBar", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        statusItem?.menu = menu
    }

    @objc private func statusItemClicked() {}

    private func updateMenuBarTitle() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self, let menu = self.statusItem?.menu else { return }

            self.statusItem?.button?.title = self.account.menuLabel

            menu.item(withTag: 1)?.title = "Equity: \(self.account.equity)"
            menu.item(withTag: 2)?.title = "Day: \(self.account.dayChangePct)  \(self.account.dayChange)"
            menu.item(withTag: 3)?.title = "Buying Power: \(self.account.buyingPower)"
            menu.item(withTag: 4)?.title = "Cash: \(self.account.cash)"

            // Update positions submenu
            if let posItem = menu.item(withTag: 5) {
                if self.account.positions.isEmpty {
                    posItem.title = "No open positions"
                    posItem.submenu = nil
                } else {
                    posItem.title = "Positions (\(self.account.positions.count))"
                    let sub = NSMenu()
                    for pos in self.account.positions.prefix(10) {
                        let pnl = Double(pos.unrealized_pl) ?? 0
                        let pct = (Double(pos.unrealized_plpc) ?? 0) * 100
                        let title = String(format: "%@  %@sh  %@$%.2f (%@%.1f%%)",
                                          pos.symbol, pos.qty,
                                          pnl >= 0 ? "+" : "", pnl,
                                          pct >= 0 ? "+" : "", pct)
                        sub.addItem(withTitle: title, action: nil, keyEquivalent: "")
                    }
                    posItem.submenu = sub
                }
            }

            if let err = self.account.errorMessage {
                menu.item(withTag: 1)?.title = "⚠ \(err)"
            }
        }
    }

    // MARK: - Settings

    @objc func openSettings() {
        print("[AlpacaBar] openSettings called")
        print("[AlpacaBar] activation policy before: \(NSApp.activationPolicy().rawValue)")

        if settingsWindowController == nil {
            print("[AlpacaBar] creating new SettingsWindowController")
            settingsWindowController = SettingsWindowController(account: account)
            settingsWindowController?.window?.delegate = self
        }

        print("[AlpacaBar] window before show: \(String(describing: settingsWindowController?.window))")
        print("[AlpacaBar] window isVisible before: \(settingsWindowController?.window?.isVisible ?? false)")

        settingsWindowController?.showWindow(nil)
        settingsWindowController?.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        print("[AlpacaBar] window isVisible after: \(settingsWindowController?.window?.isVisible ?? false)")
        print("[AlpacaBar] window isKey after: \(settingsWindowController?.window?.isKeyWindow ?? false)")
        print("[AlpacaBar] activation policy after: \(NSApp.activationPolicy().rawValue)")
    }

    // MARK: - NSWindowDelegate

    func windowDidBecomeKey(_ notification: Notification) {
        print("[AlpacaBar] windowDidBecomeKey")
    }

    func windowDidResignKey(_ notification: Notification) {
        print("[AlpacaBar] windowDidResignKey")
    }

    func windowWillClose(_ notification: Notification) {
        print("[AlpacaBar] windowWillClose — stack trace:")
        Thread.callStackSymbols.prefix(20).forEach { print("[AlpacaBar]   \($0)") }
    }

    func windowDidChangeOcclusionState(_ notification: Notification) {
        if let win = notification.object as? NSWindow {
            print("[AlpacaBar] occlusionState changed: isVisible=\(win.isVisible) occludedVisible=\(win.occlusionState.contains(.visible))")
        }
    }

    // MARK: - Refresh

    @objc private func refreshClicked() {
        account.refresh()
    }

    private func startRefreshTimer() {
        refreshTimer?.invalidate()
        refreshTimer = Timer(timeInterval: 30, repeats: true) { [weak self] _ in
            print("[AlpacaBar] auto-refresh fired")
            self?.account.refresh()
        }
        RunLoop.main.add(refreshTimer!, forMode: .common)
        print("[AlpacaBar] refresh timer started (30s interval)")
    }
}
