import CoreAudio
import Foundation

nonisolated struct AudioInputDevice: Identifiable, Hashable, Sendable {
    let id: AudioDeviceID
    let uid: String
    let name: String
    let subtitle: String
    let kind: AudioInputDeviceKind
}
