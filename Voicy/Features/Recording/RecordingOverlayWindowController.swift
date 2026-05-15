import AppKit
import SwiftUI

final class RecordingOverlayWindowController: NSWindowController, NSWindowDelegate {

    nonisolated(unsafe) private var lastScreen: NSScreen?
    nonisolated(unsafe) private var screenTracker: Timer?

    init(viewModel: RecordingViewModel, cycle: ModeCycleService) {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 200, height: 6),
            styleMask: [.nonactivatingPanel, .borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.level = .floating
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        super.init(window: panel)

        panel.delegate = self

        let hostingController = NSHostingController(
            rootView: OverlayView(viewModel: viewModel, cycle: cycle)
        )
        panel.contentViewController = hostingController

        positionAtBottomCenter()
    }

    required init?(coder: NSCoder) { nil }

    func show() {
        positionAtBottomCenter()
        window?.orderFront(nil)
        screenTracker = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.trackScreenIfNeeded()
            }
        }
    }

    func windowDidResize(_ notification: Notification) {
        positionAtBottomCenter()
    }

    private func trackScreenIfNeeded() {
        let current = NSScreen.screens.first { $0.frame.contains(NSEvent.mouseLocation) }
        guard current !== lastScreen else { return }
        positionAtBottomCenter()
    }

    private func positionAtBottomCenter() {
        let screen = NSScreen.screens.first { $0.frame.contains(NSEvent.mouseLocation) } ?? NSScreen.main
        guard let screen, let window else { return }
        lastScreen = screen
        let f = screen.visibleFrame
        window.setFrameOrigin(NSPoint(x: f.midX - window.frame.width / 2, y: f.minY + 20))
    }

    deinit {
        screenTracker?.invalidate()
    }
}
