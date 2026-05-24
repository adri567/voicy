protocol TextCorrectionService: Sendable {
    nonisolated func loadModel(onProgress: (@Sendable (Double) -> Void)?) async throws

    /// Run the given mode against the transcript. The `.raw` case never hits
    /// this method — RecordingViewModel branches before calling.
    nonisolated func correct(
        _ text: String,
        mode: Mode,
        sourceLanguage: AppLanguage
    ) async throws -> String

    // MARK: - Download management

    nonisolated func isModelInstalled() -> Bool

    /// True if a usable model is available for correction. May promote an
    /// already-installed fallback model to "active" as a side effect, so a
    /// model that was downloaded but never explicitly set as default still
    /// gets picked up by the correction pipeline. Routed through the service
    /// (rather than a static disk check) so callers stay testable.
    nonisolated func ensureModelAvailable() -> Bool

    nonisolated func installModel(progress: @escaping @Sendable (DownloadPhase) -> Void) async throws
    nonisolated func removeModel() async throws
}

extension TextCorrectionService {
    nonisolated func loadModel() async throws {
        try await loadModel(onProgress: nil)
    }
}
