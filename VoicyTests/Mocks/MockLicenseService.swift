@testable import Voicy
import Foundation
import Synchronization

/// In-memory `LicenseService` for ViewModel tests. Preset the stored-license
/// flag, snapshot, and activation outcome; counters record what was called.
final class MockLicenseService: LicenseService {
    private struct State {
        var hasStoredLicense: Bool
        var checkoutURL: URL
        var activateResult: Result<LicenseSnapshot, LicenseActivationError>
        var snapshot: LicenseSnapshot?
        var deactivateCount = 0
        var refreshCount = 0
    }

    private let state: Mutex<State>

    nonisolated init(
        hasStoredLicense: Bool = false,
        checkoutURL: URL = URL(string: "https://voicy.pro")!,
        activateResult: Result<LicenseSnapshot, LicenseActivationError> = .failure(.invalidKey),
        snapshot: LicenseSnapshot? = nil
    ) {
        state = Mutex(State(
            hasStoredLicense: hasStoredLicense,
            checkoutURL: checkoutURL,
            activateResult: activateResult,
            snapshot: snapshot
        ))
    }

    var hasStoredLicense: Bool { state.withLock { $0.hasStoredLicense } }
    var checkoutURL: URL { state.withLock { $0.checkoutURL } }

    func activate(key: String) async -> Result<LicenseSnapshot, LicenseActivationError> {
        state.withLock { $0.activateResult }
    }

    func currentSnapshot() async -> LicenseSnapshot? {
        state.withLock { $0.snapshot }
    }

    func deactivate() async { state.withLock { $0.deactivateCount += 1 } }
    func refreshEntitlement() async { state.withLock { $0.refreshCount += 1 } }

    var deactivateCount: Int { state.withLock { $0.deactivateCount } }
    var refreshCount: Int { state.withLock { $0.refreshCount } }
}
