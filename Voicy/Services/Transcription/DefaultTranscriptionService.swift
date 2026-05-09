import AVFoundation
import Foundation
import WhisperKit

final class DefaultTranscriptionService: TranscriptionService {

    nonisolated(unsafe) private var whisperKit: WhisperKit?
    nonisolated(unsafe) private var audioRecorder: AVAudioRecorder?
    nonisolated(unsafe) private var recordingURL: URL?
    nonisolated(unsafe) private var recordingStartDate: Date?

    nonisolated init() {}

    func loadModel() async throws {
        guard whisperKit == nil else { return }
        whisperKit = try await WhisperKit(model: "openai_whisper-small")
    }

    func startRecording() async throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("m4a")

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 16000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        audioRecorder = try AVAudioRecorder(url: url, settings: settings)
        audioRecorder?.record()
        recordingURL = url
        recordingStartDate = Date()
    }

    func stopAndTranscribe() async throws -> TranscriptionResult {
        guard let recorder = audioRecorder, let url = recordingURL else {
            throw TranscriptionError.noActiveRecording
        }

        let duration = recordingStartDate.map { Date().timeIntervalSince($0) } ?? 0
        recorder.stop()
        audioRecorder = nil

        guard let kit = whisperKit else {
            throw TranscriptionError.modelNotLoaded
        }

        let results = try await kit.transcribe(audioPath: url.path(), decodeOptions: DecodingOptions(language: "de"))
        let text = results.compactMap(\.text).joined(separator: " ").trimmingCharacters(in: .whitespaces)

        try? FileManager.default.removeItem(at: url)
        recordingURL = nil
        recordingStartDate = nil

        return TranscriptionResult(text: text, duration: duration)
    }
}

enum TranscriptionError: LocalizedError {
    case modelNotLoaded
    case noActiveRecording

    var errorDescription: String? {
        switch self {
        case .modelNotLoaded: "Whisper-Modell ist noch nicht geladen."
        case .noActiveRecording: "Keine aktive Aufnahme vorhanden."
        }
    }
}


