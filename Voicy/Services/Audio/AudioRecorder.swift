import Foundation
import WhisperKit

/// Wrapper über WhisperKits AudioProcessor.
/// Beide Transcription-Engines (Whisper, Parakeet) nutzen denselben Recorder
/// — die Engines sind nur für Inferenz zuständig, das Mikrofon-Capture ist geteilt.
final class AudioRecorder {

    nonisolated(unsafe) private var processor: AudioProcessor?
    nonisolated(unsafe) private var startDate: Date?

    nonisolated init() {}

    nonisolated func start() throws {
        let processor = AudioProcessor()
        try processor.startRecordingLive(inputDeviceID: nil, callback: nil)
        self.processor = processor
        self.startDate = Date()
    }

    nonisolated func stop() -> (samples: [Float], duration: TimeInterval) {
        let duration = startDate.map { Date().timeIntervalSince($0) } ?? 0
        processor?.stopRecording()
        let samples = Array(processor?.audioSamples ?? [])
        processor = nil
        startDate = nil
        return (samples, duration)
    }

    nonisolated func currentLevel() -> Float {
        processor?.relativeEnergy.last.map { max(0, min(1, $0)) } ?? 0
    }
}
