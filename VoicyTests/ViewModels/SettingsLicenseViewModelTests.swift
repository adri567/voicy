import FactoryKit
import Foundation
import Testing
@testable import Voicy

@MainActor
@Suite("SettingsLicenseViewModel")
struct SettingsLicenseViewModelTests {

    init() { Container.shared.reset() }

    @Test("onAppear with no license stays in entry mode")
    func onAppearFree() {
        Container.shared.licenseService.register { MockLicenseService(hasStoredLicense: false) }
        let vm = SettingsLicenseViewModel()
        vm.onAppear()
        #expect(vm.hasLicense == false)
        #expect(vm.snapshot == nil)
    }

    @Test("onAppear with a license flags it; loadSnapshot fills the snapshot")
    func licensedSnapshot() async {
        let snap = LicenseSnapshot(status: .active, customerEmail: "buyer@example.com", activationName: "Mac")
        Container.shared.licenseService.register { MockLicenseService(hasStoredLicense: true, snapshot: snap) }
        let vm = SettingsLicenseViewModel()

        vm.onAppear()
        #expect(vm.hasLicense)

        await vm.loadSnapshot()
        #expect(vm.snapshot == snap)
    }

    @Test("canActivate requires a non-empty key and an idle phase")
    func canActivateLogic() {
        Container.shared.licenseService.register { MockLicenseService() }
        let vm = SettingsLicenseViewModel()

        #expect(vm.canActivate == false) // empty
        vm.keyInput = "  "
        #expect(vm.canActivate == false) // whitespace only
        vm.keyInput = "KEY-123"
        #expect(vm.canActivate)
        vm.phase = .activating
        #expect(vm.canActivate == false) // already in flight
    }

    @Test("a successful activation flips to the activated state (no relaunch)")
    func activationSuccess() async {
        let snap = LicenseSnapshot(status: .active, customerEmail: "buyer@example.com", activationName: "Mac")
        Container.shared.entitlementService.register { MockEntitlementService(plan: .free) }
        Container.shared.licenseService.register { MockLicenseService(activateResult: .success(snap)) }
        let vm = SettingsLicenseViewModel()
        vm.keyInput = "KEY-123"

        await vm.performActivation()

        #expect(vm.phase == .idle)
        #expect(vm.hasLicense)
        #expect(vm.snapshot == snap)
        #expect(vm.keyInput.isEmpty)
    }

    @Test("a failed activation surfaces the error message")
    func activationFailure() async {
        Container.shared.entitlementService.register { MockEntitlementService(plan: .free) }
        Container.shared.licenseService.register {
            MockLicenseService(activateResult: .failure(.activationLimitReached))
        }
        let vm = SettingsLicenseViewModel()
        vm.keyInput = "KEY-123"

        await vm.performActivation()

        #expect(vm.phase == .error(LicenseActivationError.activationLimitReached.message))
        #expect(vm.hasLicense == false)
    }

    @Test("checkoutURL comes from the license service")
    func checkout() {
        let url = URL(string: "https://store.example.com/buy/voicy-pro")!
        Container.shared.licenseService.register { MockLicenseService(checkoutURL: url) }
        let vm = SettingsLicenseViewModel()
        // openCheckout would hit NSWorkspace; assert the source URL instead.
        #expect(Container.shared.licenseService().checkoutURL == url)
    }
}
