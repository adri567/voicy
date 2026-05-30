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
    var modelState: DownloadUIState = .idle
    var brainID: String? = nil
    var brainState: DownloadUIState = .idle
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

    // MARK: - Footer copy (model)

    /// Title for the model step's primary button.
    var modelPrimaryTitle: String {
        switch modelState {
        case .ready:               return "Continue →"
        case .inProgress(let p):   return "Downloading \(pickedModel.name) — \(p.shortLabel)"
        case .idle, .failed:       return "Download \(pickedModel.name) (\(pickedModel.displaySize))"
        }
    }

    var modelPrimaryDisabled: Bool { modelState.isInProgress }

    /// Sub-label under the model step's primary button.
    var modelFooterNote: String {
        switch modelState {
        case .failed(let message): return "Error: \(message)"
        case .ready:               return "\(pickedModel.name) ready"
        case .inProgress(let p):
            if let fraction = p.fraction {
                return "\(Int(fraction * 100))% of \(pickedModel.displaySize)"
            }
            return p.shortLabel
        case .idle:
            return "Click to fetch \(pickedModel.name)"
        }
    }

    /// Primary button action for the model step: continue once ready,
    /// otherwise start the download for the selected model.
    func modelPrimaryAction() {
        if modelState.isReady {
            // The picked model may be the pre-selected default that never went
            // through `selectModel` (e.g. already on disk at first launch), so
            // its engine choice isn't persisted yet. Commit it before leaving —
            // otherwise the practice screen resolves the wrong engine.
            Self.persistEngineChoice(pickedModel)
            next()
        } else {
            downloadSelectedModel()
        }
    }

    // MARK: - Footer copy (brain)

    var brainPrimaryTitle: String {
        guard let brain = pickedBrain else { return "Continue without a brain →" }
        switch brainState {
        case .ready:             return "Continue →"
        case .inProgress(let p): return "Downloading… \(p.shortLabel)"
        case .idle, .failed:     return "Download \(brain.name) (\(brain.size))"
        }
    }

    var brainPrimaryDisabled: Bool {
        pickedBrain != nil && brainState.isInProgress
    }

    /// Primary button action for the brain step: continue when nothing is
    /// picked or it's ready, otherwise start the download for the picked brain.
    func brainPrimaryAction() {
        guard pickedBrain != nil else { next(); return }
        if brainState.isReady { next() } else { downloadSelectedBrain() }
    }

    var brainFooterNote: String {
        if let message = brainState.errorText { return "Error: \(message)" }
        guard let brain = pickedBrain else {
            return "You can install one later in Settings → Brain"
        }
        switch brainState {
        case .inProgress(let p): return "\(brain.name) · \(p.shortLabel)"
        case .ready:             return "\(brain.name) · ready"
        case .idle, .failed:     return "\(brain.name)"
        }
    }

    // MARK: - Model selection & download

    /// Selects a model without downloading anything. Picks the radio, persists
    /// the engine choice, and reflects whether it's already on disk. The actual
    /// download only happens later via `downloadSelectedModel()` (the footer
    /// button) — selecting a card must never start a download.
    func selectModel(_ model: OnboardingModel) {
        modelDownloadTask?.cancel()
        modelID = model.id

        // Persist the engine choice up-front so `TranscriptionEngine.current`
        // already reflects this model before the practice screen wires up
        // recording. Without this the RecordingViewModel resolves the
        // wrong engine and falls back to the previous (or default) one.
        Self.persistEngineChoice(model)

        // Already on disk? Ready immediately, warm the singleton in the
        // background (RAM load of existing files — not a download).
        if isModelInstalled(model) {
            modelState = .ready
            modelDownloadTask = Task { @MainActor [weak self] in
                try? await Self.loadAfterInstall(model)
                _ = self
            }
        } else {
            modelState = .idle
        }
    }

    /// Downloads the currently selected model. Triggered explicitly by the
    /// footer button — no-op if it's already downloading or ready.
    func downloadSelectedModel() {
        let model = pickedModel
        guard !modelState.isReady, !modelState.isInProgress else { return }
        // Downloading commits this model as the active engine — persist now so
        // the practice screen (and the app afterwards) resolves it correctly,
        // even if the card was the pre-selected default and never tapped.
        Self.persistEngineChoice(model)
        modelDownloadTask?.cancel()
        modelState = .inProgress(.preparing)
        modelDownloadTask = Task { @MainActor [weak self] in
            do {
                try await Self.install(model) { phase in
                    Task { @MainActor in
                        guard let self, self.modelID == model.id else { return }
                        self.modelState = self.modelState.advanced(to: phase)
                    }
                }
                guard !Task.isCancelled, self?.modelID == model.id else { return }
                // Load the just-downloaded files into the app's singleton
                // service so the user doesn't pay the load cost on their first
                // Fn-press in the practice screen — the onboarding "finalizing".
                self?.modelState = .inProgress(.finalizing)
                try? await Self.loadAfterInstall(model)
                guard let self, self.modelID == model.id else { return }
                self.modelState = .ready
            } catch is CancellationError {
                // Picker moved on — no-op.
            } catch {
                if self?.modelID == model.id {
                    self?.modelState = .failed(error.localizedDescription)
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

    // MARK: - Brain selection & download

    /// Selects a brain without downloading anything. Picks the radio and
    /// reflects whether it's already on disk. The download only happens later
    /// via `downloadSelectedBrain()` (the footer button).
    func selectBrain(_ brain: OnboardingBrain) {
        brainDownloadTask?.cancel()
        brainID = brain.id
        brainState = MLXTextCorrectionService.isInstalled(registryKey: brain.registryKey)
            ? .ready
            : .idle
    }

    /// Downloads the currently selected brain. Triggered explicitly by the
    /// footer button — no-op if it's already downloading or ready.
    func downloadSelectedBrain() {
        guard let brain = pickedBrain else { return }
        guard !brainState.isReady, !brainState.isInProgress else { return }
        brainDownloadTask?.cancel()
        brainState = .inProgress(.preparing)
        brainDownloadTask = Task { @MainActor [weak self] in
            do {
                try await MLXTextCorrectionService.install(registryKey: brain.registryKey) { phase in
                    Task { @MainActor in
                        guard let self, self.brainID == brain.id else { return }
                        self.brainState = self.brainState.advanced(to: phase)
                    }
                }
                if !Task.isCancelled, self?.brainID == brain.id {
                    self?.brainState = .ready
                }
            } catch is CancellationError {
                // Picker moved on — no-op.
            } catch {
                if self?.brainID == brain.id {
                    self?.brainState = .failed(error.localizedDescription)
                }
            }
        }
    }

    /// Clears any picked brain, cancels its download, resets progress.
    func clearBrainSelection() {
        brainDownloadTask?.cancel()
        brainID = nil
        brainState = .idle
    }

    private static func install(_ model: OnboardingModel,
                                progress: @escaping @Sendable (DownloadPhase) -> Void) async throws {
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
            modelState = .ready
        }
        // If a previously-selected brain is already on disk, mirror that.
        if let brain = pickedBrain,
           MLXTextCorrectionService.isInstalled(registryKey: brain.registryKey) {
            brainState = .ready
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
