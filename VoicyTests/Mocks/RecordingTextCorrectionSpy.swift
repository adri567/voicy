@testable import Voicy

actor RecordingTextCorrectionSpy: TextCorrectionService {
    private(set) var lastSource: AppLanguage?
    private(set) var lastMode: Mode?
    private(set) var callCount = 0

    init() {}
    nonisolated func loadModel(onProgress: (@Sendable (Double) -> Void)?) async throws {}
    nonisolated func correct(
        _ text: String,
        mode: Mode,
        sourceLanguage: AppLanguage
    ) async throws -> String {
        await record(mode: mode, source: sourceLanguage)
        return text + " [\(mode.type.rawValue)]"
    }
    nonisolated func isModelInstalled() -> Bool { true }
    nonisolated func ensureModelAvailable() -> Bool { true }
    nonisolated func installModel(progress: @escaping @Sendable (DownloadPhase) -> Void) async throws { progress(.downloading(1.0)) }
    nonisolated func removeModel() async throws {}

    private func record(mode: Mode, source: AppLanguage) {
        callCount += 1
        lastMode = mode
        lastSource = source
    }
}
