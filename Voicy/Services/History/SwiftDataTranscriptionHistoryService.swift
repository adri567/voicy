import Foundation
import SwiftData

final class SwiftDataTranscriptionHistoryService: TranscriptionHistoryService {

    private let container: ModelContainer

    nonisolated init(container: ModelContainer) {
        self.container = container
    }

    nonisolated func save(
        text: String,
        duration: TimeInterval,
        engine: TranscriptionEngine,
        corrected: Bool,
        target: TargetAppSnapshot?
    ) async throws {
        let context = ModelContext(container)
        let entry = TranscriptionEntry(
            text: text,
            createdAt: Date(),
            duration: duration,
            engine: engine,
            corrected: corrected,
            target: target
        )
        context.insert(entry)
        try context.save()
    }

    nonisolated func deleteAll() async throws {
        let context = ModelContext(container)
        try context.delete(model: TranscriptionEntry.self)
        try context.save()
    }
}
