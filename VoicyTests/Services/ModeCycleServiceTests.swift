import Foundation
import Testing
@testable import Voicy

@MainActor
@Suite("ModeCycleService")
struct ModeCycleServiceTests {

    /// Isolated defaults per test instance so the persisted reel never races or
    /// inherits another suite's writes. Pro entitlement so slot mechanics run at
    /// full capacity — plan gating has its own suite below.
    let defaults: UserDefaults

    init() {
        defaults = UserDefaults(suiteName: "modecycle.test.\(UUID().uuidString)")!
    }

    private func makeService() -> ModeCycleService {
        ModeCycleService(entitlement: MockEntitlementService(plan: .pro), defaults: defaults)
    }

    @Test("Default-Reel: 3 Slots, step=0, Source=de")
    func defaultReel() {
        let service = makeService()
        #expect(service.modes.count == 3)
        #expect(service.step == 0)
        #expect(service.sourceLanguage.code == "de")
        #expect(service.modes[0].type == .raw)
        #expect(service.modes[1].type == .translate)
        #expect(service.modes[2].type == .email)
    }

    @Test("cycleForward wrappt vom letzten Slot zu 0")
    func cycleForwardWraps() {
        let service = makeService()
        service.setStep(service.usableSlotCount - 1)
        service.cycleForward()
        #expect(service.step == 0)
    }

    @Test("cycleBackward wrappt von 0 zum letzten Slot")
    func cycleBackwardWraps() {
        let service = makeService()
        service.setStep(0)
        service.cycleBackward()
        #expect(service.step == service.usableSlotCount - 1)
    }

    @Test("addMode: clamped bei maxSlots")
    func addModeClampedAtMax() {
        let service = makeService()
        while service.modes.count < ModeCycleService.maxSlots {
            _ = service.addMode()
        }
        #expect(service.modes.count == ModeCycleService.maxSlots)
        let attempt = service.addMode()
        #expect(attempt == nil)
        #expect(service.modes.count == ModeCycleService.maxSlots)
    }

    @Test("removeMode: kann alle non-raw Slots entfernen, Raw bleibt")
    func removeModeDownToRawOnly() {
        let service = makeService()
        #expect(service.modes.count == 3)
        while service.modes.count > 1 {
            let id = service.modes[1].id
            service.removeMode(id: id)
        }
        #expect(service.modes.count == ModeCycleService.minSlots)
        #expect(service.modes[0].type == .raw)
    }

    @Test("move: tauscht Positionen und step folgt")
    func moveReorders() {
        let service = makeService()
        let originalSecond = service.modes[1].id
        service.setStep(1)
        service.move(id: originalSecond, by: 1)
        #expect(service.modes[2].id == originalSecond)
        #expect(service.step == 2)
    }

    @Test("update mutates only the given slot")
    func updateMutates() {
        let service = makeService()
        let id = service.modes[1].id
        service.update(id: id) { $0.targetCode = "es" }
        #expect(service.modes[1].targetCode == "es")
        #expect(service.modes[0].type == .raw)
    }

    @Test("setSourceLanguage: Translate-Slots mit target==newSource werden remapped")
    func setSourceLanguageReconcilesTargets() {
        let service = makeService()
        let id = service.modes[1].id
        service.update(id: id) { $0.targetCode = "en" }
        service.setSourceLanguage("en")
        #expect(service.sourceLanguage.code == "en")
        #expect(service.modes[1].targetCode != "en")
    }

    @Test("Persistence: nach setSourceLanguage liest neuer Service den Wert")
    func sourcePersists() {
        let service = makeService()
        service.setSourceLanguage("es")
        let next = makeService()
        #expect(next.sourceLanguage.code == "es")
    }

    @Test("Persistence: nach update wird Reel persisted")
    func modesPersist() {
        let service = makeService()
        let id = service.modes[1].id
        service.update(id: id) { $0.targetCode = "it" }
        let next = makeService()
        #expect(next.modes[1].targetCode == "it")
    }

    @Test("Slot 0: Type kann nicht via update geändert werden")
    func slot0TypeLocked() {
        let service = makeService()
        let id = service.modes[0].id
        service.update(id: id) { $0.type = .email }
        #expect(service.modes[0].type == .raw)
    }

    @Test("Slot 0: removeMode wird ignoriert")
    func slot0RemoveBlocked() {
        let service = makeService()
        _ = service.addMode()
        let countBefore = service.modes.count
        let id = service.modes[0].id
        service.removeMode(id: id)
        #expect(service.modes.count == countBefore)
        #expect(service.modes[0].id == id)
    }

    @Test("Slot 0: move wird ignoriert")
    func slot0MoveBlocked() {
        let service = makeService()
        let id = service.modes[0].id
        service.move(id: id, by: 1)
        #expect(service.modes[0].id == id)
    }

    @Test("Slot 1: move(by: -1) verschiebt nicht in slot 0")
    func cannotDisplaceSlot0() {
        let service = makeService()
        let slot0 = service.modes[0].id
        let slot1 = service.modes[1].id
        service.move(id: slot1, by: -1)
        #expect(service.modes[0].id == slot0)
        #expect(service.modes[1].id == slot1)
    }
}

@MainActor
@Suite("ModeCycleService plan gating")
struct ModeCycleServicePlanGatingTests {

    let defaults: UserDefaults

    init() {
        defaults = UserDefaults(suiteName: "modecycle.gating.\(UUID().uuidString)")!
    }

    private func makeService(plan: Plan) -> ModeCycleService {
        ModeCycleService(entitlement: MockEntitlementService(plan: plan), defaults: defaults)
    }

    @Test("Free: slotLimit ist freeModeSlots, canAddSlot false ab Limit")
    func freeSlotLimit() {
        let service = makeService(plan: .free)
        #expect(service.slotLimit == PlanLimits.freeModeSlots)
        // Default reel already fills the free allowance (Raw + Translate + Email).
        #expect(service.modes.count == PlanLimits.freeModeSlots)
        #expect(service.canAddSlot == false)
        #expect(service.addMode() == nil)
        #expect(service.modes.count == PlanLimits.freeModeSlots)
    }

    @Test("Pro: kann bis maxSlots hinzufügen")
    func proCanFillToMax() {
        let service = makeService(plan: .pro)
        #expect(service.slotLimit == ModeCycleService.maxSlots)
        while service.canAddSlot { _ = service.addMode() }
        #expect(service.modes.count == ModeCycleService.maxSlots)
    }

    @Test("Free: Custom-Mode wird beim update abgewiesen")
    func freeRejectsCustomMode() {
        let service = makeService(plan: .free)
        #expect(service.allowsCustomMode == false)
        let id = service.modes[1].id
        let originalType = service.modes[1].type
        service.update(id: id) { $0.type = .custom }
        #expect(service.modes[1].type == originalType)
    }

    @Test("Pro: Custom-Mode wird akzeptiert")
    func proAllowsCustomMode() {
        let service = makeService(plan: .pro)
        #expect(service.allowsCustomMode)
        let id = service.modes[1].id
        service.update(id: id) { $0.type = .custom }
        #expect(service.modes[1].type == .custom)
    }

    @Test("Free nach Pro-Reel: usableSlotCount klemmt, Cycle überspringt locked slots")
    func downgradeClampsUsableSlots() {
        // Build a 6-slot reel as Pro, persisting to the shared (isolated) defaults.
        let pro = makeService(plan: .pro)
        while pro.canAddSlot { _ = pro.addMode() }
        #expect(pro.modes.count == ModeCycleService.maxSlots)

        // Reload the same reel as Free.
        let free = makeService(plan: .free)
        #expect(free.modes.count == ModeCycleService.maxSlots)
        #expect(free.usableSlotCount == PlanLimits.freeModeSlots)
        #expect(free.isPlanLocked(at: PlanLimits.freeModeSlots))
        #expect(free.isPlanLocked(at: 0) == false)

        // setStep can't select a plan-locked slot.
        free.setStep(ModeCycleService.maxSlots - 1)
        #expect(free.step == 0)

        // Cycling stays within the usable range.
        free.setStep(PlanLimits.freeModeSlots - 1)
        free.cycleForward()
        #expect(free.step == 0)
    }
}
