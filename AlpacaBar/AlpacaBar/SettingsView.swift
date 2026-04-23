import SwiftUI
import ServiceManagement

enum AuthState {
    case idle
    case checking
    case success
    case failure(String)
}

struct SettingsView: View {
    @EnvironmentObject var account: AccountViewModel
    @State private var keyId: String = ""
    @State private var secret: String = ""
    @State private var isPaper: Bool = true
    @State private var launchAtLogin: Bool = false
    @State private var authState: AuthState = .idle
    @Environment(\.dismiss) private var dismiss

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

            Form {
                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("API Key")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("PK5XFH...", text: $keyId)
                            .textFieldStyle(.roundedBorder)
                            .autocorrectionDisabled()
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("API Secret (if shown — otherwise leave blank)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        SecureField("Optional", text: $secret)
                            .textFieldStyle(.roundedBorder)
                    }

                    Link("Find your API keys at app.alpaca.markets → API",
                         destination: URL(string: "https://app.alpaca.markets/paper/dashboard/overview")!)
                        .font(.caption)
                        .padding(.top, 2)

                } header: {
                    Text("Alpaca API Credentials")
                }

                Section {
                    Picker("Account Type", selection: $isPaper) {
                        Text("Paper Trading").tag(true)
                        Text("Live Trading").tag(false)
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Account Type")
                }

                Section {
                    Toggle("Launch at Login", isOn: $launchAtLogin)
                        .onChange(of: launchAtLogin) { _, newVal in
                            setLaunchAtLogin(newVal)
                        }
                } header: {
                    Text("Startup")
                }
            }
            .formStyle(.grouped)

            Divider()

            // Auth status + Save button
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
        .frame(width: 420, height: 480)
        .onAppear {
            keyId         = account.apiKeyId
            secret        = account.apiSecret
            isPaper       = account.isPaper
            launchAtLogin = getLaunchAtLogin()
            // If we already have a key, test it on open
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
        }
    }

    private func saveAndVerify() {
        let trimmedKey    = keyId.trimmingCharacters(in: .whitespaces)
        let trimmedSecret = secret.trimmingCharacters(in: .whitespaces)
        account.apiKeyId  = trimmedKey
        account.apiSecret = trimmedSecret.isEmpty ? trimmedKey : trimmedSecret
        account.isPaper   = isPaper
        checkAuth(keyId: trimmedKey, secret: trimmedSecret.isEmpty ? trimmedKey : trimmedSecret, paper: isPaper)
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
                    // Auto-close after brief success display
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                        dismiss()
                    }
                case 401, 403:
                    authState = .failure("Invalid API key. Double-check your key at app.alpaca.markets → API.")
                case 403:
                    authState = .failure("Access forbidden. Make sure you're using the correct account type (paper vs live).")
                default:
                    authState = .failure("Unexpected error (HTTP \(status)). Try again.")
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
