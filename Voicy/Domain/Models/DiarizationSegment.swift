import Foundation

/// One contiguous span of audio attributed to a single speaker by the
/// diarization model. Independent of the transcription's word/phrase
/// segments — the pipeline merges these two streams via time overlap.
nonisolated struct DiarizationSegment: Sendable, Hashable {
    let start: TimeInterval
    let end: TimeInterval
    let speakerId: Int
}
