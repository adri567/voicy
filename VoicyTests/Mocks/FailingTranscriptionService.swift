import Foundation
@testable import Voicy

final class FailingTranscriptionService: TranscriptionService {
    nonisolated init() {}
    nonisolated func loadModel() async throws { throw TestError.loadFailed }
    nonisolated func startRecording() async throws {}
    nonisolated func stopAndTranscribe(language: String) async throws -> TranscriptionResult {
        throw TestError.loadFailed
    }
    nonisolated func cancelRecording() async {}
    nonisolated func currentAudioLevel() async -> Float { 0 }
    nonisolated func transcribeFile(at url: URL, language: String?) async throws -> TranscriptionResult {
        throw TestError.loadFailed
    }
    nonisolated func isModelInstalled() -> Bool { false }
    nonisolated func installModel(progress: @escaping @Sendable (DownloadPhase) -> Void) async throws { throw TestError.loadFailed }
    nonisolated func removeModel() async throws {}
}
