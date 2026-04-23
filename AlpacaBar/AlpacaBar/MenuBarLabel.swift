import SwiftUI

struct MenuBarLabel: View {
    @EnvironmentObject var account: AccountViewModel

    var body: some View {
        Text(account.menuLabel)
            .font(.system(size: 12, weight: .medium, design: .monospaced))
    }
}
