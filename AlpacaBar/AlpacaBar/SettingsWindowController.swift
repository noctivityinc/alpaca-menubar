import Cocoa
import ServiceManagement

class SettingsWindowController: NSWindowController {

    private weak var account: AccountViewModel?

    private var keyIdField: NSTextField!
    private var secretField: NSSecureTextField!
    private var paperRadio: NSButton!
    private var liveRadio: NSButton!
    private var statusLabel: NSTextField!
    private var saveButton: NSButton!
    private var launchAtLoginCheckbox: NSButton!

    init(account: AccountViewModel) {
        self.account = account

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 440, height: 340),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: true
        )
        window.title = "AlpacaBar Settings"
        window.center()
        window.isReleasedWhenClosed = false

        super.init(window: window)
        setupUI()
        loadSettings()
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - UI Setup

    private func setupUI() {
        guard let cv = window?.contentView else { return }

        // Title
        let title = label("AlpacaBar Settings", frame: NSRect(x: 20, y: 300, width: 400, height: 22), bold: true, size: 15)
        cv.addSubview(title)

        let sep1 = separator(NSRect(x: 20, y: 288, width: 400, height: 1))
        cv.addSubview(sep1)

        // API Key ID
        let keyLabel = label("API Key ID", frame: NSRect(x: 20, y: 258, width: 200, height: 17), bold: true, size: 12)
        cv.addSubview(keyLabel)

        keyIdField = NSTextField(frame: NSRect(x: 20, y: 234, width: 400, height: 22))
        keyIdField.placeholderString = "PK..."
        keyIdField.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        cv.addSubview(keyIdField)

        // Secret
        let secretLabel = label("API Secret Key", frame: NSRect(x: 20, y: 208, width: 200, height: 17), bold: true, size: 12)
        cv.addSubview(secretLabel)

        secretField = NSSecureTextField(frame: NSRect(x: 20, y: 184, width: 400, height: 22))
        secretField.placeholderString = "Secret key..."
        cv.addSubview(secretField)

        let helpLink = label("Find your keys: app.alpaca.markets → API", frame: NSRect(x: 20, y: 162, width: 400, height: 16), bold: false, size: 11)
        helpLink.textColor = .secondaryLabelColor
        cv.addSubview(helpLink)

        let sep2 = separator(NSRect(x: 20, y: 150, width: 400, height: 1))
        cv.addSubview(sep2)

        // Account type
        let acctLabel = label("Account Type", frame: NSRect(x: 20, y: 124, width: 200, height: 17), bold: true, size: 12)
        cv.addSubview(acctLabel)

        paperRadio = NSButton(radioButtonWithTitle: "Paper Trading", target: self, action: #selector(radioChanged))
        paperRadio.frame = NSRect(x: 20, y: 100, width: 180, height: 20)
        cv.addSubview(paperRadio)

        liveRadio = NSButton(radioButtonWithTitle: "Live Trading", target: self, action: #selector(radioChanged))
        liveRadio.frame = NSRect(x: 220, y: 100, width: 180, height: 20)
        cv.addSubview(liveRadio)

        let sep3 = separator(NSRect(x: 20, y: 88, width: 400, height: 1))
        cv.addSubview(sep3)

        // Status label
        statusLabel = label("", frame: NSRect(x: 20, y: 60, width: 280, height: 22), bold: false, size: 12)
        statusLabel.textColor = .secondaryLabelColor
        cv.addSubview(statusLabel)

        // Save button
        saveButton = NSButton(frame: NSRect(x: 320, y: 56, width: 100, height: 28))
        saveButton.title = "Save & Connect"
        saveButton.bezelStyle = .rounded
        saveButton.target = self
        saveButton.action = #selector(saveTapped)
        cv.addSubview(saveButton)

        let sep4 = separator(NSRect(x: 20, y: 46, width: 400, height: 1))
        cv.addSubview(sep4)

        // Launch at login
        launchAtLoginCheckbox = NSButton(checkboxWithTitle: "Launch at Login", target: self, action: #selector(launchAtLoginChanged))
        launchAtLoginCheckbox.frame = NSRect(x: 20, y: 16, width: 200, height: 20)
        cv.addSubview(launchAtLoginCheckbox)
    }

    // MARK: - Helpers

    private func label(_ text: String, frame: NSRect, bold: Bool, size: CGFloat) -> NSTextField {
        let f = NSTextField(frame: frame)
        f.stringValue = text
        f.isEditable = false; f.isSelectable = false
        f.drawsBackground = false; f.isBezeled = false
        f.font = bold ? NSFont.boldSystemFont(ofSize: size) : NSFont.systemFont(ofSize: size)
        return f
    }

    private func separator(_ frame: NSRect) -> NSBox {
        let b = NSBox(frame: frame)
        b.boxType = .separator
        return b
    }

    // MARK: - Load / Save

    private func loadSettings() {
        guard let account = account else { return }
        keyIdField.stringValue = account.apiKeyId
        secretField.stringValue = account.apiSecret
        paperRadio.state = account.isPaper ? .on : .off
        liveRadio.state = account.isPaper ? .off : .on
        if #available(macOS 13, *) {
            launchAtLoginCheckbox.state = SMAppService.mainApp.status == .enabled ? .on : .off
        }
    }

    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)
        loadSettings()
    }

    @objc private func radioChanged() {}

    @objc private func launchAtLoginChanged() {
        if #available(macOS 13, *) {
            let on = launchAtLoginCheckbox.state == .on
            let svc = SMAppService.mainApp
            try? on ? svc.register() : svc.unregister()
        }
    }

    @objc private func saveTapped() {
        guard let account = account else { return }

        let keyId = keyIdField.stringValue.trimmingCharacters(in: .whitespaces)
        let secret = secretField.stringValue.trimmingCharacters(in: .whitespaces)

        guard !keyId.isEmpty else {
            setStatus("Please enter an API Key ID.", color: .systemRed)
            return
        }

        account.apiKeyId  = keyId
        account.apiSecret = secret.isEmpty ? keyId : secret
        account.isPaper   = paperRadio.state == .on

        setStatus("Connecting…", color: .secondaryLabelColor)
        saveButton.isEnabled = false

        let base = account.isPaper ? "https://paper-api.alpaca.markets" : "https://api.alpaca.markets"
        var req = URLRequest(url: URL(string: "\(base)/v2/account")!, timeoutInterval: 8)
        req.setValue(keyId, forHTTPHeaderField: "APCA-API-KEY-ID")
        req.setValue(account.apiSecret, forHTTPHeaderField: "APCA-API-SECRET-KEY")

        URLSession.shared.dataTask(with: req) { [weak self] _, response, error in
            DispatchQueue.main.async {
                self?.saveButton.isEnabled = true
                if let error = error {
                    self?.setStatus("Error: \(error.localizedDescription)", color: .systemRed)
                    return
                }
                let status = (response as? HTTPURLResponse)?.statusCode ?? 0
                if status == 200 {
                    self?.setStatus("✓ Connected!", color: .systemGreen)
                    account.isConfigured = true
                    account.refresh()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        self?.close()
                    }
                } else if status == 401 || status == 403 {
                    self?.setStatus("Invalid credentials (HTTP \(status)). Check your Key ID & Secret.", color: .systemRed)
                } else {
                    self?.setStatus("Error HTTP \(status). Try again.", color: .systemRed)
                }
            }
        }.resume()
    }

    private func setStatus(_ text: String, color: NSColor) {
        statusLabel.stringValue = text
        statusLabel.textColor = color
    }
}
