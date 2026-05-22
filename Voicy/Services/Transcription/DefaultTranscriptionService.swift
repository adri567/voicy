import FactoryKit
import Foundation
import OSLog
import WhisperKit

actor DefaultTranscriptionService: TranscriptionService {

    private var whisperKit: WhisperKit?
    /// In-flight load, shared by concurrent `loadModel()` callers so the model
    /// is loaded once instead of duplicated across overlapping calls.
    private var loadTask: Task<Void, Error>?
    private let recorder = AudioRecorder()
    private let audioDevices: any AudioInputDeviceService

    init() {
        self.audioDevices = Container.shared.audioInputDeviceService()
    }

    func loadModel() async throws {
        if whisperKit != nil { return }
        if let loadTask { return try await loadTask.value }
        let task = Task<Void, Error> { try await self.performLoad() }
        loadTask = task
        defer { loadTask = nil }
        try await task.value
    }

    private func performLoad() async throws {
        guard whisperKit == nil else { return }
        // Load-from-cache only. Downloads happen exclusively through
        // installModel(progress:), triggered from EngineView.
        guard isModelInstalled() else {
            Log.transcription.debug("WhisperKit: skipping auto-load — model not on disk")
            return
        }
        let model = Self.activeModelID
        Log.transcription.debug("WhisperKit: loading model from cache: \(model, privacy: .public)")
        whisperKit = try await WhisperKit(model: model)
        Log.transcription.debug("WhisperKit: model loaded successfully")
    }

    /// Currently selected Whisper model identifier (from UserDefaults).
    /// `_turbo` variants are inherently incompatible with WhisperKit 1.0.0
    /// (TextDecoderContextPrefill was removed); the EngineView UI only offers
    /// non-turbo IDs.
    nonisolated static var activeModelID: String {
        UserDefaults.standard.string(forKey: Preferences.Key.whisperModelID) ?? defaultModelID
    }

    nonisolated static let defaultModelID = "openai_whisper-small"

    func startRecording() async throws {
        guard whisperKit != nil else { throw TranscriptionError.modelNotLoaded }
        let deviceID = await audioDevices.resolveSelectedDeviceID()
        try recorder.start(inputDeviceID: deviceID)
    }

    func stopAndTranscribe(language: String) async throws -> TranscriptionResult {
        guard let kit = whisperKit else { throw TranscriptionError.noActiveRecording }

        let (samples, duration) = recorder.stop()

        Log.transcription.debug("WhisperKit: final transcription: \(samples.count) samples, language=\(language, privacy: .public)")
        guard !samples.isEmpty else {
            throw TranscriptionError.noAudioCaptured
        }

        let results = try await kit.transcribe(
            audioArray: samples,
            decodeOptions: DecodingOptions(language: language)
        )
        let text = Self.cleanWhisperOutput(
            results.compactMap(\.text).joined(separator: " ")
        )

        return TranscriptionResult(text: text, duration: duration)
    }

    func transcribeFile(
        at url: URL,
        language: String?
    ) async throws -> TranscriptionResult {
        if whisperKit == nil {
            try await loadModel()
        }
        guard let kit = whisperKit else { throw TranscriptionError.modelNotLoaded }

        let options = DecodingOptions(
            task: .transcribe,
            language: language
        )
        let results = try await kit.transcribe(audioPath: url.path, decodeOptions: options)

        let text = Self.cleanWhisperOutput(
            results.map(\.text).joined(separator: " ")
        )
        let segments: [Voicy.TranscriptionSegment] = results.flatMap { kitResult in
            kitResult.segments.map { kitSeg in
                Voicy.TranscriptionSegment(
                    start: TimeInterval(kitSeg.start),
                    end: TimeInterval(kitSeg.end),
                    text: Self.cleanWhisperOutput(kitSeg.text)
                )
            }
        }
        let duration = segments.last?.end ?? 0
        let detected = results.first?.language

        return TranscriptionResult(
            text: text,
            duration: duration,
            segments: segments,
            detectedLanguage: detected
        )
    }

    /// WhisperKit (especially Large-v3 / Distil variants) sometimes leaks its
    /// raw control tokens — `<|startoftranscript|>`, `<|de|>`, `<|transcribe|>`,
    /// `<|0.00|>` timestamps — into the decoded text. Strip every `<|...|>` and
    /// collapse the resulting whitespace.
    nonisolated static func cleanWhisperOutput(_ raw: String) -> String {
        let stripped = raw.replacing(/<\|[^|>]*\|>/, with: "")
        return stripped
            .replacing(/[ \t]+/, with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func cancelRecording() {
        _ = recorder.stop()
    }

    func currentAudioLevel() -> Float {
        recorder.currentLevel()
    }

    // MARK: - Download management

    nonisolated func isModelInstalled() -> Bool {
        ModelStorage.exists(at: ModelStorage.whisperKitPath(model: Self.activeModelID))
    }

    func installModel(progress: @escaping @Sendable (Double) -> Void) async throws {
        if isModelInstalled(), whisperKit != nil {
            progress(1.0)
            return
        }
        // WhisperKit() downloads via HubApi when the cache is empty, then loads
        // into RAM. No per-file progress hook in the public init — we report
        // 0 → 1 around the call.
        progress(0.05)
        let model = Self.activeModelID
        let kit = try await WhisperKit(model: model)
        whisperKit = kit
        progress(1.0)
    }

    func removeModel() async throws {
        whisperKit = nil
        try ModelStorage.remove(at: ModelStorage.whisperKitPath(model: Self.activeModelID))
        Log.transcription.debug("WhisperKit: model removed from disk")
    }

    // MARK: - Static API (any model, not just the active one)

    nonisolated static func isInstalled(modelID: String) -> Bool {
        ModelStorage.exists(at: ModelStorage.whisperKitPath(model: modelID))
    }

    /// Downloads the given model into the WhisperKit cache. Briefly instantiates
    /// `WhisperKit(model:)` to trigger the download, then discards the instance —
    /// the model lives on disk afterwards. RAM-loading of the *active* model
    /// happens later, on next app launch.
    nonisolated static func install(modelID: String, progress: @escaping @Sendable (Double) -> Void) async throws {
        progress(0.05)
        let kit = try await WhisperKit(model: modelID)
        _ = kit
        progress(1.0)
    }

    nonisolated static func remove(modelID: String) throws {
        try ModelStorage.remove(at: ModelStorage.whisperKitPath(model: modelID))
    }
}

nonisolated enum TranscriptionError: LocalizedError {
    case modelNotLoaded
    case noActiveRecording
    case audioSetupFailed
    case noAudioCaptured

    var errorDescription: String? {
        switch self {
        case .modelNotLoaded:    "Whisper model not loaded yet."
        case .noActiveRecording: "No active recording."
        case .audioSetupFailed:  "Couldn't read audio."
        case .noAudioCaptured:   "No audio samples captured — check microphone permission."
        }
    }
}
