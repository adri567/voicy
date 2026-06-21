import FactoryKit
import Foundation

/// Default `LicenseService`: coordinates the Lemon Squeezy client, the Keychain,
/// and the entitlement flag. A `final class` (no mutable state of its own — only
/// `let` dependencies) following the same pattern as `DefaultEntitlementService`;
/// the network round-trips happen in the `nonisolated` client and suspend off
/// the main actor.
final class DefaultLicenseService: LicenseService {

    private let client: any LemonSqueezyClient
    private let secureStore: any SecureStore
    private let entitlement: any EntitlementService
    private let defaults: UserDefaults
    private let config: LemonSqueezyConfig
    private let now: @Sendable () -> Date

    /// Pro stays active offline for this long after the last successful
    /// validation, so a subscriber who's briefly offline keeps working. A
    /// definitive "invalid" from the server withdraws Pro immediately regardless.
    private static let graceInterval: TimeInterval = 7 * 24 * 60 * 60

    private enum StoreKey {
        static let licenseKey = "licenseKey"
        static let instanceID = "instanceID"
    }

    init(
        client: any LemonSqueezyClient = Container.shared.lemonSqueezyClient(),
        secureStore: any SecureStore = Container.shared.secureStore(),
        entitlement: any EntitlementService = Container.shared.entitlementService(),
        defaults: UserDefaults = .standard,
        config: LemonSqueezyConfig = .loadFromBundle(),
        now: @escaping @Sendable () -> Date = { .now }
    ) {
        self.client = client
        self.secureStore = secureStore
        self.entitlement = entitlement
        self.defaults = defaults
        self.config = config
        self.now = now
    }

    var checkoutURL: URL { config.checkoutURL }

    var hasStoredLicense: Bool {
        secureStore.string(forKey: StoreKey.licenseKey) != nil
    }

    // MARK: - Activation

    func activate(key: String) async -> Result<LicenseSnapshot, LicenseActivationError> {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .failure(.invalidKey) }

        let result: LicenseValidation
        do {
            result = try await client.activate(key: trimmed, instanceName: Self.instanceName())
        } catch let error as LemonSqueezyClientError {
            return .failure(Self.mapClientError(error))
        } catch {
            return .failure(.network(error.localizedDescription))
        }

        guard result.valid, let instanceID = result.instanceID else {
            return .failure(Self.mapActivationFailure(result.error))
        }
        guard config.accepts(storeID: result.storeID, variantID: result.variantID) else {
            return .failure(.wrongProduct)
        }

        secureStore.set(trimmed, forKey: StoreKey.licenseKey)
        secureStore.set(instanceID, forKey: StoreKey.instanceID)
        markValidated()
        entitlement.setPro(true)

        return .success(snapshot(from: result))
    }

    func currentSnapshot() async -> LicenseSnapshot? {
        guard
            let key = secureStore.string(forKey: StoreKey.licenseKey),
            let instanceID = secureStore.string(forKey: StoreKey.instanceID)
        else { return nil }

        // Best-effort live status; fall back to a plain "active" snapshot when
        // offline so the UI still shows the device as licensed.
        if let result = try? await client.validate(key: key, instanceID: instanceID) {
            return snapshot(from: result)
        }
        return LicenseSnapshot(status: .active, customerEmail: nil, activationName: nil)
    }

    func deactivate() async {
        if
            let key = secureStore.string(forKey: StoreKey.licenseKey),
            let instanceID = secureStore.string(forKey: StoreKey.instanceID) {
            try? await client.deactivate(key: key, instanceID: instanceID)
        }
        clearStoredLicense()
        entitlement.setPro(false)
    }

    // MARK: - Launch validation

    func refreshEntitlement() async {
        guard
            let key = secureStore.string(forKey: StoreKey.licenseKey),
            let instanceID = secureStore.string(forKey: StoreKey.instanceID)
        else { return }   // no license — leave the flag untouched (e.g. debug toggle)

        do {
            let result = try await client.validate(key: key, instanceID: instanceID)
            let accepted = config.accepts(storeID: result.storeID, variantID: result.variantID)
            if result.valid, result.status == .active, accepted {
                markValidated()
                entitlement.setPro(true)
            } else {
                // Definitive rejection — drop Pro and forget the key.
                clearStoredLicense()
                entitlement.setPro(false)
            }
        } catch {
            // Network failure — honour the offline grace window. Keep the key so
            // a later successful validation can restore Pro.
            entitlement.setPro(withinGracePeriod())
        }
    }

    // MARK: - Helpers

    private func snapshot(from result: LicenseValidation) -> LicenseSnapshot {
        LicenseSnapshot(
            status: result.status,
            customerEmail: result.customerEmail,
            activationName: result.instanceName
        )
    }

    private func markValidated() {
        defaults.set(now().timeIntervalSince1970, forKey: Preferences.Key.licenseLastValidated)
    }

    private func withinGracePeriod() -> Bool {
        guard let last = defaults.object(forKey: Preferences.Key.licenseLastValidated) as? Double else {
            return false
        }
        return now().timeIntervalSince1970 - last <= Self.graceInterval
    }

    private func clearStoredLicense() {
        secureStore.removeValue(forKey: StoreKey.licenseKey)
        secureStore.removeValue(forKey: StoreKey.instanceID)
        defaults.removeObject(forKey: Preferences.Key.licenseLastValidated)
    }

    private static func mapClientError(_ error: LemonSqueezyClientError) -> LicenseActivationError {
        switch error {
        case .transport(let detail): .network(detail)
        case .badResponse: .server("unexpected response")
        }
    }

    private static func mapActivationFailure(_ error: String?) -> LicenseActivationError {
        guard let error = error?.lowercased() else { return .invalidKey }
        if error.contains("activation limit") { return .activationLimitReached }
        if error.contains("not found") || error.contains("does not exist") { return .invalidKey }
        return .server(error)
    }

    private static func instanceName() -> String {
        Host.current().localizedName ?? ProcessInfo.processInfo.hostName
    }
}
