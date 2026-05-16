import AVFoundation
import Foundation

/// Real-file metadata for the Transcribe page (display only). Replaces the
/// fixture `TranscribeSampleFile` that was used by the UI shell.
nonisolated struct TranscribeFileInfo: Sendable, Hashable {
    let name: String
    let size: String
    let sizeBytes: Int64
    let durationSeconds: Int
    let durationLabel: String
    let format: String

    static func load(from url: URL) async throws -> TranscribeFileInfo {
        try await Task.detached(priority: .userInitiated) {
            try read(from: url)
        }.value
    }

    private static func read(from url: URL) throws -> TranscribeFileInfo {
        let file = try AVAudioFile(forReading: url)
        let format = file.processingFormat
        let totalFrames = Double(file.length)
        let duration = format.sampleRate > 0 ? totalFrames / format.sampleRate : 0

        let attrs = try? FileManager.default.attributesOfItem(atPath: url.path)
        let bytes = (attrs?[.size] as? NSNumber)?.int64Value ?? 0
        let sizeString = ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)

        let ext = url.pathExtension.uppercased()
        let channels = Int(format.channelCount)
        let sampleRateKHz = Int((format.sampleRate / 1000).rounded())
        let channelLabel = channels >= 2 ? "stereo" : "mono"
        let formatLabel = "\(ext) · \(sampleRateKHz) kHz · \(channelLabel)"

        let durSeconds = Int(duration.rounded())
        let durationLabel = Duration.seconds(durSeconds).formatted(.time(pattern: .minuteSecond))

        return TranscribeFileInfo(
            name: url.lastPathComponent,
            size: sizeString,
            sizeBytes: bytes,
            durationSeconds: durSeconds,
            durationLabel: durationLabel,
            format: formatLabel
        )
    }
}
