import FactoryKit
import Foundation
import Testing
@testable import Voicy

/// Apple's built-in brain enters the onboarding picker without a download:
/// it carries the sentinel registry key, skips the MLX install flow, and
/// persists as the selected brain. Serialized — each test mutates shared
/// Factory services and `UserDefaults.standard`.
@MainActor
@Suite("OnboardingState — Apple built-in brain", .serialized)
struct OnboardingBrainTests {

    init() {
        Container.shared.permissionService.register {
            MainActor.assumeIsolated { MockPermissionService() }
        }
        UserDefaults.standard.removeObject(forKey: Preferences.Key.llmRegistryKey)
        UserDefaults.standard.removeObject(forKey: Preferences.Key.onboardingCompleted)
    }

    private var appleBrain: OnboardingBrain {
        OnboardingCatalog.brains.first(where: \.isBuiltIn)!
    }

    @Test("catalog lists Apple as a built-in brain with the sentinel key")
    func catalogHasAppleBuiltIn() {
        let apple = appleBrain
        #expect(apple.registryKey == BrainBackend.appleRegistryKey)
        #expect(apple.name == "Apple Intelligence")
        #expect(apple.tier == "Built-in")
        // It's the first card so it heads the list above the downloadable brains.
        #expect(OnboardingCatalog.brains.first?.id == apple.id)
    }

    @Test("selecting the built-in brain never enters a download state")
    func selectBuiltInSkipsDownload() {
        let state = OnboardingState()
        state.selectBrain(appleBrain)
        #expect(state.brainID == appleBrain.id)
        #expect(!state.brainState.isInProgress)
        // Ready exactly when Apple Intelligence can serve it on this machine.
        #expect(state.brainState.isReady == state.appleBrainAvailability.isAvailable)
    }

    @Test("built-in brain persists the Apple backend key on finish")
    func builtInPersistsBackendKey() {
        let state = OnboardingState()
        state.selectBrain(appleBrain)
        state.persistFinalChoices()
        #expect(
            UserDefaults.standard.string(forKey: Preferences.Key.llmRegistryKey)
                == BrainBackend.appleRegistryKey
        )
    }

    @Test("primary button skips the download wording for the built-in brain")
    func builtInPrimaryCopy() {
        let state = OnboardingState()
        state.selectBrain(appleBrain)
        #expect(state.brainPrimaryTitle == "Continue →")
        #expect(state.brainFooterNote == "Apple Intelligence · built-in, ready")
        #expect(!state.brainPrimaryDisabled)
    }

    @Test("recommendation prefers Apple when available, else Quill")
    func recommendationFollowsAvailability() {
        let state = OnboardingState()
        if state.appleBrainAvailability.isAvailable {
            #expect(state.recommendedBrainID == appleBrain.id)
        } else {
            #expect(state.recommendedBrainID == "gemma2b")
        }
    }
}
