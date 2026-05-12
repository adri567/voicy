protocol TextCorrectionService: Sendable {
    nonisolated func loadModel(onProgress: (@Sendable (Double) -> Void)?) async throws
    nonisolated func correct(_ text: String) async throws -> String
}

extension TextCorrectionService {
    nonisolated func loadModel() async throws {
        try await loadModel(onProgress: nil)
    }
}
