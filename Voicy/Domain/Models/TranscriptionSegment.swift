import Foundation

nonisolated struct TranscriptionSegment: Sendable, Hashable, Identifiable, Codable {
    let id: UUID
    let start: TimeInterval
    let end: TimeInterval
    let text: String
    /// Zero-based speaker index from diarization, or `nil` if diarization
    /// wasn't run for this segment. Codable's default decoding tolerates
    /// missing keys when the property is Optional — old `segmentsData`
    /// JSON blobs (pre-diarization) load as `nil` without a migration.
    let speaker: Int?

    init(start: TimeInterval, end: TimeInterval, text: String, speaker: Int? = nil) {
        self.id = UUID()
        self.start = start
        self.end = end
        self.text = text
        self.speaker = speaker
    }
}
