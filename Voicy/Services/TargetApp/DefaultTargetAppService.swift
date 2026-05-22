import AppKit
@preconcurrency import ApplicationServices

final class DefaultTargetAppService: TargetAppService {

    nonisolated init() {}

    @MainActor
    func captureCurrent() -> TargetAppSnapshot? {
        guard let app = NSWorkspace.shared.frontmostApplication else { return nil }

        // Skip Voicy itself — if Voicy is frontmost the user hasn't focused another target yet.
        if app.bundleIdentifier == Bundle.main.bundleIdentifier {
            return nil
        }

        let windowTitle = focusedWindowTitle(for: app.processIdentifier)

        return TargetAppSnapshot(
            bundleID: app.bundleIdentifier,
            appName: app.localizedName,
            windowTitle: windowTitle
        )
    }

    private func focusedWindowTitle(for pid: pid_t) -> String? {
        let axApp = AXUIElementCreateApplication(pid)
        var focusedWindow: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(axApp, kAXFocusedWindowAttribute as CFString, &focusedWindow)
        guard result == .success, let window = focusedWindow else { return nil }

        let windowElement = unsafeDowncast(window, to: AXUIElement.self)
        var title: CFTypeRef?
        let titleResult = AXUIElementCopyAttributeValue(windowElement, kAXTitleAttribute as CFString, &title)
        guard titleResult == .success, let titleString = title as? String, !titleString.isEmpty else {
            return nil
        }
        return titleString
    }
}
