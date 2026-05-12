import Foundation
import FluidAudio

final class ParakeetTranscriptionService: TranscriptionService {

    nonisolated(unsafe) private var asrManager: AsrManager?
    private let recorder = AudioRecorder()

    nonisolated init() {}

    nonisolated func loadModel() async throws {
        guard asrManager == nil else { return }
        print("[Parakeet] Loading FluidAudio model (v3, multilingual)…")
        let models = try await AsrModels.downloadAndLoad(version: .v3)
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
}
