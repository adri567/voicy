import Foundation

protocol DiarizationService: Sendable {
    /// Run speaker diarization over a file. Returns one entry per contiguous
    /// speaker span. Empty array means the model wasn't installed or the file
    /// produced no detectable speakers — callers should treat that as "no
    /// speaker info" rather than an error.
    nonisolated func diarize(at url: URL) async throws -> [DiarizationSegment]

    nonisolated func isModelInstalled() -> Bool
    nonisolated func installModel(progress: @escaping @Sendable (Double) -> Void) async throws
    nonisolated func removeModel() async throws
}

nonisolated enum DiarizationError: LocalizedError {
    case modelNotLoaded

    var errorDescription: String? {
        switch self {
        case .modelNotLoaded:
            return "Diarization-Modell ist noch nicht geladen."
        }
    }
}
