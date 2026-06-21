import Foundation
import Testing
@testable import Voicy

@MainActor
@Suite("DefaultLicenseService")
struct LicenseServiceTests {

    // MARK: - Fixtures

    private let now = Date(timeIntervalSince1970: 1_700_000_000)

    private func makeDefaults() -> UserDefaults {
        UserDefaults(suiteName: "license.test.\(UUID().uuidString)")!
    }

    /// A stored, already-activated license so refresh/deactivate have something
    /// to work with.
    private func licensedStore() -> MockSecureStore {
        MockSecureStore(["licenseKey": "KEY-123", "instanceID": "instance-abc"])
    }

    private func validation(
        valid: Bool = true,
        status: LicenseStatus = .active,
        instanceID: String? = "instance-abc",
        storeID: Int? = nil,
        variantID: Int? = nil,
        email: String? = "buyer@example.com",
        error: String? = nil
    ) -> LicenseValidation {
        LicenseValidation(
            valid: valid, error: error, status: status, instanceID: instanceID,
            storeID: storeID, variantID: variantID, customerEmail: email, instanceName: "Mac"
        )
    }

    private func makeService(
        client: MockLemonSqueezyClient,
        store: MockSecureStore,
        entitlement: MockEntitlementService,
        defaults: UserDefaults,
        config: LemonSqueezyConfig = LemonSqueezyConfig(storeID: 0, variantIDs: [], checkoutURL: URL(string: "https://voicy.pro")!),
        now: Date? = nil
    ) -> DefaultLicenseService {
        let fixed = now ?? self.now
        return DefaultLicenseService(
            client: client, secureStore: store, entitlement: entitlement,
            defaults: defaults, config: config, now: { fixed }
        )
    }

    // MARK: - Activation

    @Test("activate stores the key and grants Pro on success")
    func activateSuccess() async {
        let client = MockLemonSqueezyClient(activate: .success(validation()))
        let store = MockSecureStore()
        let entitlement = MockEntitlementService(plan: .free)
        let defaults = makeDefaults()
        let service = makeService(client: client, store: store, entitlement: entitlement, defaults: defaults)

        let result = await service.activate(key: "  KEY-123  ")

        #expect(result == .success(LicenseSnapshot(status: .active, customerEmail: "buyer@example.com", activationName: "Mac")))
        #expect(entitlement.isPro)
        #expect(store.string(forKey: "licenseKey") == "KEY-123") // trimmed
        #expect(store.string(forKey: "instanceID") == "instance-abc")
        #expect(defaults.object(forKey: Preferences.Key.licenseLastValidated) as? Double == now.timeIntervalSince1970)
    }

    @Test("activate rejects an empty key without hitting the network")
    func activateEmpty() async {
        let client = MockLemonSqueezyClient()
        let entitlement = MockEntitlementService(plan: .free)
        let service = makeService(client: client, store: MockSecureStore(), entitlement: entitlement, defaults: makeDefaults())

        #expect(await service.activate(key: "   ") == .failure(.invalidKey))
        #expect(entitlement.isPro == false)
    }

    @Test("activate maps an unknown key to invalidKey")
    func activateInvalidKey() async {
        let client = MockLemonSqueezyClient(activate: .success(validation(valid: false, error: "license_key not found")))
        let entitlement = MockEntitlementService(plan: .free)
        let service = makeService(client: client, store: MockSecureStore(), entitlement: entitlement, defaults: makeDefaults())

        #expect(await service.activate(key: "BAD") == .failure(.invalidKey))
        #expect(entitlement.isPro == false)
    }

    @Test("activate maps an exhausted activation limit")
    func activateLimitReached() async {
        let client = MockLemonSqueezyClient(activate: .success(validation(valid: false, error: "This license key has reached its activation limit.")))
        let service = makeService(client: client, store: MockSecureStore(), entitlement: MockEntitlementService(), defaults: makeDefaults())

        #expect(await service.activate(key: "KEY") == .failure(.activationLimitReached))
    }

    @Test("activate rejects a key from another product when configured")
    func activateWrongProduct() async {
        let client = MockLemonSqueezyClient(activate: .success(validation(storeID: 999, variantID: 888)))
        let entitlement = MockEntitlementService(plan: .free)
        let config = LemonSqueezyConfig(storeID: 100, variantIDs: [200], checkoutURL: URL(string: "https://voicy.pro")!)
        let service = makeService(client: client, store: MockSecureStore(), entitlement: entitlement, defaults: makeDefaults(), config: config)

        #expect(await service.activate(key: "KEY") == .failure(.wrongProduct))
        #expect(entitlement.isPro == false)
    }

    @Test("activate accepts a matching product when configured")
    func activateRightProduct() async {
        let client = MockLemonSqueezyClient(activate: .success(validation(storeID: 100, variantID: 200)))
        let entitlement = MockEntitlementService(plan: .free)
        let config = LemonSqueezyConfig(storeID: 100, variantIDs: [200, 201], checkoutURL: URL(string: "https://voicy.pro")!)
        let service = makeService(client: client, store: MockSecureStore(), entitlement: entitlement, defaults: makeDefaults(), config: config)

        if case .success = await service.activate(key: "KEY") {} else { Issue.record("expected success") }
        #expect(entitlement.isPro)
    }

    @Test("activate surfaces a transport failure as network")
    func activateTransport() async {
        let client = MockLemonSqueezyClient(activate: .failure(.transport("offline")))
        let service = makeService(client: client, store: MockSecureStore(), entitlement: MockEntitlementService(), defaults: makeDefaults())

        #expect(await service.activate(key: "KEY") == .failure(.network("offline")))
    }

    // MARK: - Launch refresh

    @Test("refresh keeps Pro and re-stamps the timestamp when active")
    func refreshActive() async {
        let client = MockLemonSqueezyClient(validate: .success(validation(status: .active)))
        let entitlement = MockEntitlementService(plan: .free)
        let defaults = makeDefaults()
        let service = makeService(client: client, store: licensedStore(), entitlement: entitlement, defaults: defaults)

        await service.refreshEntitlement()

        #expect(entitlement.isPro)
        #expect(defaults.object(forKey: Preferences.Key.licenseLastValidated) as? Double == now.timeIntervalSince1970)
    }

    @Test("refresh drops Pro and clears the key when the subscription expired")
    func refreshExpired() async {
        let client = MockLemonSqueezyClient(validate: .success(validation(valid: true, status: .expired)))
        let entitlement = MockEntitlementService(plan: .pro)
        let store = licensedStore()
        let service = makeService(client: client, store: store, entitlement: entitlement, defaults: makeDefaults())

        await service.refreshEntitlement()

        #expect(entitlement.isPro == false)
        #expect(store.string(forKey: "licenseKey") == nil)
        #expect(store.string(forKey: "instanceID") == nil)
    }

    @Test("refresh drops Pro when the key was disabled")
    func refreshDisabled() async {
        let client = MockLemonSqueezyClient(validate: .success(validation(valid: true, status: .disabled)))
        let entitlement = MockEntitlementService(plan: .pro)
        let service = makeService(client: client, store: licensedStore(), entitlement: entitlement, defaults: makeDefaults())

        await service.refreshEntitlement()
        #expect(entitlement.isPro == false)
    }

    @Test("refresh keeps Pro offline within the 7-day grace window")
    func refreshGraceWithin() async {
        let client = MockLemonSqueezyClient(validate: .failure(.transport("offline")))
        let entitlement = MockEntitlementService(plan: .pro)
        let defaults = makeDefaults()
        // Last validated 6 days ago — inside the 7-day window.
        defaults.set(now.addingTimeInterval(-6 * 24 * 60 * 60).timeIntervalSince1970,
                     forKey: Preferences.Key.licenseLastValidated)
        let store = licensedStore()
        let service = makeService(client: client, store: store, entitlement: entitlement, defaults: defaults)

        await service.refreshEntitlement()

        #expect(entitlement.isPro)
        #expect(store.string(forKey: "licenseKey") == "KEY-123") // key kept for later re-validation
    }

    @Test("refresh drops Pro offline past the grace window, keeping the key")
    func refreshGraceExpired() async {
        let client = MockLemonSqueezyClient(validate: .failure(.transport("offline")))
        let entitlement = MockEntitlementService(plan: .pro)
        let defaults = makeDefaults()
        // Last validated 8 days ago — outside the window.
        defaults.set(now.addingTimeInterval(-8 * 24 * 60 * 60).timeIntervalSince1970,
                     forKey: Preferences.Key.licenseLastValidated)
        let store = licensedStore()
        let service = makeService(client: client, store: store, entitlement: entitlement, defaults: defaults)

        await service.refreshEntitlement()

        #expect(entitlement.isPro == false)
        #expect(store.string(forKey: "licenseKey") == "KEY-123") // not cleared — only network-unreachable
    }

    @Test("refresh is a no-op when no license is stored")
    func refreshNoLicense() async {
        let client = MockLemonSqueezyClient(validate: .success(validation()))
        let entitlement = MockEntitlementService(plan: .pro) // e.g. debug toggle
        let service = makeService(client: client, store: MockSecureStore(), entitlement: entitlement, defaults: makeDefaults())

        await service.refreshEntitlement()
        #expect(entitlement.isPro) // untouched
    }

    // MARK: - Deactivation

    @Test("deactivate releases the activation, clears the key, and drops Pro")
    func deactivate() async {
        let client = MockLemonSqueezyClient()
        let entitlement = MockEntitlementService(plan: .pro)
        let store = licensedStore()
        let service = makeService(client: client, store: store, entitlement: entitlement, defaults: makeDefaults())

        await service.deactivate()

        #expect(client.deactivateCount == 1)
        #expect(store.isEmpty)
        #expect(entitlement.isPro == false)
    }
}
