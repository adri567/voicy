import Foundation

nonisolated enum AudioInputDeviceKind: Sendable {
    case builtIn
    case wireless
    case usb
    case external
    case virtual
}
