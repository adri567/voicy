import Foundation
import FluidAudio

actor ParakeetTranscriptionService: TranscriptionService {

    private var asrManager: AsrManager?
    private let recorder = AudioRecorder()

    init() {}

    func loadModel() async throws {
        guard asrManager == nil else { return }
        // Load-from-cache only. Downloads happen exclusively through
        // installModel(progress:), triggered from EngineView.
        guard isModelInstalled() else {
            print("[Parakeet] Skipping auto-load — model not on disk")
            return
        }
        let v = Self.asrVersion(for: Self.activeVersion)
        print("[Parakeet] Loading FluidAudio model from cache (\(Self.activeVersion))…")
        let models = try await AsrModels.loadFromCache(version: v)
        let manager = AsrManager(config: .default)
        try await manager.loadModels(models)
        asrManager = manager
        print("[Parakeet] Model ready (Neural Engine)")
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
        try recorder.start()
    }

    func stopAndTranscribe() async throws -> TranscriptionResult {
        guard let manager = asrManager else { throw TranscriptionError.noActiveRecording }

        let (samples, duration) = recorder.stop()
        guard !samples.isEmpty else { throw TranscriptionError.noAudioCaptured }

        print("[Parakeet] Transcribing \(samples.count) samples (\(String(format: "%.1f", Double(samples.count) / 16000.0))s)…")
        var decoderState = TdtDecoderState.make()
        let result = try await manager.transcribe(samples, decoderState: &decoderState, language: .german)
        let text = result.text.trimmingCharacters(in: .whitespaces)
        print("[Parakeet] Done: \"\(text)\"")
        return TranscriptionResult(text: text, duration: duration)
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
        print("[Parakeet] Installing model with progress…")
        let models = try await AsrModels.downloadAndLoad(version: v) { p in
            progress(p.fractionCompleted)
        }
        let manager = AsrManager(config: .default)
        try await manager.loadModels(models)
        asrManager = manager
        progress(1.0)
        print("[Parakeet] Model installed")
    }

    func removeModel() async throws {
        asrManager = nil
        try Self.remove(version: Self.activeVersion)
        print("[Parakeet] Model removed from disk")
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
