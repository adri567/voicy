import FactoryKit
import Foundation
import Testing
@testable import Voicy

@MainActor
@Suite("OnboardingState — engine persistence", .serialized)
struct OnboardingStateTests {

    init() {
        Container.shared.permissionService.register {
            MainActor.assumeIsolated { MockPermissionService() }
        }
        let d = UserDefaults.standard
        d.removeObject(forKey: Preferences.Key.transcriptionEngine)
        d.removeObject(forKey: Preferences.Key.whisperModelID)
        d.removeObject(forKey: Preferences.Key.parakeetVersion)
    }

    private func model(_ id: String) -> OnboardingModel {
        OnboardingCatalog.models.first { $0.id == id }!
    }

    @Test("selectModel persists the engine choice")
    func selectPersistsEngine() {
        let state = OnboardingState()
        state.selectModel(model("parakeet"))
        #expect(TranscriptionEngine.current == .parakeet)
        #expect(UserDefaults.standard.string(forKey: Preferences.Key.parakeetVersion) == "v3")

        state.selectModel(model("small"))
        #expect(TranscriptionEngine.current == .whisper)
        #expect(UserDefaults.standard.string(forKey: Preferences.Key.whisperModelID) == "openai_whisper-small")
    }

    @Test("Continue on an already-ready default persists the engine (regression)")
    func continueOnReadyPersistsDefaultEngine() {
        // Reproduces the bug: the pre-selected default (parakeet) never went
        // through `selectModel`, so its engine was never persisted. Tapping
        // Continue while ready must commit it — otherwise practice resolves the
        // wrong engine and reports "no model installed".
        let state = OnboardingState()
        state.modelID = "parakeet"
        state.modelState = .ready
        state.modelPrimaryAction()
        #expect(TranscriptionEngine.current == .parakeet)
    }
}
