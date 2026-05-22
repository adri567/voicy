import Foundation
@testable import Voicy

final class NoopTranscriptionHistoryService: TranscriptionHistoryService {
    nonisolated init() {}
    nonisolated func save(
        text: String,
        duration: TimeInterval,
        engine: TranscriptionEngine,
        corrected: Bool,
        target: TargetAppSnapshot?
    ) async throws {}
    nonisolated func deleteAll() async throws {}
}
