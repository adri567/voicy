import AppKit
import AVFoundation

enum PermissionState: Equatable, Sendable {
    case idle, granted, denied
}

@MainActor
final class PermissionService {

    static let shared = PermissionService()

    private init() {}

    // MARK: - Microphone

    func currentMicrophoneState() -> PermissionState {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized: return .granted
        case .denied, .restricted: return .denied
        case .notDetermined: return .idle
        @unknown default: return .idle
        }
    }

    func requestMicrophone() async -> PermissionState {
        if AVCaptureDevice.authorizationStatus(for: .audio) == .authorized {
            return .granted
        }
        let ok = await AVCaptureDevice.requestAccess(for: .audio)
        return ok ? .granted : .denied
    }

    // MARK: - Accessibility

    func currentAccessibilityState() -> PermissionState {
        AXIsProcessTrusted() ? .granted : .idle
    }

    /// Triggers the standard macOS Accessibility prompt and opens
    /// System Settings → Privacy → Accessibility so the user can flip the toggle.
    func requestAccessibility() {
        let key = "AXTrustedCheckOptionPrompt" as CFString
        let options = [key: kCFBooleanTrue!] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
        openAccessibilityPane()
    }

    private func openAccessibilityPane() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
}
