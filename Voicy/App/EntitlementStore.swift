import FactoryKit
import Foundation

/// Observable mirror of the Pro entitlement for the UI. `EntitlementService` is
/// a stateless UserDefaults reader that SwiftUI can't observe, so this store
/// holds `isPro` as observed state: a license activation/deactivation updates
/// Pro-gated views live, without an app relaunch.
///
/// `EntitlementService` stays the source of truth (it writes the flag); this is
/// just the published mirror. Every code path that flips the flag — the license
/// service's launch validation, the Settings activation flow, the debug toggle —
/// calls `refresh()` afterwards so the mirror tracks it.
@Observable @MainActor final class EntitlementStore {
    private(set) var isPro: Bool

    @ObservationIgnored @Injected(\.entitlementService) private var entitlement

    init() {
        isPro = Container.shared.entitlementService().isPro
    }

    /// Re-reads the plan flag and publishes it. No-op when unchanged, so callers
    /// can fire it liberally without spurious view invalidations.
    func refresh() {
        let current = entitlement.isPro
        if current != isPro { isPro = current }
    }
}
