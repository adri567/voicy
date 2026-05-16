import AVFoundation
import Foundation

/// Thin wrapper around AVAudioPlayer used by the Transcribe page for file
/// playback. Lives on MainActor because the VM that owns it is MainActor —
/// AVAudioPlayer itself is thread-safe, so this is a convenience boundary.
@MainActor
final class TranscribeAudioPlayer {

    private var player: AVAudioPlayer?

    init() {}

    var duration: TimeInterval {
        player?.duration ?? 0
    }

    var currentTime: TimeInterval {
        player?.currentTime ?? 0
    }

    var isPlaying: Bool {
        player?.isPlaying ?? false
    }

    /// Progress 0...1 of the current playhead within the loaded file.
    var progress: Double {
        guard let p = player, p.duration > 0 else { return 0 }
        return p.currentTime / p.duration
    }

    func load(url: URL) throws {
        stop()
        let p = try AVAudioPlayer(contentsOf: url)
        p.prepareToPlay()
        player = p
    }

    func play() {
        player?.play()
    }

    func pause() {
        player?.pause()
    }

    func stop() {
        player?.stop()
        player = nil
    }

    func seek(toFraction fraction: Double) {
        guard let p = player else { return }
        let clamped = min(max(fraction, 0), 1)
        p.currentTime = clamped * p.duration
    }
}
