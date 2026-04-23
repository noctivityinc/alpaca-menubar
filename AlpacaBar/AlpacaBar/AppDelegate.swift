import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var settingsWindowController: SettingsWindowController?
    private var refreshTimer: Timer?

    let account = AccountViewModel()

    func applicationDidFinishLaunching(_ notification: Notification) {
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
        if settingsWindowController == nil {
            settingsWindowController = SettingsWindowController(account: account)
        }
        settingsWindowController?.showWindow(nil)
        settingsWindowController?.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    // MARK: - Refresh

    @objc private func refreshClicked() {
        account.refresh()
    }

    private func startRefreshTimer() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.account.refresh()
        }
        RunLoop.current.add(refreshTimer!, forMode: .common)
    }
}
