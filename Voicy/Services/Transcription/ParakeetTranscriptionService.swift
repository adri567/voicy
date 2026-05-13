import Foundation
import FluidAudio

final class ParakeetTranscriptionService: TranscriptionService {

    nonisolated(unsafe) private var asrManager: AsrManager?
    private let recorder = AudioRecorder()

    nonisolated init() {}

    nonisolated func loadModel() async throws {
        guard asrManager == nil else { return }
        // Load-from-cache only. Downloads happen exclusively through
        // installModel(progress:), triggered from EngineView.
        guard isModelInstalled() else {
            print("[Parakeet] Skipping auto-load — model not on disk")
            return
        }
        print("[Parakeet] Loading FluidAudio model from cache (v3, multilingual)…")
        let models = try await AsrModels.loadFromCache(version: .v3)
        let manager = AsrManager(config: .default)
        try await manager.loadModels(models)
        asrManager = manager
        print("[Parakeet] Model ready (Neural Engine)")
    }

    nonisolated func startRecording() async throws {
        guard asrManager != nil else { throw TranscriptionError.modelNotLoaded }
        try recorder.start()
    }

    nonisolated func stopAndTranscribe() async throws -> TranscriptionResult {
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

    nonisolated func currentAudioLevel() -> Float {
        recorder.currentLevel()
    }

    // MARK: - Download management

    nonisolated func isModelInstalled() -> Bool {
        let dir = AsrModels.defaultCacheDirectory(for: .v3)
        return AsrModels.modelsExist(at: dir, version: .v3)
    }

    nonisolated func installModel(progress: @escaping @Sendable (Double) -> Void) async throws {
        if isModelInstalled(), asrManager != nil {
            progress(1.0)
            return
        }
        print("[Parakeet] Installing model with progress…")
        let models = try await AsrModels.downloadAndLoad(version: .v3) { p in
            progress(p.fractionCompleted)
        }
        let manager = AsrManager(config: .default)
        try await manager.loadModels(models)
        asrManager = manager
        progress(1.0)
        print("[Parakeet] Model installed")
    }

    nonisolated func removeModel() async throws {
        asrManager = nil
        let dir = AsrModels.defaultCacheDirectory(for: .v3)
        try ModelStorage.remove(at: dir)
        print("[Parakeet] Model removed from disk")
    }
}
