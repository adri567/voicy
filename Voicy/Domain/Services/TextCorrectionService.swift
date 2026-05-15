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
    nonisolated func installModel(progress: @escaping @Sendable (Double) -> Void) async throws
    nonisolated func removeModel() async throws
}

extension TextCorrectionService {
    nonisolated func loadModel() async throws {
        try await loadModel(onProgress: nil)
    }
}
