import Foundation

/// Minimal secure key-value storage for small secrets — here the Lemon Squeezy
/// license key and its activation instance id. Abstracted so tests can swap in
/// an in-memory store; the real Keychain isn't unit-testable.
protocol SecureStore: Sendable {
    func string(forKey key: String) -> String?
    func set(_ value: String, forKey key: String)
    func removeValue(forKey key: String)
}
