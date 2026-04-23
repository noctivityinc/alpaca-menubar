import SwiftUI
import ServiceManagement
import AppKit

enum AuthState: Equatable {
    case idle
    case checking
    case success
    case failure(String)
}

struct SettingsView: View {
    @ObservedObject var account: AccountViewModel
    @State private var keyId: String = ""
    @State private var secret: String = ""
    @State private var isPaper: Bool = true
    @State private var launchAtLogin: Bool = false
    @State private var authState: AuthState = .idle

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text("AlpacaBar Setup")
                    .font(.headline)
                Text("Enter your Alpaca API credentials to connect.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding()

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Credentials
                    GroupBox(label: Text("Alpaca API Credentials").font(.caption).foregroundColor(.secondary)) {
                        VStack(alignment: .leading, spacing: 10) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("API Key ID").font(.caption).foregroundColor(.secondary)
                                TextField("PK...", text: $keyId)
                                    .textFieldStyle(.roundedBorder)
                                    .autocorrectionDisabled()
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Text("API Secret").font(.caption).foregroundColor(.secondary)
                                SecureField("Secret key", text: $secret)
                                    .textFieldStyle(.roundedBorder)
                            }
                            Button("Find my API keys →") {
                                NSWorkspace.shared.open(URL(string: "https://app.alpaca.markets/paper/dashboard/overview")!)
                            }
                            .buttonStyle(.plain)
                            .font(.caption)
                            .foregroundColor(.accentColor)
                        }
                        .padding(8)
                    }

                    // Account type
                    GroupBox(label: Text("Account Type").font(.caption).foregroundColor(.secondary)) {
                        Picker("", selection: $isPaper) {
                            Text("Paper Trading").tag(true)
                            Text("Live Trading").tag(false)
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                        .padding(8)
                    }

                    // Launch at login
                    GroupBox(label: Text("Startup").font(.caption).foregroundColor(.secondary)) {
                        Toggle("Launch at Login", isOn: $launchAtLogin)
                            .onChange(of: launchAtLogin) { _, newVal in setLaunchAtLogin(newVal) }
                            .padding(8)
                    }
                }
                .padding()
            }

            Divider()

            // Footer
            HStack(spacing: 12) {
                authStatusView
                Spacer()
                Button("Save & Connect") {
                    saveAndVerify()
                }
                .buttonStyle(.borderedProminent)
                .disabled(keyId.trimmingCharacters(in: .whitespaces).isEmpty || authState == .checking)
            }
            .padding()
        }
        .frame(width: 420, height: 460)
        .onAppear {
            keyId         = account.apiKeyId
            secret        = account.apiSecret
            isPaper       = account.isPaper
            launchAtLogin = getLaunchAtLogin()
            if !keyId.isEmpty {
                checkAuth(keyId: keyId, secret: secret, paper: isPaper)
            }
        }
    }

    @ViewBuilder
    private var authStatusView: some View {
        switch authState {
        case .idle:
            EmptyView()
        case .checking:
            HStack(spacing: 6) {
                ProgressView().scaleEffect(0.7)
                Text("Connecting…").font(.caption).foregroundColor(.secondary)
            }
        case .success:
            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                Text("Connected!").font(.caption).foregroundColor(.green)
            }
        case .failure(let msg):
            HStack(alignment: .top, spacing: 6) {
                Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.red)
                Text(msg).font(.caption).foregroundColor(.red).fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: 220)
        }
    }

    private func saveAndVerify() {
        let k = keyId.trimmingCharacters(in: .whitespaces)
        let s = secret.trimmingCharacters(in: .whitespaces)
        account.apiKeyId  = k
        account.apiSecret = s
        account.isPaper   = isPaper
        checkAuth(keyId: k, secret: s, paper: isPaper)
    }

    private func checkAuth(keyId: String, secret: String, paper: Bool) {
        authState = .checking
        let base = paper ? "https://paper-api.alpaca.markets" : "https://api.alpaca.markets"
        guard let url = URL(string: "\(base)/v2/account") else { return }
        var req = URLRequest(url: url, timeoutInterval: 8)
        req.setValue(keyId, forHTTPHeaderField: "APCA-API-KEY-ID")
        req.setValue(secret.isEmpty ? keyId : secret, forHTTPHeaderField: "APCA-API-SECRET-KEY")

        URLSession.shared.dataTask(with: req) { _, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    authState = .failure("Connection error: \(error.localizedDescription)")
                    return
                }
                let status = (response as? HTTPURLResponse)?.statusCode ?? 0
                switch status {
                case 200:
                    authState = .success
                    account.isConfigured = true
                    account.refresh()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                        SettingsWindowController.shared?.close()
                        SettingsWindowController.shared = nil
                    }
                case 401, 403:
                    authState = .failure("Invalid credentials. Check your Key ID and Secret at app.alpaca.markets → API.")
                default:
                    authState = .failure("Error (HTTP \(status)). Try again.")
                }
            }
        }.resume()
    }

    private func getLaunchAtLogin() -> Bool {
        SMAppService.mainApp.status == .enabled
    }

    private func setLaunchAtLogin(_ enable: Bool) {
        do {
            if enable { try SMAppService.mainApp.register() }
            else       { try SMAppService.mainApp.unregister() }
        } catch {
            print("Launch at login error: \(error)")
        }
    }
}
