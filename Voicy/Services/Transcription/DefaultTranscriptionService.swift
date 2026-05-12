import Foundation
import WhisperKit

final class DefaultTranscriptionService: TranscriptionService {

    nonisolated(unsafe) private var whisperKit: WhisperKit?
    private let recorder = AudioRecorder()

    nonisolated init() {}

    nonisolated func loadModel() async throws {
        guard whisperKit == nil else { return }
        let model = await Self.modelName
        print("[WhisperKit] Loading model: \(model)")
        whisperKit = try await WhisperKit(model: model)
        print("[WhisperKit] Model loaded successfully")
    }

    // WhisperKit 1.0.0 removed TextDecoderContextPrefill, making all _turbo variants
    // incompatible. Use small for now — fast enough with LLM cleanup in the pipeline.
    // Revisit when WhisperKit adds a new turbo path without TextDecoderContextPrefill.
    private static let modelName = "openai_whisper-small"

    nonisolated func startRecording() async throws {
        guard whisperKit != nil else { throw TranscriptionError.modelNotLoaded }
        try recorder.start()
    }

    nonisolated func stopAndTranscribe() async throws -> TranscriptionResult {
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
        let text = results.compactMap(\.text).joined(separator: " ").trimmingCharacters(in: .whitespaces)

        return TranscriptionResult(text: text, duration: duration)
    }

    nonisolated func currentAudioLevel() -> Float {
        recorder.currentLevel()
    }
}

enum TranscriptionError: LocalizedError {
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
