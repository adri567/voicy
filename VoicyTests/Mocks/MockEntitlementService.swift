@testable import Voicy
import Synchronization

/// In-memory `EntitlementService` for tests. The plan is mutable so a test can
/// flip Free↔Pro and assert gate behaviour without touching UserDefaults.
///
/// Backed by a `Mutex` rather than actor isolation because the conformance is
/// used from nonisolated Factory registration closures — so the type must be
/// genuinely `Sendable`, not `@MainActor`.
final class MockEntitlementService: EntitlementService {
    private let _plan: Mutex<Plan>

    nonisolated init(plan: Plan = .free) {
        _plan = Mutex(plan)
    }

    var plan: Plan { _plan.withLock { $0 } }

    func setPro(_ isPro: Bool) {
        _plan.withLock { $0 = isPro ? .pro : .free }
    }
}
