import Foundation
@testable import Voicy

final class MockTranscriptionService: TranscriptionService {
    static let mockText = "Hallo, das ist ein Test."

    nonisolated init() {}
    nonisolated func loadModel() async throws {}
    nonisolated func startRecording() async throws {}
    nonisolated func stopAndTranscribe(language: String) async throws -> TranscriptionResult {
        TranscriptionResult(text: Self.mockText, duration: 1.5)
    }
    nonisolated func cancelRecording() async {}
    nonisolated func currentAudioLevel() async -> Float { 0 }
    nonisolated func transcribeFile(at url: URL, language: String?) async throws -> TranscriptionResult {
        TranscriptionResult(text: Self.mockText, duration: 1.5)
    }
    nonisolated func isModelInstalled() -> Bool { true }
    nonisolated func installModel(progress: @escaping @Sendable (DownloadPhase) -> Void) async throws { progress(.downloading(1.0)) }
    nonisolated func removeModel() async throws {}
}
