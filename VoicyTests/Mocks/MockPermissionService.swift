@testable import Voicy

/// All-granted permission stub so `OnboardingState` can be constructed in tests
/// without touching the real TCC/system state.
final class MockPermissionService: PermissionService {
    nonisolated init() {}

    func currentMicrophoneState() -> PermissionState { .granted }
    func requestMicrophone() async -> PermissionState { .granted }
    func openMicrophonePane() {}

    func currentAccessibilityState() -> PermissionState { .granted }
    func requestAccessibility() {}

    func currentFnKeyState() -> PermissionState { .granted }
    func disableFnKey() {}
    func openKeyboardPane() {}
}
