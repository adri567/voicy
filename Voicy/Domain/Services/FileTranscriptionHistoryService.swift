import Foundation

protocol FileTranscriptionHistoryService: Sendable {
    nonisolated func save(_ entry: FileTranscriptionEntry) async throws
}
