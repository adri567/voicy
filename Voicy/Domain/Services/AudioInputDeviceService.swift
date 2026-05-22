import CoreAudio
import Foundation

protocol AudioInputDeviceService: Sendable {
    nonisolated func currentSnapshot() async -> [AudioInputDevice]
    nonisolated func deviceID(forUID uid: String) async -> AudioDeviceID?
    nonisolated func systemDefaultDeviceID() async -> AudioDeviceID?
    nonisolated var changes: AsyncStream<[AudioInputDevice]> { get }
}

extension AudioInputDeviceService {
    /// Resolves the persisted UID (`Preferences.Key.selectedAudioDeviceUID`) to a
    /// live `AudioDeviceID`. Returns `nil` if no UID is stored or the device is
    /// no longer present — callers should then fall back to the system default.
    nonisolated func resolveSelectedDeviceID() async -> AudioDeviceID? {
        let uid = UserDefaults.standard.string(forKey: Preferences.Key.selectedAudioDeviceUID)
        guard let uid, !uid.isEmpty else { return nil }
        return await deviceID(forUID: uid)
    }
}
