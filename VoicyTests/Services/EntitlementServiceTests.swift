import Foundation
import Testing
@testable import Voicy

@MainActor
@Suite("EntitlementService derived limits")
struct EntitlementServiceTests {

    @Test("Free: limited everywhere")
    func freeLimits() {
        let e = MockEntitlementService(plan: .free)
        #expect(e.isPro == false)
        #expect(e.maxModeSlots == PlanLimits.freeModeSlots)
        #expect(e.maxSnippets == PlanLimits.freeSnippets)
        #expect(e.weeklyWordLimit == PlanLimits.freeWeeklyWords)
        #expect(e.monthlyFileMinuteLimit == PlanLimits.freeMonthlyFileMinutes)
        #expect(e.allowsCustomMode == false)
    }

    @Test("Pro: unlimited everywhere")
    func proLimits() {
        let e = MockEntitlementService(plan: .pro)
        #expect(e.isPro)
        #expect(e.maxModeSlots == PlanLimits.proModeSlots)
        #expect(e.maxSnippets == nil)
        #expect(e.weeklyWordLimit == nil)
        #expect(e.monthlyFileMinuteLimit == nil)
        #expect(e.allowsCustomMode)
    }

    @Test("Free: only the standard brain is allowed")
    func freeBrainGate() {
        let e = MockEntitlementService(plan: .free)
        #expect(e.canUseBrain(registryKey: PlanLimits.freeBrainRegistryKey))
        #expect(e.canUseBrain(registryKey: "gemma4_e4b_it_4bit") == false)
        #expect(e.canUseBrain(registryKey: "qwen2_5_7b") == false)
    }

    @Test("Pro: every brain is allowed")
    func proBrainGate() {
        let e = MockEntitlementService(plan: .pro)
        #expect(e.canUseBrain(registryKey: PlanLimits.freeBrainRegistryKey))
        #expect(e.canUseBrain(registryKey: "gemma4_e4b_it_4bit"))
        #expect(e.canUseBrain(registryKey: "qwen2_5_7b"))
    }

    @Test("DefaultEntitlementService reads and writes the Pro flag")
    func defaultReadsWritesFlag() {
        let defaults = UserDefaults(suiteName: "entitlement.test.\(UUID().uuidString)")!
        let service = DefaultEntitlementService(defaults: defaults)
        #expect(service.plan == .free)
        service.setPro(true)
        #expect(service.plan == .pro)
        service.setPro(false)
        #expect(service.plan == .free)
    }
}
