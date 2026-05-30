import AppKit
import SwiftUI

/// Floating panel that hosts `SelectionActionView` just above the recording
/// overlay pill. A non-activating panel so ordering it front never steals focus
/// or clears the user's selection in the target app.
final class SelectionActionWindowController: NSWindowController {

    private let hostingController: NSHostingController<SelectionActionView>

    init(viewModel: SelectionViewModel) {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 60, height: 40),
            styleMask: [.nonactivatingPanel, .borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.level = .floating
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        hostingController = NSHostingController(rootView: SelectionActionView(viewModel: viewModel))
        super.init(window: panel)
        panel.contentViewController = hostingController
    }

    required init?(coder: NSCoder) { nil }

    /// Positions the pill centered just above `barFrame` (the overlay window's
    /// frame) and orders it front without activating Voicy.
    func show(above barFrame: NSRect) {
        guard let window else { return }
        let screen = NSScreen.screens.first { $0.frame.intersects(barFrame) } ?? NSScreen.main ?? NSScreen.screens[0]
        hostingController.view.layoutSubtreeIfNeeded()
        let size = hostingController.view.fittingSize
        window.setFrame(
            NSRect(
                x: screen.visibleFrame.midX - size.width / 2,
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
