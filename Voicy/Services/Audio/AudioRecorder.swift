import Foundation
import WhisperKit

/// Wrapper über WhisperKits AudioProcessor.
/// Beide Transcription-Engines (Whisper, Parakeet) nutzen denselben Recorder
/// — die Engines sind nur für Inferenz zuständig, das Mikrofon-Capture ist geteilt.
///
/// Owned by the transcription actor — its state lives inside that actor's
/// isolation domain, so this type is marked `nonisolated` to opt out of the
/// project-wide MainActor default and lets the owning actor call its methods
/// from its own isolation context without hopping to main.
nonisolated final class AudioRecorder {

    private var processor: AudioProcessor?
    private var startDate: Date?

    init() {}

    func start() throws {
        let processor = AudioProcessor()
        try processor.startRecordingLive(inputDeviceID: nil, callback: nil)
        self.processor = processor
        self.startDate = Date()
    }

    func stop() -> (samples: [Float], duration: TimeInterval) {
        let duration = startDate.map { Date().timeIntervalSince($0) } ?? 0
        processor?.stopRecording()
        let samples = Array(processor?.audioSamples ?? [])
        processor = nil
        startDate = nil
        return (samples, duration)
    }

    func currentLevel() -> Float {
        processor?.relativeEnergy.last.map { max(0, min(1, $0)) } ?? 0
    }
}
