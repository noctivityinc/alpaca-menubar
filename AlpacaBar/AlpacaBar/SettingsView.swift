import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @EnvironmentObject var account: AccountViewModel
    @State private var keyId: String = ""
    @State private var secret: String = ""
    @State private var isPaper: Bool = true
    @State private var launchAtLogin: Bool = false
    @State private var saved: Bool = false

    var body: some View {
        Form {
            Section("Alpaca API Credentials") {
                TextField("API Key ID", text: $keyId)
                    .textFieldStyle(.roundedBorder)
                SecureField("API Secret Key", text: $secret)
                    .textFieldStyle(.roundedBorder)
            }

            Section("Account Type") {
                Picker("", selection: $isPaper) {
                    Text("Paper Trading").tag(true)
                    Text("Live Trading").tag(false)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }

            Section("Startup") {
                Toggle("Launch at Login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { newVal in
                        setLaunchAtLogin(newVal)
                    }
            }

            HStack {
                Spacer()
                if saved {
                    Label("Saved!", systemImage: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .transition(.opacity)
                }
                Button("Save") {
                    account.apiKeyId  = keyId
                    account.apiSecret = secret
                    account.isPaper   = isPaper
                    account.isConfigured = !keyId.isEmpty && !secret.isEmpty
                    account.refresh()
                    withAnimation { saved = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation { saved = false }
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(keyId.isEmpty || secret.isEmpty)
            }
        }
        .formStyle(.grouped)
        .padding()
        .frame(width: 380, height: 320)
        .onAppear {
            keyId      = account.apiKeyId
            secret     = account.apiSecret
            isPaper    = account.isPaper
            launchAtLogin = getLaunchAtLogin()
        }
    }

    private func getLaunchAtLogin() -> Bool {
        if #available(macOS 13.0, *) {
            return SMAppService.mainApp.status == .enabled
        }
        return false
    }

    private func setLaunchAtLogin(_ enable: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enable {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("Launch at login error: \(error)")
            }
        }
    }
}
