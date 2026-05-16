import AVFoundation
import Foundation

/// Pure utility — reads an audio file from disk, computes RMS over equally
/// sized buckets, and returns a normalized 0...1 array of bar heights for
/// rendering a static waveform.
nonisolated enum AudioWaveformReader {

    /// `@concurrent` offloads onto the cooperative pool so the caller's actor
    /// (MainActor in our case) isn't blocked by the file read + RMS loop.
    @concurrent
    static func bars(for url: URL, count: Int = 96) async throws -> [Double] {
        try compute(url: url, count: count)
    }

    private static func compute(url: URL, count: Int) throws -> [Double] {
        guard count > 0 else { return [] }

        let file = try AVAudioFile(forReading: url)
        let format = file.processingFormat
        let totalFrames = AVAudioFrameCount(file.length)
        guard totalFrames > 0 else { return [] }

        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: totalFrames) else {
            return []
        }
        try file.read(into: buffer)

        guard let channels = buffer.floatChannelData else { return [] }
        let channelCount = Int(format.channelCount)
        let frames = Int(buffer.frameLength)
        guard frames > 0, channelCount > 0 else { return [] }

        let samplesPerBar = max(1, frames / count)
        var bars: [Double] = []
        bars.reserveCapacity(count)

        for barIdx in 0..<count {
            let start = barIdx * samplesPerBar
            let end = min(frames, start + samplesPerBar)
            guard start < end else {
                bars.append(0)
                continue
            }

            var sumSquares: Double = 0
            var sampleCount = 0
            for ch in 0..<channelCount {
                let chPtr = channels[ch]
                for i in start..<end {
                    let v = Double(chPtr[i])
                    sumSquares += v * v
                    sampleCount += 1
                }
            }
            let rms = sampleCount > 0 ? (sumSquares / Double(sampleCount)).squareRoot() : 0
            bars.append(rms)
        }

        let peak = bars.max() ?? 0
        guard peak > 0 else { return Array(repeating: 0.08, count: count) }
        return bars.map { value in
            let normalized = value / peak
            return max(0.08, min(1, normalized))
        }
    }
}
