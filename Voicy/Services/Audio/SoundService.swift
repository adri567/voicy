import AppKit
import Foundation

/// Plays the three UX feedback sounds for Voicy. Uses macOS' built-in
/// `/System/Library/Sounds` files — no bundled assets, no licensing.
/// All calls are no-ops when the user has disabled sounds in onboarding.
///
/// Sound choices are subjective — swap the `named:` strings below for any
/// of: Basso, Blow, Bottle, Frog, Funk, Glass, Hero, Morse, Ping, Pop,
/// Purr, Sosumi, Submarine, Tink.
@MainActor
enum SoundService {

    /// Recording start/stop sit at this level. Quiet enough that the system
    /// speaker doesn't leak loudly into the mic — the audio recorder also
    /// crops the first/last 200 ms as belt-and-suspenders so any residual
    /// click never reaches Whisper / Parakeet.
    private static let recordingVolume: Float = 0.25
    /// Mode-switch fires during recording (when the user is cycling with
    /// Fn+arrows), so it has to be markedly quieter — it shouldn't grab
    /// attention, just confirm the gesture happened.
    private static let modeSwitchVolume: Float = 0.08

    static func playRecordingStart() { play("Purr",  volume: recordingVolume) }
    static func playRecordingStop()  { play("Pop",   volume: recordingVolume) }
    static func playModeSwitch()     { play("Morse", volume: modeSwitchVolume) }

    /// Cache one NSSound per name so we can stop+restart it. Without the
    /// `stop()`, NSSound silently drops `play()` calls that arrive while
    /// the previous playback is still active — meaning a fast mode-cycle
    /// (Fn+→ →) would only beep on the first step.
    private static var cache: [String: NSSound] = [:]

    private static func play(_ name: String, volume: Float) {
        guard enabled else { return }
        let sound = cache[name] ?? NSSound(named: name)
        guard let sound else { return }
        cache[name] = sound
        sound.stop()
        sound.volume = volume
        sound.play()
    }

    /// Default-on: if the preference hasn't been written yet (e.g. user
    /// hasn't finished onboarding), treat that as enabled rather than mute.
    private static var enabled: Bool {
        let d = UserDefaults.standard
        if d.object(forKey: Preferences.Key.onboardingClickSounds) == nil { return true }
        return d.bool(forKey: Preferences.Key.onboardingClickSounds)
    }
}
