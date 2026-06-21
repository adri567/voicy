import AppKit
import FactoryKit
import Foundation

/// Drives the Settings → Voicy Pro section: key entry, activation feedback, and
/// the deactivate/checkout actions. Activation/deactivation update the
/// entitlement and refresh the observable `EntitlementStore`, so Pro-gated views
/// switch over live — no app relaunch.
@Observable @MainActor final class SettingsLicenseViewModel {

    enum Phase: Equatable {
        case idle
        case activating
        case error(String)
    }

    var keyInput = ""
    var phase: Phase = .idle
    var snapshot: LicenseSnapshot?
    var hasLicense = false

    @ObservationIgnored @Injected(\.licenseService) private var licenseService
    @ObservationIgnored @Injected(\.entitlementStore) private var entitlementStore

    var canActivate: Bool {
        phase != .activating && !keyInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func onAppear() {
        hasLicense = licenseService.hasStoredLicense
        guard hasLicense else { return }
        Task { await loadSnapshot() }
    }

    /// Awaitable snapshot load, split out from `onAppear` for testability.
    func loadSnapshot() async {
        snapshot = await licenseService.currentSnapshot()
    }

    func activate() {
        Task { await performActivation() }
    }

    /// Awaitable core of `activate()` so tests can drive it without the
    /// fire-and-forget `Task`. On success it flips the UI to the activated state
    /// and refreshes the store so Pro-gated views update live.
    func performActivation() async {
        guard canActivate else { return }
        phase = .activating
        switch await licenseService.activate(key: keyInput) {
        case .success(let snapshot):
            self.snapshot = snapshot
            hasLicense = true
            keyInput = ""
            phase = .idle
            entitlementStore.refresh()
        case .failure(let error):
            phase = .error(error.message)
        }
    }

    func deactivate() {
        Task {
            await licenseService.deactivate()
            snapshot = nil
            hasLicense = false
            phase = .idle
            entitlementStore.refresh()
        }
    }

    func openCheckout() {
        NSWorkspace.shared.open(licenseService.checkoutURL)
    }
}
