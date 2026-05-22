import Foundation
import OSLog
import SwiftData

/// One-shot reset that wipes all existing `TranscriptionEntry` rows on first
/// launch after the file-history split. Without this, old file-runs would
/// stay mixed in with mic dictations in HomeView. Guarded by a UserDefaults
/// flag so it never runs twice.
nonisolated enum HistoryMigration {
    static let migratedKey = "didResetHistoryForFileSeparationV2"

    @MainActor
    static func runIfNeeded(container: ModelContainer) {
        guard !UserDefaults.standard.bool(forKey: migratedKey) else { return }
        let context = ModelContext(container)
        do {
            try context.delete(model: TranscriptionEntry.self)
            try context.save()
            Log.history.info("HistoryMigration: reset complete — all TranscriptionEntry rows deleted")
        } catch {
            Log.history.error("HistoryMigration: reset failed: \(error.localizedDescription, privacy: .public)")
        }
        UserDefaults.standard.set(true, forKey: migratedKey)
    }
}
