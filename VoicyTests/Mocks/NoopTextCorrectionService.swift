@testable import Voicy

final class NoopTextCorrectionService: TextCorrectionService {
    nonisolated init() {}
    nonisolated func loadModel(onProgress: (@Sendable (Double) -> Void)?) async throws {}
    nonisolated func correct(
        _ text: String,
        mode: Mode,
        sourceLanguage: AppLanguage
    ) async throws -> String { text }
    nonisolated func isModelInstalled() -> Bool { true }
    nonisolated func ensureModelAvailable() -> Bool { true }
    nonisolated func installModel(progress: @escaping @Sendable (DownloadPhase) -> Void) async throws { progress(.downloading(1.0)) }
    nonisolated func removeModel() async throws {}
}
