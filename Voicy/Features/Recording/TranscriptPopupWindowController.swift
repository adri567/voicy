import AppKit
import SwiftUI

final class TranscriptPopupWindowController: NSWindowController {

    private let hostingController: NSHostingController<TranscriptPopupView>

    init(viewModel: RecordingViewModel) {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 360, height: 200),
            styleMask: [.nonactivatingPanel, .borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.level = .floating
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        hostingController = NSHostingController(rootView: TranscriptPopupView(viewModel: viewModel))
        super.init(window: panel)
        panel.contentViewController = hostingController
    }

    required init?(coder: NSCoder) { nil }

    func show(above barFrame: NSRect) {
        guard let window else { return }
        let screen = NSScreen.screens.first { $0.frame.intersects(barFrame) } ?? NSScreen.main ?? NSScreen.screens[0]
        hostingController.view.layoutSubtreeIfNeeded()
        let size = hostingController.view.fittingSize
        window.setFrame(
            NSRect(
                x: screen.visibleFrame.midX - 180,
                y: barFrame.maxY + 12,
                width: size.width,
                height: size.height
            ),
            display: false
        )
        window.orderFront(nil)
    }

    func hide() {
        window?.orderOut(nil)
    }
}
