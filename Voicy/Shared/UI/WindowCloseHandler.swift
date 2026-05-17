import AppKit
import SwiftUI

/// Invisible AppKit bridge that observes `NSWindow.willCloseNotification` on
/// the host window and forwards it to a SwiftUI closure. Used by the
/// onboarding host to terminate the app when the user closes the window
/// before completing the flow.
struct WindowCloseHandler: NSViewRepresentable {

    let onClose: () -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onClose: onClose) }

    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        DispatchQueue.main.async { [weak view] in
            guard let window = view?.window else { return }
            context.coordinator.attach(to: window)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}

    final class Coordinator {
        private let onClose: () -> Void

        // Notification token must be released from the nonisolated deinit.
        // NSObjectProtocol is not Sendable; this property is only mutated on
        // MainActor (in `attach`) so the race-free invariant holds.
        nonisolated(unsafe) private var token: NSObjectProtocol?

        init(onClose: @escaping () -> Void) {
            self.onClose = onClose
        }

        func attach(to window: NSWindow) {
            guard token == nil else { return }
            token = NotificationCenter.default.addObserver(
                forName: NSWindow.willCloseNotification,
                object: window,
                queue: .main
            ) { [onClose] _ in onClose() }
        }

        deinit {
            if let token { NotificationCenter.default.removeObserver(token) }
        }
    }
}
