@testable import Voicy
import Synchronization

/// Scriptable `LemonSqueezyClient` for tests. Each endpoint returns a preset
/// `Result` — `.success` yields a `LicenseValidation`, `.failure` throws a
/// `LemonSqueezyClientError` (used to drive the offline-grace paths).
final class MockLemonSqueezyClient: LemonSqueezyClient {
    private struct State {
        var activateResult: Result<LicenseValidation, LemonSqueezyClientError>
        var validateResult: Result<LicenseValidation, LemonSqueezyClientError>
        var deactivateCount = 0
    }

    private let state: Mutex<State>

    nonisolated init(
        activate: Result<LicenseValidation, LemonSqueezyClientError> = .failure(.badResponse),
        validate: Result<LicenseValidation, LemonSqueezyClientError> = .failure(.badResponse)
    ) {
        state = Mutex(State(activateResult: activate, validateResult: validate))
    }

    func activate(key: String, instanceName: String) async throws -> LicenseValidation {
        try state.withLock { try $0.activateResult.get() }
    }

    func validate(key: String, instanceID: String) async throws -> LicenseValidation {
        try state.withLock { try $0.validateResult.get() }
    }

    func deactivate(key: String, instanceID: String) async throws {
        state.withLock { $0.deactivateCount += 1 }
    }

    var deactivateCount: Int { state.withLock { $0.deactivateCount } }
}
