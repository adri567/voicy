import Foundation
import Observation

@Observable
final class OnboardingState {

    // Navigation
    var stepIndex: Int = 0
    var step: OnboardingStep { OnboardingStep.allCases[stepIndex] }

    // Permission state
    var micPermission: PermissionState = .idle
    var a11yPermission: PermissionState = .idle

    // Selections
    var modelID: String = "small"
    var modelDownload: Double = 0  // 0…100
    var modelDownloadError: String? = nil
    var brainID: String? = nil
    var brainDownload: Double = 0
    var languageCode: String = "en"

    private var modelDownloadTask: Task<Void, Never>? = nil

    // Preferences
    var clickSounds: Bool = true
    var openAtLogin: Bool = true

    // Practice
    var practicePhase: PracticePhase = .idle
    var practiceText: String = ""

    enum PracticePhase { case idle, recording, done }

    // Derived
    var pickedModel: OnboardingModel {
        OnboardingCatalog.models.first(where: { $0.id == modelID }) ?? OnboardingCatalog.models[1]
    }

    var pickedBrain: OnboardingBrain? {
        guard let id = brainID else { return nil }
        return OnboardingCatalog.brains.first(where: { $0.id == id })
    }

    var pickedLanguage: AppLanguage {
        LanguageCatalog.language(for: languageCode)
    }

    // MARK: - Model download

    /// Cancels any in-flight download and starts a new one for `model`.
    /// If the model is already installed, jumps straight to 100%.
    func selectAndDownloadModel(_ model: OnboardingModel) {
        modelDownloadTask?.cancel()
        modelID = model.id
        modelDownloadError = nil

        // Already on disk? Skip the download.
        if isModelInstalled(model) {
            modelDownload = 100
            return
        }

        modelDownload = 0
        modelDownloadTask = Task { @MainActor [weak self] in
            do {
                try await Self.install(model) { progress in
                    Task { @MainActor in
                        guard let self else { return }
                        // Ignore stale callbacks if the picker has moved on.
                        guard self.modelID == model.id else { return }
                        self.modelDownload = max(self.modelDownload, min(99, progress * 100))
                    }
                }
                if !Task.isCancelled, self?.modelID == model.id {
                    self?.modelDownload = 100
                }
            } catch is CancellationError {
                // Picker moved on — no-op.
            } catch {
                if self?.modelID == model.id {
                    self?.modelDownloadError = error.localizedDescription
                }
            }
        }
    }

    private func isModelInstalled(_ model: OnboardingModel) -> Bool {
        switch model.engine {
        case .whisper:  return DefaultTranscriptionService.isInstalled(modelID: model.realID)
        case .parakeet: return ParakeetTranscriptionService.isInstalled(version: model.realID)
        }
    }

    private static func install(_ model: OnboardingModel,
                                progress: @escaping @Sendable (Double) -> Void) async throws {
        switch model.engine {
        case .whisper:
            try await DefaultTranscriptionService.install(modelID: model.realID, progress: progress)
        case .parakeet:
            try await ParakeetTranscriptionService.install(version: model.realID, progress: progress)
        }
    }

    // MARK: - Navigation

    func next() {
        stepIndex = min(OnboardingStep.allCases.count - 1, stepIndex + 1)
    }

    func back() {
        stepIndex = max(0, stepIndex - 1)
    }

    func goTo(_ index: Int) {
        stepIndex = max(0, min(OnboardingStep.allCases.count - 1, index))
    }

    // MARK: - Init from preferences

    init() {
        let d = UserDefaults.standard
        micPermission = PermissionService.shared.currentMicrophoneState()
        a11yPermission = PermissionService.shared.currentAccessibilityState()
        if let lang = d.string(forKey: Preferences.Key.sourceLanguageCode) {
            languageCode = lang
        }
        if d.object(forKey: Preferences.Key.onboardingClickSounds) != nil {
            clickSounds = d.bool(forKey: Preferences.Key.onboardingClickSounds)
        }
        if d.object(forKey: Preferences.Key.onboardingOpenAtLogin) != nil {
            openAtLogin = d.bool(forKey: Preferences.Key.onboardingOpenAtLogin)
        }
        // If the default model is already on disk, show it as ready.
        if isModelInstalled(pickedModel) {
            modelDownload = 100
        }
    }

    // MARK: - Persist

    func persistFinalChoices() {
        let d = UserDefaults.standard
        d.set(true, forKey: Preferences.Key.onboardingCompleted)
        d.set(languageCode, forKey: Preferences.Key.sourceLanguageCode)
        d.set(clickSounds, forKey: Preferences.Key.onboardingClickSounds)
        d.set(openAtLogin, forKey: Preferences.Key.onboardingOpenAtLogin)

        // Engine + model id (so the next app launch picks them up)
        let m = pickedModel
        d.set(m.engine.rawValue, forKey: Preferences.Key.transcriptionEngine)
        switch m.engine {
        case .whisper:  d.set(m.realID, forKey: Preferences.Key.whisperModelID)
        case .parakeet: d.set(m.realID, forKey: Preferences.Key.parakeetVersion)
        }
    }
}
