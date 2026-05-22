import Testing
@testable import Voicy

@MainActor
@Suite("ModeCycleService", .serialized)
struct ModeCycleServiceTests {

    @Test("Default-Reel: 4 Slots, step=0, Source=de")
    func defaultReel() {
        clearModeCycleDefaults()
        let service = ModeCycleService()
        #expect(service.modes.count == 4)
        #expect(service.step == 0)
        #expect(service.sourceLanguage.code == "de")
        #expect(service.modes[0].type == .raw)
        #expect(service.modes[1].type == .translate)
        #expect(service.modes[2].type == .translate)
        #expect(service.modes[3].type == .email)
    }

    @Test("cycleForward wrappt vom letzten Slot zu 0")
    func cycleForwardWraps() {
        clearModeCycleDefaults()
        let service = ModeCycleService()
        service.setStep(service.modes.count - 1)
        service.cycleForward()
        #expect(service.step == 0)
    }

    @Test("cycleBackward wrappt von 0 zum letzten Slot")
    func cycleBackwardWraps() {
        clearModeCycleDefaults()
        let service = ModeCycleService()
        service.setStep(0)
        service.cycleBackward()
        #expect(service.step == service.modes.count - 1)
    }

    @Test("addMode: clamped bei maxSlots")
    func addModeClampedAtMax() {
        clearModeCycleDefaults()
        let service = ModeCycleService()
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
        clearModeCycleDefaults()
        let service = ModeCycleService()
        #expect(service.modes.count == 4)
        // Remove every non-zero slot, repeatedly grabbing the new slot 1.
        while service.modes.count > 1 {
            let id = service.modes[1].id
            service.removeMode(id: id)
        }
        #expect(service.modes.count == ModeCycleService.minSlots)
        #expect(service.modes[0].type == .raw)
    }

    @Test("move: tauscht Positionen und step folgt")
    func moveReorders() {
        clearModeCycleDefaults()
        let service = ModeCycleService()
        let originalSecond = service.modes[1].id
        service.setStep(1)
        service.move(id: originalSecond, by: 1)
        #expect(service.modes[2].id == originalSecond)
        #expect(service.step == 2)
    }

    @Test("update mutates only the given slot")
    func updateMutates() {
        clearModeCycleDefaults()
        let service = ModeCycleService()
        let id = service.modes[1].id
        service.update(id: id) { $0.targetCode = "es" }
        #expect(service.modes[1].targetCode == "es")
        // Other slots unchanged
        #expect(service.modes[0].type == .raw)
    }

    @Test("setSourceLanguage: Translate-Slots mit target==newSource werden remapped")
    func setSourceLanguageReconcilesTargets() {
        clearModeCycleDefaults()
        let service = ModeCycleService()
        // Force a translate slot to target English.
        let id = service.modes[1].id
        service.update(id: id) { $0.targetCode = "en" }
        // Now switch source to English — the slot must remap to something else.
        service.setSourceLanguage("en")
        #expect(service.sourceLanguage.code == "en")
        #expect(service.modes[1].targetCode != "en")
    }

    @Test("Persistence: nach setSourceLanguage liest neuer Service den Wert")
    func sourcePersists() {
        clearModeCycleDefaults()
        let service = ModeCycleService()
        service.setSourceLanguage("es")
        let next = ModeCycleService()
        #expect(next.sourceLanguage.code == "es")
    }

    @Test("Persistence: nach update wird Reel persisted")
    func modesPersist() {
        clearModeCycleDefaults()
        let service = ModeCycleService()
        let id = service.modes[1].id
        service.update(id: id) { $0.targetCode = "it" }
        let next = ModeCycleService()
        #expect(next.modes[1].targetCode == "it")
    }

    @Test("Slot 0: Type kann nicht via update geändert werden")
    func slot0TypeLocked() {
        clearModeCycleDefaults()
        let service = ModeCycleService()
        let id = service.modes[0].id
        service.update(id: id) { $0.type = .email }
        #expect(service.modes[0].type == .raw)
    }

    @Test("Slot 0: removeMode wird ignoriert")
    func slot0RemoveBlocked() {
        clearModeCycleDefaults()
        let service = ModeCycleService()
        // Add a 5th slot so we're above minSlots and the min-clamp doesn't
        // mask the slot-0-lock behaviour.
        _ = service.addMode()
        let countBefore = service.modes.count
        let id = service.modes[0].id
        service.removeMode(id: id)
        #expect(service.modes.count == countBefore)
        #expect(service.modes[0].id == id)
    }

    @Test("Slot 0: move wird ignoriert")
    func slot0MoveBlocked() {
        clearModeCycleDefaults()
        let service = ModeCycleService()
        let id = service.modes[0].id
        service.move(id: id, by: 1)
        #expect(service.modes[0].id == id)
    }

    @Test("Slot 1: move(by: -1) verschiebt nicht in slot 0")
    func cannotDisplaceSlot0() {
        clearModeCycleDefaults()
        let service = ModeCycleService()
        let slot0 = service.modes[0].id
        let slot1 = service.modes[1].id
        service.move(id: slot1, by: -1)
        // Slot 0 stays put. Slot 1 still at index 1.
        #expect(service.modes[0].id == slot0)
        #expect(service.modes[1].id == slot1)
    }
}
