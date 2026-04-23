import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var account: AccountViewModel
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header — equity + day change
            VStack(alignment: .leading, spacing: 2) {
                Text("Equity: \(account.equity)")
                    .font(.system(size: 13, weight: .semibold))
                HStack(spacing: 4) {
                    Image(systemName: account.dayChangePositive ? "arrow.up.right" : "arrow.down.right")
                        .foregroundColor(account.dayChangePositive ? .green : .red)
                        .font(.system(size: 11))
                    Text("\(account.dayChangePct)  \(account.dayChange)")
                        .foregroundColor(account.dayChangePositive ? .green : .red)
                        .font(.system(size: 12, design: .monospaced))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)

            Divider()

            // Account stats
            HStack(spacing: 16) {
                statView(label: "Buying Power", value: account.buyingPower)
                Divider().frame(height: 28)
                statView(label: "Cash", value: account.cash)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            if !account.positions.isEmpty {
                Divider()

                Text("Positions")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.top, 6)
                    .padding(.bottom, 2)

                ForEach(account.positions.prefix(10)) { pos in
                    positionRow(pos)
                }
                .padding(.bottom, 4)
            }

            if let err = account.errorMessage {
                Divider()
                Text("⚠ \(err)")
                    .font(.system(size: 11))
                    .foregroundColor(.red)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
            }

            Divider()

            // Footer buttons
            HStack {
                Button("Refresh") { account.refresh() }
                    .buttonStyle(.plain)
                    .font(.system(size: 12))
                Spacer()
                Button("Settings") { openSettings() }
                    .buttonStyle(.plain)
                    .font(.system(size: 12))
                Spacer()
                Button("Quit") { NSApplication.shared.terminate(nil) }
                    .buttonStyle(.plain)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .frame(width: 300)
    }

    @ViewBuilder
    private func statView(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
        }
    }

    @ViewBuilder
    private func positionRow(_ pos: AlpacaPosition) -> some View {
        let pnl = Double(pos.unrealized_pl) ?? 0
        let pct = (Double(pos.unrealized_plpc) ?? 0) * 100
        let positive = pnl >= 0

        HStack {
            Text(pos.symbol)
                .font(.system(size: 12, weight: .semibold))
                .frame(width: 50, alignment: .leading)
            Text("\(pos.qty)sh")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            Spacer()
            Text(String(format: "%@$%.2f (%@%.1f%%)",
                        pnl >= 0 ? "+" : "", pnl,
                        pct >= 0 ? "+" : "", pct))
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(positive ? .green : .red)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 2)
    }
}
