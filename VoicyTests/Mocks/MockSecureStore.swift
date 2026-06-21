@testable import Voicy
import Synchronization

/// In-memory `SecureStore` for tests. `Mutex`-backed for a genuine `Sendable`
/// conformance, like the other mocks — it's resolved through nonisolated Factory
/// closures and used off the main actor.
final class MockSecureStore: SecureStore {
    private let storage: Mutex<[String: String]>

    nonisolated init(_ initial: [String: String] = [:]) {
        storage = Mutex(initial)
    }

    func string(forKey key: String) -> String? { storage.withLock { $0[key] } }
    func set(_ value: String, forKey key: String) { storage.withLock { $0[key] = value } }
    func removeValue(forKey key: String) { _ = storage.withLock { $0.removeValue(forKey: key) } }

    /// Read accessor for assertions.
    var isEmpty: Bool { storage.withLock { $0.isEmpty } }
}
