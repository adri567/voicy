import Foundation

protocol TranscriptionService: Sendable {
    nonisolated func loadModel() async throws
    nonisolated func startRecording() async throws
    nonisolated func stopAndTranscribe() async throws -> TranscriptionResult
    /// Stops the active recording without running inference. Samples are
    /// dropped. Used when the user's tap was too short to be meaningful
    /// (double-tap first half, accidental brush) — instant return, so the
    /// app state can flip back to idle without waiting for ASR.
    nonisolated func cancelRecording() async
    nonisolated func currentAudioLevel() async -> Float

    /// Transcribe an audio/video file from disk. Loaded model required.
    /// - Parameters:
    ///   - url: File URL (m4a, mp3, wav, mp4, etc.)
    ///   - language: ISO code (e.g. "de", "en"). `nil` means auto-detect — only
    ///     supported by WhisperKit. Parakeet falls back to its default.
    nonisolated func transcribeFile(
        at url: URL,
        language: String?
    ) async throws -> TranscriptionResult

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
