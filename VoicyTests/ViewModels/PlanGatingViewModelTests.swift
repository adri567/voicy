import FactoryKit
import Testing
@testable import Voicy

/// Integration of the plan gate into the Brain and Snippets view models.
/// Serialized because each test registers shared Factory services before
/// constructing its view model.
@MainActor
@Suite("Plan gating · Brain & Snippets", .serialized)
struct PlanGatingViewModelTests {

    // MARK: - BrainViewModel.canUse

    @Test("Free: only the standard brain is usable")
    func brainFreeGate() {
        Container.shared.entitlementService.register { MockEntitlementService(plan: .free) }
        let vm = BrainViewModel()
        let standard = llmModel("std", registryKey: PlanLimits.freeBrainRegistryKey)
        let premium = llmModel("prem", registryKey: "gemma4_e4b_it_4bit")
        let cloud = llmModel("cloud", registryKey: nil, location: .cloud)
        #expect(vm.canUse(standard))
        #expect(vm.canUse(premium) == false)
        // Cloud models have no registry key — not gated here (they're Coming Soon).
        #expect(vm.canUse(cloud))
    }

    @Test("Pro: every brain is usable")
    func brainProGate() {
        Container.shared.entitlementService.register { MockEntitlementService(plan: .pro) }
        let vm = BrainViewModel()
        #expect(vm.canUse(llmModel("std", registryKey: PlanLimits.freeBrainRegistryKey)))
        #expect(vm.canUse(llmModel("e4b", registryKey: "gemma4_e4b_it_4bit")))
        #expect(vm.canUse(llmModel("qwen", registryKey: "qwen2_5_7b")))
    }

    // MARK: - SnippetsViewModel.canCreateSnippet

    @Test("Free under cap: can create")
    func snippetsFreeUnderCap() async {
        Container.shared.entitlementService.register { MockEntitlementService(plan: .free) }
        Container.shared.snippetService.register { MockSnippetService(count: PlanLimits.freeSnippets - 1) }
        let vm = SnippetsViewModel()
        await vm.reload()
        #expect(vm.canCreateSnippet)
    }

    @Test("Free at cap: cannot create")
    func snippetsFreeAtCap() async {
        Container.shared.entitlementService.register { MockEntitlementService(plan: .free) }
        Container.shared.snippetService.register { MockSnippetService(count: PlanLimits.freeSnippets) }
        let vm = SnippetsViewModel()
        await vm.reload()
        #expect(vm.canCreateSnippet == false)
    }

    @Test("Pro at Free cap: still can create (unlimited)")
    func snippetsProUnlimited() async {
        Container.shared.entitlementService.register { MockEntitlementService(plan: .pro) }
        Container.shared.snippetService.register { MockSnippetService(count: PlanLimits.freeSnippets + 5) }
        let vm = SnippetsViewModel()
        await vm.reload()
        #expect(vm.canCreateSnippet)
    }
}
