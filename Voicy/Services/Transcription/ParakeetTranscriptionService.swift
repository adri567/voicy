import FactoryKit
import Foundation
import OSLog
import FluidAudio

actor ParakeetTranscriptionService: TranscriptionService {

    private var asrManager: AsrManager?
    /// In-flight load, shared by concurrent `loadModel()` callers so the model
    /// is loaded once instead of duplicated across overlapping calls.
    private var loadTask: Task<Void, Error>?
    private let recorder = AudioRecorder()
    private let audioDevices: any AudioInputDeviceService

    init() {
        self.audioDevices = Container.shared.audioInputDeviceService()
    }

    func loadModel() async throws {
        if asrManager != nil { return }
        if let loadTask { return try await loadTask.value }
        let task = Task<Void, Error> { try await self.performLoad() }
        loadTask = task
        defer { loadTask = nil }
        try await task.value
    }

    private func performLoad() async throws {
        guard asrManager == nil else { return }
        // Load-from-cache only. Downloads happen exclusively through
        // installModel(progress:), triggered from EngineView.
        guard isModelInstalled() else {
            Log.transcription.debug("Parakeet: skipping auto-load — model not on disk")
            return
        }
        let v = Self.asrVersion(for: Self.activeVersion)
        Log.transcription.debug("Parakeet: loading FluidAudio model from cache (\(Self.activeVersion, privacy: .public))")
        let models = try await AsrModels.loadFromCache(version: v)
        let manager = AsrManager(config: .default)
        try await manager.loadModels(models)
        asrManager = manager
        Log.transcription.debug("Parakeet: model ready (Neural Engine)")
    }

    /// Currently selected Parakeet version identifier (from UserDefaults).
    /// Falls back to the default if the stored value is not in the supported
    /// library (e.g. `tdtCtc110m` was removed because of a FluidAudio bug that
    /// re-downloads on every launch).
    nonisolated static var activeVersion: String {
        let stored = UserDefaults.standard.string(forKey: Preferences.Key.parakeetVersion) ?? defaultVersion
        return supportedVersions.contains(stored) ? stored : defaultVersion
    }

    nonisolated static let defaultVersion = "v3"
    nonisolated static let supportedVersions = ["v3"]

    func startRecording() async throws {
        guard asrManager != nil else { throw TranscriptionError.modelNotLoaded }
        let deviceID = await audioDevices.resolveSelectedDeviceID()
        try recorder.start(inputDeviceID: deviceID)
    }

    func stopAndTranscribe(language: String) async throws -> TranscriptionResult {
        guard let manager = asrManager else { throw TranscriptionError.noActiveRecording }

        let (samples, duration) = recorder.stop()
        guard !samples.isEmpty else { throw TranscriptionError.noAudioCaptured }

        let lang: Language = Language(rawValue: language) ?? .german
        Log.transcription.debug("Parakeet: transcribing \(samples.count) samples, language=\(language, privacy: .public)")
        var decoderState = TdtDecoderState.make()
        let result = try await manager.transcribe(samples, decoderState: &decoderState, language: lang)
        let text = result.text.trimmingCharacters(in: .whitespaces)
        Log.transcription.debug("Parakeet: done: \"\(text)\"")
        return TranscriptionResult(text: text, duration: duration)
    }

    func transcribeFile(
        at url: URL,
        language: String?
    ) async throws -> TranscriptionResult {
        if asrManager == nil {
            try await loadModel()
        }
        guard let manager = asrManager else { throw TranscriptionError.modelNotLoaded }

        let lang: Language = language.flatMap { Language(rawValue: $0) } ?? .german
        var decoderState = TdtDecoderState.make()
        let result = try await manager.transcribe(url, decoderState: &decoderState, language: lang)
        let text = result.text.trimmingCharacters(in: .whitespaces)

        let segments = Self.collapseTokensIntoSegments(result.tokenTimings ?? [], fallbackText: text)
        let duration = result.duration > 0 ? result.duration : (segments.last?.end ?? 0)

        return TranscriptionResult(
            text: text,
            duration: duration,
            segments: segments,
            detectedLanguage: lang.rawValue
        )
    }

    /// Group raw token timings into readable display segments. Parakeet returns
    /// per-token timings without sentence boundaries, so we approximate them:
    ///   - split when the last token in the bucket ends with sentence-ending
    ///     punctuation (`.`, `!`, `?`) — natural sentence break
    ///   - split when the gap to the next token exceeds `pauseGap` — the speaker
    ///     drew breath
    ///   - force-split when the bucket has grown beyond `maxBucketDuration` —
    ///     keeps very long monotonic stretches from becoming a single block
    /// A short `minBucketDuration` floor prevents hyper-fragmentation when the
    /// speaker is using lots of micro-pauses or every token has a comma.
    nonisolated private static func collapseTokensIntoSegments(
        _ tokens: [TokenTiming],
        fallbackText: String
    ) -> [Voicy.TranscriptionSegment] {
        guard let first = tokens.first else {
            return [Voicy.TranscriptionSegment(start: 0, end: 0, text: fallbackText)]
        }

        let maxBucketDuration: TimeInterval = 25
        let minBucketDuration: TimeInterval = 3
        let pauseGap: TimeInterval = 0.8
        let sentenceEnders: Set<Character> = [".", "!", "?"]

        var segments: [Voicy.TranscriptionSegment] = []
        var bucketTokens: [TokenTiming] = []
        var bucketStart: TimeInterval = first.startTime

        for (index, token) in tokens.enumerated() {
            bucketTokens.append(token)

            guard index + 1 < tokens.count else { continue }
            let next = tokens[index + 1]
            let bucketDuration = next.startTime - bucketStart
            let pause = next.startTime - token.endTime
            let trimmed = token.token.trimmingCharacters(in: .whitespacesAndNewlines)
            let endsSentence = trimmed.last.map { sentenceEnders.contains($0) } ?? false

            let shouldSplit =
                bucketDuration >= maxBucketDuration ||
                (bucketDuration >= minBucketDuration && (endsSentence || pause >= pauseGap))

            if shouldSplit {
                segments.append(Self.bucketSegment(bucketTokens))
                bucketTokens = []
                bucketStart = next.startTime
            }
        }

        if !bucketTokens.isEmpty {
            segments.append(Self.bucketSegment(bucketTokens))
        }

        return segments.isEmpty
            ? [Voicy.TranscriptionSegment(start: first.startTime, end: tokens.last?.endTime ?? 0, text: fallbackText)]
            : segments
    }

    nonisolated private static func bucketSegment(_ tokens: [TokenTiming]) -> Voicy.TranscriptionSegment {
        let text = tokens.map(\.token).joined().trimmingCharacters(in: .whitespaces)
        let start = tokens.first?.startTime ?? 0
        let end = tokens.last?.endTime ?? start
        return Voicy.TranscriptionSegment(start: start, end: end, text: text)
    }

    func cancelRecording() {
        _ = recorder.stop()
    }

    func currentAudioLevel() -> Float {
        recorder.currentLevel()
    }

    // MARK: - Download management

    nonisolated func isModelInstalled() -> Bool {
        Self.isInstalled(version: Self.activeVersion)
    }

    func installModel(progress: @escaping @Sendable (Double) -> Void) async throws {
        let v = Self.asrVersion(for: Self.activeVersion)
        if isModelInstalled(), asrManager != nil {
            progress(1.0)
            return
        }
        Log.transcription.debug("Parakeet: installing model with progress")
        let models = try await AsrModels.downloadAndLoad(version: v) { p in
            progress(p.fractionCompleted)
        }
        let manager = AsrManager(config: .default)
        try await manager.loadModels(models)
        asrManager = manager
        progress(1.0)
        Log.transcription.debug("Parakeet: model installed")
    }

    func removeModel() async throws {
        asrManager = nil
        try Self.remove(version: Self.activeVersion)
        Log.transcription.debug("Parakeet: model removed from disk")
    }

    // MARK: - Static API (any model, not just the active one)

    nonisolated static func isInstalled(version: String) -> Bool {
        let v = asrVersion(for: version)
        return AsrModels.modelsExist(at: AsrModels.defaultCacheDirectory(for: v), version: v)
    }

    /// Downloads the given Parakeet version to disk without loading into RAM.
    nonisolated static func install(version: String, progress: @escaping @Sendable (Double) -> Void) async throws {
        let v = asrVersion(for: version)
        _ = try await AsrModels.download(version: v) { p in
            progress(p.fractionCompleted)
        }
        // No final progress(1.0) — the ViewModel sets the terminal state after
        // `install` returns. A trailing 1.0 here would race with that and can
        // overwrite `.installed` with `.downloading(1.0)` in the UI.
    }

    nonisolated static func remove(version: String) throws {
        let v = asrVersion(for: version)
        let dir = AsrModels.defaultCacheDirectory(for: v)
        try ModelStorage.remove(at: dir)
    }

    nonisolated static func asrVersion(for key: String) -> AsrModelVersion {
        switch key {
        case "v3":         return .v3
        case "v2":         return .v2
        case "tdtCtc110m": return .tdtCtc110m
        default:           return .v3
        }
    }
}
