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

    /// Asks the system for microphone access. The system-level prompt only
    /// appears on the very first `.notDetermined` call — every subsequent
    /// `requestAccess` after the user has denied returns `false` immediately
    /// without UI. In that case we open the Microphone privacy pane so the
    /// user can flip the toggle manually.
    func requestMicrophone() async -> PermissionState {
        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        switch status {
        case .authorized:
            return .granted
        case .denied, .restricted:
            openMicrophonePane()
            return .denied
        case .notDetermined:
            let ok = await AVCaptureDevice.requestAccess(for: .audio)
            return ok ? .granted : .denied
        @unknown default:
            return .idle
        }
    }

    func openMicrophonePane() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone") {
            NSWorkspace.shared.open(url)
        }
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

    // MARK: - Fn / 🌐 key behavior
    //
    // macOS triggers the Character Viewer / dictation / input-source switch
    // when the Fn key is pressed, based on `AppleFnUsageType` in
    // `com.apple.HIToolbox`. Voicy needs that set to 0 ("Do Nothing") so
    // the Fn hotkey can be used cleanly. The setting only takes effect
    // after logout/login — there is no way to apply it at runtime.
    //
    // Values: 0=Do Nothing, 1=Change Input Source, 2=Show Emoji & Symbols
    // (default on modern Macs), 3=Start Dictation.

    func currentFnKeyState() -> PermissionState {
        // Check the per-host value (CurrentHost) first since System
        // Settings + HIToolbox use that, then fall back to the merged
        // any-host view as a safety net.
        let perHost = CFPreferencesCopyValue("AppleFnUsageType" as CFString,
                                             "com.apple.HIToolbox" as CFString,
                                             kCFPreferencesCurrentUser,
                                             kCFPreferencesCurrentHost) as? Int
        if let perHost { return perHost == 0 ? .granted : .idle }
        let merged = CFPreferencesCopyAppValue("AppleFnUsageType" as CFString,
                                               "com.apple.HIToolbox" as CFString) as? Int
        return merged == 0 ? .granted : .idle
    }

    /// Sets `AppleFnUsageType` to 0 ("Do Nothing") in both host scopes and
    /// then nudges HIToolbox to re-read the value live — what System
    /// Settings does internally when the user picks "Do Nothing" from
    /// the dropdown, no logout required.
    ///
    /// Three steps:
    /// 1. Write to AnyHost and CurrentHost (HIToolbox uses CurrentHost,
    ///    System Settings UI reflects AnyHost — both must match).
    /// 2. Call Apple's private `activateSettings -u` utility — documented
    ///    to push preference changes into running daemons immediately.
    /// 3. Post `AppleKeyboardPreferencesChangedNotification` on the
    ///    distributed notification center, which HIToolbox listens to.
    func disableFnKey() {
        writeFnKeyValue(0 as CFNumber)
        nudgeHIToolbox()
    }

    /// Restores the system default (key removed → Show Emoji & Symbols).
    /// Best-effort revert hook for an eventual uninstall flow.
    func restoreFnKeyDefault() {
        writeFnKeyValue(nil)
        nudgeHIToolbox()
    }

    private func writeFnKeyValue(_ value: CFNumber?) {
        let key = "AppleFnUsageType" as CFString
        let domain = "com.apple.HIToolbox" as CFString
        CFPreferencesSetValue(key, value, domain,
                              kCFPreferencesCurrentUser, kCFPreferencesAnyHost)
        CFPreferencesSetValue(key, value, domain,
                              kCFPreferencesCurrentUser, kCFPreferencesCurrentHost)
        CFPreferencesSynchronize(domain,
                                 kCFPreferencesCurrentUser, kCFPreferencesAnyHost)
        CFPreferencesSynchronize(domain,
                                 kCFPreferencesCurrentUser, kCFPreferencesCurrentHost)
    }

    private func nudgeHIToolbox() {
        // 1) Apple's private activateSettings utility pushes preference
        //    changes into running daemons.
        runProcess("/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings",
                   ["-u"])

        // 2) Send SIGHUP to cfprefsd so it flushes its in-memory cache —
        //    HIToolbox reads preferences through cfprefsd, so this forces
        //    a fresh read on the next query.
        runProcess("/usr/bin/killall", ["-HUP", "cfprefsd"])

        // 3) Post the notifications HIToolbox / Carbon-era keyboard code
        //    typically listens to for live preference reloads.
        let dnc = DistributedNotificationCenter.default()
        let names = [
            "AppleKeyboardPreferencesChangedNotification",
            "com.apple.HIToolbox.AppleFnUsageTypeChanged",
            "AppleHardwareKeyboardPreferencesChanged",
            "com.apple.Carbon.TISNotifySelectedKeyboardInputSourceChanged"
        ]
        for name in names {
            dnc.postNotificationName(NSNotification.Name(name),
                                     object: nil,
                                     userInfo: nil,
                                     deliverImmediately: true)
        }
    }

    private func runProcess(_ path: String, _ args: [String]) {
        guard FileManager.default.isExecutableFile(atPath: path) else { return }
        let task = Process()
        task.launchPath = path
        task.arguments = args
        try? task.run()
    }

    func openKeyboardPane() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.keyboard") {
            NSWorkspace.shared.open(url)
        }
    }
}
