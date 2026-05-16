import Foundation
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
            print("[HistoryMigration] reset complete — all TranscriptionEntry rows deleted")
        } catch {
            print("[HistoryMigration] reset failed: \(error.localizedDescription)")
        }
        UserDefaults.standard.set(true, forKey: migratedKey)
    }
}
