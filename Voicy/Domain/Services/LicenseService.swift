import Foundation

/// Owns the Lemon Squeezy license lifecycle and is the only writer of the Pro
/// entitlement flag once a real store is wired up. Activation/deactivation are
/// user-driven (Settings); `refreshEntitlement` runs at launch to re-validate a
/// subscription and withdraw Pro when it has lapsed.
///
/// Plan changes take effect on relaunch (same model as engine/brain switches),
/// so the UI relaunches after activate/deactivate.
protocol LicenseService: Sendable {
    /// Whether a license key is stored on this device — drives the Settings UI.
    var hasStoredLicense: Bool { get }

    /// The checkout page to open in the browser for purchasing Pro.
    var checkoutURL: URL { get }

    /// Validates and stores a key, granting Pro on success.
    func activate(key: String) async -> Result<LicenseSnapshot, LicenseActivationError>

    /// A read-only view of the stored license for display, if any.
    func currentSnapshot() async -> LicenseSnapshot?

    /// Releases this device's activation and drops Pro.
    func deactivate() async

    /// Re-validates the stored license at launch; updates the Pro flag per the
    /// offline-grace policy.
    func refreshEntitlement() async
}
