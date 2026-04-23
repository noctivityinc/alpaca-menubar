import SwiftUI
import AppKit

struct MenuBarView: View {
    @EnvironmentObject var account: AccountViewModel

    var body: some View {
        // Account summary (non-interactive labels)
        if account.isConfigured {
            Text("Equity: \(account.equity)")
            Text("Day: \(account.dayChangePct)  \(account.dayChange)")
                .foregroundColor(account.dayChangePositive ? .green : .red)
            Divider()
            Text("Buying Power: \(account.buyingPower)")
            Text("Cash: \(account.cash)")

            if !account.positions.isEmpty {
                Divider()
                Text("Positions").foregroundColor(.secondary)
                ForEach(account.positions.prefix(10)) { pos in
                    let pnl = Double(pos.unrealized_pl) ?? 0
                    let pct = (Double(pos.unrealized_plpc) ?? 0) * 100
                    Text(String(format: "%@  %@sh  %@$%.2f (%@%.1f%%)",
                                pos.symbol, pos.qty,
                                pnl >= 0 ? "+" : "", pnl,
                                pct >= 0 ? "+" : "", pct))
                }
            }

            if let err = account.errorMessage {
                Divider()
                Text("⚠ \(err)").foregroundColor(.red)
            }

            Divider()
            Button("Refresh") { account.refresh() }
        } else {
            Text("AlpacaBar — not connected")
        }

        Divider()
        Button("Settings…") {
            SettingsWindowController.open(account: account)
        }
        Button("Quit") {
            NSApplication.shared.terminate(nil)
        }
    }
}
