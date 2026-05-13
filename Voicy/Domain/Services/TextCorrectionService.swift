protocol TextCorrectionService: Sendable {
    nonisolated func loadModel(onProgress: (@Sendable (Double) -> Void)?) async throws
    nonisolated func correct(
        _ text: String,
        sourceLanguage: AppLanguage,
        targetLanguage: AppLanguage?
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
