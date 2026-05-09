import AppKit
import SwiftUI

final class RecordingOverlayWindowController: NSWindowController, NSWindowDelegate {

    init(viewModel: RecordingViewModel) {
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

        let hostingController = NSHostingController(rootView: OverlayView(viewModel: viewModel))
        panel.contentViewController = hostingController

        positionAtBottomCenter()
    }

    required init?(coder: NSCoder) { nil }

    func show() {
        positionAtBottomCenter()
        window?.orderFront(nil)
    }

    func windowDidResize(_ notification: Notification) {
        positionAtBottomCenter()
    }

    private func positionAtBottomCenter() {
        guard let screen = NSScreen.main, let window else { return }
        let screenFrame = screen.visibleFrame
        window.setFrameOrigin(NSPoint(
            x: screenFrame.midX - window.frame.width / 2,
            y: screenFrame.minY + 20
        ))
    }
}
