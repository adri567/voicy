enum PermissionState: Equatable, Sendable {
    case idle, granted, denied
}

protocol PermissionService: Sendable {
    func currentMicrophoneState() -> PermissionState
    func requestMicrophone() async -> PermissionState
    func openMicrophonePane()

    func currentAccessibilityState() -> PermissionState
    func requestAccessibility()

    func currentFnKeyState() -> PermissionState
    func disableFnKey()
    func openKeyboardPane()
}
