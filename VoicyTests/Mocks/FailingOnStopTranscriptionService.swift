import Foundation
@testable import Voicy

final class FailingOnStopTranscriptionService: TranscriptionService {
    nonisolated init() {}
    nonisolated func loadModel() async throws {}
    nonisolated func startRecording() async throws {}
    nonisolated func stopAndTranscribe(language: String) async throws -> TranscriptionResult {
        throw TestError.transcriptionFailed
    }
    nonisolated func cancelRecording() async {}
    nonisolated func currentAudioLevel() async -> Float { 0 }
    nonisolated func transcribeFile(at url: URL, language: String?) async throws -> TranscriptionResult {
        throw TestError.transcriptionFailed
    }
    nonisolated func isModelInstalled() -> Bool { true }
    nonisolated func installModel(progress: @escaping @Sendable (Double) -> Void) async throws { progress(1.0) }
    nonisolated func removeModel() async throws {}
}
