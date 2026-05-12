import Foundation

protocol TranscriptionService: Sendable {
    nonisolated func loadModel() async throws
    nonisolated func startRecording() async throws
    nonisolated func stopAndTranscribe() async throws -> TranscriptionResult
    nonisolated func currentAudioLevel() -> Float
}
