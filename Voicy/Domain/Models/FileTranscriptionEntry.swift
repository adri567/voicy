import Foundation
import SwiftData

/// Persisted record of one file-transcription run on the Transcribe page.
/// Intentionally separate from `TranscriptionEntry` (mic dictation history)
/// so the two sources don't get mixed in HomeView's history.
@Model
final class FileTranscriptionEntry {
    var id: UUID
    var createdAt: Date
    var fileName: String
    var fileSizeBytes: Int64
    var fileFormat: String
    var durationSeconds: Double
    var engineRaw: String
    var sourceLanguageCode: String
    var fullText: String
    var segmentsData: Data

    init(
        createdAt: Date,
        fileName: String,
        fileSizeBytes: Int64,
        fileFormat: String,
        durationSeconds: Double,
        engine: TranscriptionEngine,
        sourceLanguageCode: String,
        fullText: String,
        segments: [TranscriptionSegment]
    ) {
        self.id = UUID()
        self.createdAt = createdAt
        self.fileName = fileName
        self.fileSizeBytes = fileSizeBytes
        self.fileFormat = fileFormat
        self.durationSeconds = durationSeconds
        self.engineRaw = engine.rawValue
        self.sourceLanguageCode = sourceLanguageCode
        self.fullText = fullText
        self.segmentsData = (try? JSONEncoder().encode(segments)) ?? Data()
    }

    var engine: TranscriptionEngine {
        TranscriptionEngine(rawValue: engineRaw) ?? .whisper
    }

    var segments: [TranscriptionSegment] {
        (try? JSONDecoder().decode([TranscriptionSegment].self, from: segmentsData)) ?? []
    }

    var preview: String {
        if let first = segments.first?.text, !first.isEmpty { return first }
        return fullText
    }

    var wordCount: Int {
        fullText.wordCount
    }

    var durationLabel: String {
        Duration.seconds(Int(durationSeconds)).formatted(.time(pattern: .minuteSecond))
    }
}
