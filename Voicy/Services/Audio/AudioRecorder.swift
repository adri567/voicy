import CoreAudio
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

    func start(inputDeviceID: AudioDeviceID? = nil) throws {
        let processor = AudioProcessor()
        try processor.startRecordingLive(inputDeviceID: inputDeviceID, callback: nil)
        self.processor = processor
        self.startDate = Date()
    }

    /// Sample rate used by WhisperKit's AudioProcessor.
    private static let sampleRate = 16_000
    /// Number of samples to crop at the start AND end of every recording.
    /// 200 ms covers the leaked echo of Voicy's start/stop UI sounds —
    /// without this, the system speaker leaks into the mic and the
    /// transcription often contains a stray "click" or hallucinated word.
    /// Users typically wait ~150 ms after the start beep before speaking,
    /// so cropping this window doesn't eat real speech.
    private static let cropSamples = sampleRate / 5  // 200 ms

    func stop() -> (samples: [Float], duration: TimeInterval) {
        let duration = startDate.map { Date().timeIntervalSince($0) } ?? 0
        processor?.stopRecording()
        let raw = Array(processor?.audioSamples ?? [])
        processor = nil
        startDate = nil

        // Drop the UI-sound bleed at both ends. If the recording is shorter
        // than the combined crop, keep what we have rather than returning
        // an empty array.
        let trimmed: [Float]
        if raw.count > Self.cropSamples * 2 {
            trimmed = Array(raw[Self.cropSamples..<(raw.count - Self.cropSamples)])
        } else {
            trimmed = raw
        }
        return (trimmed, duration)
    }

    func currentLevel() -> Float {
        processor?.relativeEnergy.last.map { max(0, min(1, $0)) } ?? 0
    }
}
