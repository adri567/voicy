import AppKit
import SwiftUI

final class TranscriptPopupWindowController: NSWindowController {

    private let viewModel: RecordingViewModel

    init(viewModel: RecordingViewModel) {
        self.viewModel = viewModel
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
        super.init(window: panel)
    }

    required init?(coder: NSCoder) { nil }

    func show(above barFrame: NSRect) {
        guard let window, let screen = NSScreen.main else { return }
        let hc = NSHostingController(rootView: TranscriptPopupView(viewModel: viewModel))
        window.contentViewController = hc
        hc.view.layoutSubtreeIfNeeded()
        let size = hc.view.fittingSize
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
