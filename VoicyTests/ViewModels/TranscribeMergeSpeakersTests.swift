import Foundation
import Testing
@testable import Voicy

@Suite("TranscribeViewModel — mergeSpeakers")
struct TranscribeMergeSpeakersTests {

    private func segment(_ start: TimeInterval, _ end: TimeInterval) -> TranscriptionSegment {
        TranscriptionSegment(start: start, end: end, text: "x")
    }

    @Test("Empty diarization leaves segments unchanged (no speaker)")
    func emptyDiarization() {
        let segments = [segment(0, 2), segment(2, 4)]
        let merged = TranscribeViewModel.mergeSpeakers(into: segments, diarization: [])
        #expect(merged.count == 2)
        #expect(merged.allSatisfy { $0.speaker == nil })
    }

    @Test("Single overlapping diarization span assigns its speaker")
    func singleOverlap() {
        let merged = TranscribeViewModel.mergeSpeakers(
            into: [segment(0, 2)],
            diarization: [DiarizationSegment(start: 0, end: 2, speakerId: 3)]
        )
        #expect(merged[0].speaker == 3)
    }

    @Test("Speaker with the largest overlap wins")
    func maxOverlapWins() {
        // Segment 0–10. Speaker 1 overlaps 0–3 (3s), speaker 2 overlaps 3–10 (7s).
        let merged = TranscribeViewModel.mergeSpeakers(
            into: [segment(0, 10)],
            diarization: [
                DiarizationSegment(start: 0, end: 3, speakerId: 1),
                DiarizationSegment(start: 3, end: 10, speakerId: 2)
            ]
        )
        #expect(merged[0].speaker == 2)
    }

    @Test("No temporal overlap leaves speaker nil")
    func noOverlap() {
        let merged = TranscribeViewModel.mergeSpeakers(
            into: [segment(0, 2)],
            diarization: [DiarizationSegment(start: 5, end: 8, speakerId: 1)]
        )
        #expect(merged[0].speaker == nil)
    }

    @Test("Original timing and text are preserved")
    func preservesContent() {
        let merged = TranscribeViewModel.mergeSpeakers(
            into: [TranscriptionSegment(start: 1, end: 4, text: "hello")],
            diarization: [DiarizationSegment(start: 1, end: 4, speakerId: 0)]
        )
        #expect(merged[0].start == 1)
        #expect(merged[0].end == 4)
        #expect(merged[0].text == "hello")
        #expect(merged[0].speaker == 0)
    }
}
