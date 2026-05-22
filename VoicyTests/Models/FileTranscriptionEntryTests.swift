import Foundation
import Testing
@testable import Voicy

@Suite("FileTranscriptionEntry")
struct FileTranscriptionEntryTests {

    private func makeEntry(
        fullText: String,
        segments: [TranscriptionSegment] = []
    ) -> FileTranscriptionEntry {
        FileTranscriptionEntry(
            createdAt: .now,
            fileName: "memo.m4a",
            fileSizeBytes: 1024,
            fileFormat: "m4a",
            durationSeconds: 12,
            engine: .whisper,
            sourceLanguageCode: "en",
            fullText: fullText,
            segments: segments
        )
    }

    @Test("wordCount counts words in fullText")
    func wordCount() {
        #expect(makeEntry(fullText: "one two three").wordCount == 3)
    }

    @Test("Segments round-trip through JSON encoding")
    func segmentsRoundTrip() {
        let segs = [
            TranscriptionSegment(start: 0, end: 1, text: "hello"),
            TranscriptionSegment(start: 1, end: 2, text: "world", speaker: 1)
        ]
        let entry = makeEntry(fullText: "hello world", segments: segs)
        #expect(entry.segments.count == 2)
        #expect(entry.segments[0].text == "hello")
        #expect(entry.segments[1].speaker == 1)
    }

    @Test("preview returns the first segment's text when present")
    func previewFromSegment() {
        let entry = makeEntry(
            fullText: "full transcript text",
            segments: [TranscriptionSegment(start: 0, end: 1, text: "first segment")]
        )
        #expect(entry.preview == "first segment")
    }

    @Test("preview falls back to fullText when there are no segments")
    func previewFallback() {
        let entry = makeEntry(fullText: "full transcript text")
        #expect(entry.preview == "full transcript text")
    }

    @Test("engine deserializes from the raw value")
    func engineDeserializes() {
        #expect(makeEntry(fullText: "x").engine == .whisper)
    }
}
