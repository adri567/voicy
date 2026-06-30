import FactoryKit
import Testing
@testable import Voicy

/// The built-in Apple brain has no download, so the install/remove paths must
/// short-circuit without touching the MLX download/delete logic. Serialized
/// because each test registers shared Factory services.
@MainActor
@Suite("BrainViewModel · Apple built-in brain", .serialized)
struct BrainViewModelAppleTests {

    private func makeViewModel() -> BrainViewModel {
        Container.shared.entitlementService.register { MockEntitlementService(plan: .free) }
        Container.shared.telemetryService.register { SpyTelemetryService() }
        return BrainViewModel()
    }

    @Test("install is a no-op for the built-in Apple brain")
    func installIsNoOp() async {
        let vm = makeViewModel()
        await vm.install(registryKey: BrainBackend.appleRegistryKey)
        // Never entered the downloading state — nothing to download.
        #expect(vm.statuses[BrainBackend.appleRegistryKey] == nil)
        #expect(vm.lastError == nil)
    }

    @Test("remove is a no-op for the built-in Apple brain")
    func removeIsNoOp() async {
        let vm = makeViewModel()
        vm.statuses[BrainBackend.appleRegistryKey] = .active
        await vm.remove(registryKey: BrainBackend.appleRegistryKey)
        // Still active — the OS model can't be deleted.
        #expect(vm.statuses[BrainBackend.appleRegistryKey] == .active)
    }

    @Test("Free plan may use the built-in Apple brain")
    func freePlanAllowsAppleBrain() {
        let vm = makeViewModel()
        let apple = llmModel("apple", registryKey: BrainBackend.appleRegistryKey)
        #expect(vm.canUse(apple))
    }
}
