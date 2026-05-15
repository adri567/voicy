import Foundation
import Observation

enum OnboardingStep: Int, CaseIterable, Identifiable {
    case welcome
    case microphone
    case accessibility
    case model
    case brain
    case language
    case practice
    case allSet

    var id: Int { rawValue }

    var chapter: String { String(format: "%02d", rawValue) }

    var title: String {
        switch self {
        case .welcome:       return "Welcome"
        case .microphone:    return "Microphone"
        case .accessibility: return "Accessibility"
        case .model:         return "Voice model"
        case .brain:         return "The brain"
        case .language:      return "Language"
        case .practice:      return "First dictation"
        case .allSet:        return "All set"
        }
    }

    var shortLabel: String {
        switch self {
        case .welcome:       return "Welcome"
        case .microphone:    return "Microphone"
        case .accessibility: return "Access"
        case .model:         return "Voice"
        case .brain:         return "Brain"
        case .language:      return "Language"
        case .practice:      return "First word"
        case .allSet:        return "Ready"
        }
    }
}

// Voice model catalogue — mirrors the design bundle MODELS list.
struct OnboardingModel: Identifiable, Hashable {
    let id: String
    let family: String
    let label: String
    let displaySize: String
    let wer: String
    let speed: String
    let body: String
    let recommended: Bool
    let engine: TranscriptionEngine
    /// Real identifier used by the engine: WhisperKit model name or Parakeet version.
    let realID: String
}

enum OnboardingCatalog {
    static let models: [OnboardingModel] = [
        .init(id: "tiny",     family: "Whisper",  label: "Tiny",
              displaySize: "39 MB",
              wer: "12.4%", speed: "Realtime · 8×",
              body: "Drafts, chat, casual notes. Stumbles on names and accents.",
              recommended: false,
              engine: .whisper, realID: "openai_whisper-tiny"),
        .init(id: "small",    family: "Whisper",  label: "Small",
              displaySize: "244 MB",
              wer: "7.1%", speed: "Realtime · 4×",
              body: "The sweet spot. Handles German + English mid-sentence switches.",
              recommended: true,
              engine: .whisper, realID: "openai_whisper-small"),
        .init(id: "large",    family: "Whisper",  label: "Large",
              displaySize: "947 MB",
              wer: "4.3%", speed: "Realtime · 1.2×",
              body: "Long-form editorial, jargon, multilingual. Needs Apple Silicon.",
              recommended: false,
              engine: .whisper, realID: "openai_whisper-large-v3_947MB"),
        .init(id: "parakeet", family: "Parakeet", label: "TDT v3",
              displaySize: "1.1 GB",
              wer: "5.2%", speed: "Realtime · 10×",
              body: "NVIDIA's blistering ASR — fastest of the lot, English-first, surprisingly accurate.",
              recommended: false,
              engine: .parakeet, realID: "v3"),
    ]
}

struct OnboardingBrain: Identifiable, Hashable {
    let id: String
    let name: String
    let variant: String
    let family: String
    let size: String
    let context: String
    let speed: String
    let quality: Int
    let body: String
    let recommended: Bool
}

extension OnboardingCatalog {
    static let brains: [OnboardingBrain] = [
        .init(id: "llama8b", name: "Llama 3.1", variant: "8B",
              family: "Meta · open weights", size: "4.9 GB", context: "128k",
              speed: "Fast", quality: 86,
              body: "A solid local workhorse. Translates well, cleans up rambling, expands snippets.",
              recommended: true),
        .init(id: "mistral7b", name: "Mistral", variant: "7B",
              family: "Mistral · open", size: "4.1 GB", context: "32k",
              speed: "Realtime", quality: 82,
              body: "Lean and very fast. Excellent for short tasks like translation and punctuation fixes.",
              recommended: false),
        .init(id: "qwen14b", name: "Qwen 2.5", variant: "14B",
              family: "Alibaba · open", size: "8.7 GB", context: "128k",
              speed: "Medium", quality: 91,
              body: "Heavier and more thoughtful. Multilingual translation is its real strength.",
              recommended: false),
        .init(id: "phi35", name: "Phi-3.5", variant: "Mini",
              family: "Microsoft · open", size: "2.3 GB", context: "128k",
              speed: "Realtime", quality: 78,
              body: "A 3.8B model that punches above its weight. Wonderful when battery matters.",
              recommended: false),
    ]
}

@MainActor
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
