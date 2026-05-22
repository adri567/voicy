import FactoryKit
import Foundation
import Observation

@Observable
final class OnboardingState {

    @ObservationIgnored @Injected(\.permissionService) private var permissions

    // Navigation
    var stepIndex: Int = 0
    var step: OnboardingStep { OnboardingStep.allCases[stepIndex] }

    // Permission state
    var micPermission: PermissionState = .idle
    var a11yPermission: PermissionState = .idle
    var fnKeyState: PermissionState = .idle

    // Selections
    var modelID: String = "parakeet"
    var modelDownload: Double = 0  // 0…100
    var modelDownloadError: String? = nil
    var brainID: String? = nil
    var brainDownload: Double = 0
    var brainDownloadError: String? = nil
    var languageCode: String = "en"

    private var modelDownloadTask: Task<Void, Never>? = nil
    private var brainDownloadTask: Task<Void, Never>? = nil

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
    /// If the model is already installed, jumps straight to 100% and warms
    /// the singleton service so the practice screen has it loaded.
    func selectAndDownloadModel(_ model: OnboardingModel) {
        modelDownloadTask?.cancel()
        modelID = model.id
        modelDownloadError = nil

        // Persist the engine choice up-front so `TranscriptionEngine.current`
        // already reflects this model before the practice screen wires up
        // recording. Without this the RecordingViewModel resolves the
        // wrong engine and falls back to the previous (or default) one.
        Self.persistEngineChoice(model)

        // Already on disk? Skip the download, but still warm the singleton.
        if isModelInstalled(model) {
            modelDownload = 100
            modelDownloadTask = Task { @MainActor [weak self] in
                try? await Self.loadAfterInstall(model)
                _ = self
            }
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
                guard !Task.isCancelled, self?.modelID == model.id else { return }
                // Load the just-downloaded files into the app's singleton
                // service so the user doesn't pay the load cost on their
                // first Fn-press in the practice screen.
                try? await Self.loadAfterInstall(model)
                self?.modelDownload = 100
            } catch is CancellationError {
                // Picker moved on — no-op.
            } catch {
                if self?.modelID == model.id {
                    self?.modelDownloadError = error.localizedDescription
                }
            }
        }
    }

    private static func persistEngineChoice(_ model: OnboardingModel) {
        let d = UserDefaults.standard
        d.set(model.engine.rawValue, forKey: Preferences.Key.transcriptionEngine)
        switch model.engine {
        case .whisper:  d.set(model.realID, forKey: Preferences.Key.whisperModelID)
        case .parakeet: d.set(model.realID, forKey: Preferences.Key.parakeetVersion)
        }
    }

    /// Warms the app's singleton service for `model.engine` — pulls the
    /// just-downloaded files off disk into RAM so the next `startRecording`
    /// is immediate. Static install builds a throwaway instance; the singleton
    /// the ViewModel uses has its own cache that needs to be primed.
    private static func loadAfterInstall(_ model: OnboardingModel) async throws {
        switch model.engine {
        case .whisper:
            try await Container.shared.whisperTranscriptionService().loadModel()
        case .parakeet:
            try await Container.shared.parakeetTranscriptionService().loadModel()
        }
    }

    private func isModelInstalled(_ model: OnboardingModel) -> Bool {
        switch model.engine {
        case .whisper:  return DefaultTranscriptionService.isInstalled(modelID: model.realID)
        case .parakeet: return ParakeetTranscriptionService.isInstalled(version: model.realID)
        }
    }

    // MARK: - Brain download

    /// Cancels any in-flight brain download and starts a new one for `brain`.
    /// If the brain is already installed, jumps straight to 100%.
    func selectAndDownloadBrain(_ brain: OnboardingBrain) {
        brainDownloadTask?.cancel()
        brainID = brain.id
        brainDownloadError = nil

        if MLXTextCorrectionService.isInstalled(registryKey: brain.registryKey) {
            brainDownload = 100
            return
        }

        brainDownload = 0
        brainDownloadTask = Task { @MainActor [weak self] in
            do {
                try await MLXTextCorrectionService.install(registryKey: brain.registryKey) { fraction in
                    Task { @MainActor in
                        guard let self else { return }
                        guard self.brainID == brain.id else { return }
                        self.brainDownload = max(self.brainDownload, min(99, fraction * 100))
                    }
                }
                if !Task.isCancelled, self?.brainID == brain.id {
                    self?.brainDownload = 100
                }
            } catch is CancellationError {
                // Picker moved on — no-op.
            } catch {
                if self?.brainID == brain.id {
                    self?.brainDownloadError = error.localizedDescription
                }
            }
        }
    }

    /// Clears any picked brain, cancels its download, resets progress.
    func clearBrainSelection() {
        brainDownloadTask?.cancel()
        brainID = nil
        brainDownload = 0
        brainDownloadError = nil
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

    // MARK: - Permissions

    /// Re-reads all three permission states from the system. Called when the
    /// onboarding window appears so a change made in System Settings shows up.
    func refreshPermissions() {
        micPermission = permissions.currentMicrophoneState()
        a11yPermission = permissions.currentAccessibilityState()
        fnKeyState = permissions.currentFnKeyState()
    }

    /// Mic polling only ever upgrades to `.granted`; it never downgrades to
    /// `.denied` from a stale TCC read (see the init comment for why).
    func syncMicrophoneFromSystem() {
        if permissions.currentMicrophoneState() == .granted, micPermission != .granted {
            micPermission = .granted
        }
    }

    func requestMicrophone() async {
        micPermission = await permissions.requestMicrophone()
    }

    func denyMicrophone() {
        micPermission = .denied
    }

    func openMicrophonePane() {
        permissions.openMicrophonePane()
    }

    func syncAccessibilityFromSystem() {
        let cur = permissions.currentAccessibilityState()
        if cur != a11yPermission { a11yPermission = cur }
    }

    func requestAccessibility() {
        permissions.requestAccessibility()
    }

    func syncFnKeyFromSystem() {
        let cur = permissions.currentFnKeyState()
        if cur != fnKeyState { fnKeyState = cur }
    }

    func disableFnKey() {
        permissions.disableFnKey()
    }

    func openKeyboardPane() {
        permissions.openKeyboardPane()
    }

    // MARK: - Init from preferences

    init() {
        let d = UserDefaults.standard
        // Mic: read lazily. We only seed `.granted` if TCC already says so
        // (returning user). For a fresh user we stay `.idle` so the very
        // first Allow-click can trigger the native system prompt instead of
        // landing on a stale `.denied` from an earlier session that would
        // suppress the prompt entirely.
        let micNow = permissions.currentMicrophoneState()
        micPermission = (micNow == .granted) ? .granted : .idle
        a11yPermission = permissions.currentAccessibilityState()
        fnKeyState = permissions.currentFnKeyState()
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
        // If a previously-selected brain is already on disk, mirror that.
        if let brain = pickedBrain,
           MLXTextCorrectionService.isInstalled(registryKey: brain.registryKey) {
            brainDownload = 100
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

        // Brain (optional). Only persist if the user actually picked one.
        if let brain = pickedBrain {
            d.set(brain.registryKey, forKey: Preferences.Key.llmRegistryKey)
        }
    }
}
