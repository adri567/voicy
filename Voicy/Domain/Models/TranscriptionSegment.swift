import Foundation

nonisolated struct TranscriptionSegment: Sendable, Hashable, Identifiable, Codable {
    let id: UUID
    let start: TimeInterval
    let end: TimeInterval
    let text: String

    init(start: TimeInterval, end: TimeInterval, text: String) {
        self.id = UUID()
        self.start = start
        self.end = end
        self.text = text
    }
}
