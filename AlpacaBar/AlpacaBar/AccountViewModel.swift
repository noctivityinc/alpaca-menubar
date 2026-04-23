import Foundation
import Combine
import ServiceManagement

struct AlpacaAccount: Decodable {
    let equity: String
    let last_equity: String
    let buying_power: String
    let cash: String
}

struct AlpacaPosition: Decodable, Identifiable {
    var id: String { symbol }
    let symbol: String
    let qty: String
    let unrealized_pl: String
    let unrealized_plpc: String
}

class AccountViewModel: ObservableObject {
    @Published var menuLabel: String = "📈"
    @Published var equity: String = "—"
    @Published var buyingPower: String = "—"
    @Published var cash: String = "—"
    @Published var dayChange: String = "—"
    @Published var dayChangePct: String = "—"
    @Published var dayChangePositive: Bool = true
    @Published var positions: [AlpacaPosition] = []
    @Published var errorMessage: String? = nil
    @Published var isConfigured: Bool = false

    private var timer: Timer?
    private let keychainService = "AlpacaMenuBar"

    // Keychain helpers
    var apiKeyId: String {
        get { KeychainHelper.load(service: keychainService, account: "key_id") ?? "" }
        set { KeychainHelper.save(service: keychainService, account: "key_id", value: newValue) }
    }
    var apiSecret: String {
        get { KeychainHelper.load(service: keychainService, account: "secret") ?? "" }
        set { KeychainHelper.save(service: keychainService, account: "secret", value: newValue) }
    }
    var isPaper: Bool {
        get { (KeychainHelper.load(service: keychainService, account: "paper") ?? "1") == "1" }
        set { KeychainHelper.save(service: keychainService, account: "paper", value: newValue ? "1" : "0") }
    }

    var baseURL: String {
        isPaper ? "https://paper-api.alpaca.markets" : "https://api.alpaca.markets"
    }

    init() {
        isConfigured = !apiKeyId.isEmpty && !apiSecret.isEmpty
        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.refresh()
        }
        // Auto-open settings on first launch if no key configured
        if !isConfigured {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }

    func refresh() {
        guard !apiKeyId.isEmpty, !apiSecret.isEmpty else {
            menuLabel = "📈 ?"
            return
        }
        fetchAccount()
        fetchPositions()
    }

    private func headers() -> [String: String] {
        ["APCA-API-KEY-ID": apiKeyId, "APCA-API-SECRET-KEY": apiSecret]
    }

    private func fetchAccount() {
        guard let url = URL(string: "\(baseURL)/v2/account") else { return }
        var req = URLRequest(url: url, timeoutInterval: 8)
        headers().forEach { req.setValue($1, forHTTPHeaderField: $0) }

        URLSession.shared.dataTask(with: req) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.menuLabel = "📈 !"
                    self?.errorMessage = error.localizedDescription
                    return
                }
                if let http = response as? HTTPURLResponse, http.statusCode != 200 {
                    self?.menuLabel = "📈 !"
                    self?.errorMessage = "HTTP \(http.statusCode)"
                    return
                }
                guard let data = data,
                      let acct = try? JSONDecoder().decode(AlpacaAccount.self, from: data) else {
                    self?.menuLabel = "📈 !"
                    self?.errorMessage = "Parse error"
                    return
                }
                self?.errorMessage = nil
                self?.updateAccount(acct)
            }
        }.resume()
    }

    private func fetchPositions() {
        guard let url = URL(string: "\(baseURL)/v2/positions") else { return }
        var req = URLRequest(url: url, timeoutInterval: 8)
        headers().forEach { req.setValue($1, forHTTPHeaderField: $0) }

        URLSession.shared.dataTask(with: req) { [weak self] data, _, _ in
            DispatchQueue.main.async {
                guard let data = data,
                      let positions = try? JSONDecoder().decode([AlpacaPosition].self, from: data) else { return }
                self?.positions = positions
            }
        }.resume()
    }

    private func updateAccount(_ acct: AlpacaAccount) {
        let equity     = Double(acct.equity) ?? 0
        let lastEquity = Double(acct.last_equity) ?? 0
        let change     = equity - lastEquity
        let pct        = lastEquity > 0 ? (change / lastEquity * 100) : 0
        let bp         = Double(acct.buying_power) ?? 0
        let cashVal    = Double(acct.cash) ?? 0

        self.equity       = formatDollars(equity)
        self.buyingPower  = formatDollars(bp)
        self.cash         = formatDollars(cashVal)
        self.dayChange    = formatSignedDollars(change)
        self.dayChangePct = formatSignedPct(pct)
        self.dayChangePositive = change >= 0

        if isMarketHours() {
            let arrow = change >= 0 ? "▲" : "▼"
            menuLabel = "\(arrow) \(formatSignedPct(pct))  \(formatSignedDollars(change))"
        } else {
            menuLabel = "📈 \(formatSignedPct(pct))"
        }
    }

    private func isMarketHours() -> Bool {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "America/New_York")!
        let now = Date()
        let weekday = cal.component(.weekday, from: now)
        if weekday == 1 || weekday == 7 { return false }
        let comps = cal.dateComponents([.hour, .minute], from: now)
        let mins = (comps.hour ?? 0) * 60 + (comps.minute ?? 0)
        return mins >= 570 && mins <= 960 // 9:30–16:00
    }

    private func formatDollars(_ v: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencySymbol = "$"
        return f.string(from: NSNumber(value: v)) ?? "$0.00"
    }

    private func formatSignedDollars(_ v: Double) -> String {
        let sign = v >= 0 ? "+" : ""
        return "\(sign)\(formatDollars(v))"
    }

    private func formatSignedPct(_ v: Double) -> String {
        let sign = v >= 0 ? "+" : ""
        return String(format: "\(sign)%.2f%%", v)
    }
}
