import Foundation
import WhisperKit

actor DefaultTranscriptionService: TranscriptionService {

    private var whisperKit: WhisperKit?
    private let recorder = AudioRecorder()

    init() {}

    func loadModel() async throws {
        guard whisperKit == nil else { return }
        // Load-from-cache only. Downloads happen exclusively through
        // installModel(progress:), triggered from EngineView.
        guard isModelInstalled() else {
            print("[WhisperKit] Skipping auto-load — model not on disk")
            return
        }
        let model = Self.activeModelID
        print("[WhisperKit] Loading model from cache: \(model)")
        whisperKit = try await WhisperKit(model: model)
        print("[WhisperKit] Model loaded successfully")
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
        try recorder.start()
    }

    func stopAndTranscribe() async throws -> TranscriptionResult {
        guard let kit = whisperKit else { throw TranscriptionError.noActiveRecording }

        let (samples, duration) = recorder.stop()

        print("[WhisperKit] Final transcription: \(samples.count) samples (\(String(format: "%.1f", Double(samples.count) / 16000.0))s)")
        guard !samples.isEmpty else {
            throw TranscriptionError.noAudioCaptured
        }

        let results = try await kit.transcribe(
            audioArray: samples,
            decodeOptions: DecodingOptions(language: "de")
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
    nonisolated private static func cleanWhisperOutput(_ raw: String) -> String {
        let stripped = raw.replacing(/<\|[^|>]*\|>/, with: "")
        return stripped
            .replacing(/[ \t]+/, with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
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
        print("[WhisperKit] Model removed from disk")
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
        case .modelNotLoaded:    "Whisper-Modell ist noch nicht geladen."
        case .noActiveRecording: "Keine aktive Aufnahme vorhanden."
        case .audioSetupFailed:  "Audio konnte nicht gelesen werden."
        case .noAudioCaptured:   "Keine Audio-Samples aufgenommen — Mikrofon-Berechtigung prüfen."
        }
    }
}
