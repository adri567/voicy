import Foundation

protocol TranscriptionService: Sendable {
    nonisolated func loadModel() async throws
    nonisolated func startRecording() async throws
    nonisolated func stopAndTranscribe() async throws -> TranscriptionResult
    nonisolated func currentAudioLevel() async -> Float

    // MARK: - Download management

    /// True iff the model files exist on disk. Pure disk check — safe to call
    /// from any isolation context.
    nonisolated func isModelInstalled() -> Bool

    /// Downloads the model files with progress (fraction 0...1).
    /// Idempotent — no-op if already installed.
    nonisolated func installModel(progress: @escaping @Sendable (Double) -> Void) async throws

    /// Unloads the model from RAM and removes its files from disk.
    nonisolated func removeModel() async throws
}
