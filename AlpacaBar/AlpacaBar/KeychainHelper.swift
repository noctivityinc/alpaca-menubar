import Foundation

// During development (unsigned builds), Keychain prompts repeatedly.
// We use UserDefaults here for simplicity. For a signed/distributed build,
// swap this back to Security framework keychain calls.
enum KeychainHelper {
    private static func key(_ service: String, _ account: String) -> String {
        "\(service).\(account)"
    }

    static func save(service: String, account: String, value: String) {
        UserDefaults.standard.set(value, forKey: key(service, account))
    }

    static func load(service: String, account: String) -> String? {
        UserDefaults.standard.string(forKey: key(service, account))
    }

    static func delete(service: String, account: String) {
        UserDefaults.standard.removeObject(forKey: key(service, account))
    }
}
