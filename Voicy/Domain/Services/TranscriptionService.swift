import Foundation

protocol TranscriptionService: Sendable {
    func loadModel() async throws
    func startRecording() async throws
    func stopAndTranscribe() async throws -> TranscriptionResult
}
