import Foundation
import SwiftData

final class SwiftDataFileTranscriptionHistoryService: FileTranscriptionHistoryService {

    private let container: ModelContainer

    nonisolated init(container: ModelContainer) {
        self.container = container
    }

    nonisolated func save(_ entry: FileTranscriptionEntry) async throws {
        let context = ModelContext(container)
        context.insert(entry)
        try context.save()
    }
}
