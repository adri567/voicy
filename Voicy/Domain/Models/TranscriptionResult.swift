import Foundation

nonisolated struct TranscriptionResult: Sendable {
    let text: String
    let duration: TimeInterval
    let segments: [TranscriptionSegment]?
    let detectedLanguage: String?

    init(
        text: String,
        duration: TimeInterval,
        segments: [TranscriptionSegment]? = nil,
        detectedLanguage: String? = nil
    ) {
        self.text = text
        self.duration = duration
        self.segments = segments
        self.detectedLanguage = detectedLanguage
    }
}
