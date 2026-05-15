import AppKit
@preconcurrency import ApplicationServices
import FactoryKit
import Foundation

@MainActor
final class AppCoordinator {

    let viewModel = RecordingViewModel()
    let modeCycleService = Container.shared.modeCycleService()
    nonisolated(unsafe) private var globalMonitor: Any?
    nonisolated(unsafe) private var arrowKeyGlobalMonitor: Any?
    nonisolated(unsafe) private var arrowKeyLocalMonitor: Any?
    nonisolated(unsafe) private var previousFlags: NSEvent.ModifierFlags = []
    private var overlayController: RecordingOverlayWindowController?
    private var transcriptController: TranscriptPopupWindowController?
    private let pasteService: any PasteService = Container.shared.pasteService()
    private let targetAppService: any TargetAppService = Container.shared.targetAppService()

    func setup() {
        guard overlayController == nil else { return }
        let trusted = AXIsProcessTrustedWithOptions([kAXTrustedCheckOptionPrompt.takeRetainedValue(): true] as CFDictionary)
        if !trusted {
            let url = URL(string: "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_Accessibility")!
            NSWorkspace.shared.open(url)
        }
        overlayController = RecordingOverlayWindowController(viewModel: viewModel, cycle: modeCycleService)
        transcriptController = TranscriptPopupWindowController(viewModel: viewModel)
        overlayController?.show()
        registerHotkey()
    }

    private func registerHotkey() {
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            let fnPressed  = !(self?.previousFlags ?? []).contains(.function) && flags.contains(.function)
            let fnReleased = (self?.previousFlags ?? []).contains(.function) && !flags.contains(.function)
            self?.previousFlags = flags

            if fnPressed {
                Task { @MainActor [weak self] in await self?.handleFnPress() }
            } else if fnReleased {
                Task { @MainActor [weak self] in await self?.handleFnRelease() }
            }
        }
    }
    
    private func handleFnPress() async {
        guard viewModel.state == .idle
              || viewModel.state == .noModel
              || viewModel.state == .noBrain else { return }
        transcriptController?.hide()
        viewModel.clearTranscript()
        viewModel.captureTargetApp(targetAppService.captureCurrent())
        modeCycleService.resetCycle()
        installArrowKeyMonitor()
        await viewModel.toggleRecording()
    }

    private func handleFnRelease() async {
        removeArrowKeyMonitor()
        guard viewModel.state == .recording else { return }
        await viewModel.toggleRecording()
        if !viewModel.transcript.isEmpty {
            pasteService.paste(viewModel.transcript)
            if viewModel.showTranscript {
                let barFrame = overlayController?.window?.frame ?? .zero
                transcriptController?.show(above: barFrame)
            }
        }
    }

    // MARK: Arrow-key cycle during recording
    //
    // macOS transforms `fn + →` / `fn + ←` into End / Home key events at the
    // HID layer, so the keyCode we receive is 119/115 — *not* RightArrow (124) /
    // LeftArrow (123). We accept both encodings, plus a Fn+Arrow combo for
    // good measure if the user hits it inside an app that does *not* perform
    // the transform.

    private static let endKeyCode: UInt16 = 119
    private static let homeKeyCode: UInt16 = 115
    private static let rightArrowKeyCode: UInt16 = 124
    private static let leftArrowKeyCode: UInt16 = 123

    private func installArrowKeyMonitor() {
        guard arrowKeyGlobalMonitor == nil else { return }

        let handler: (NSEvent) -> NSEvent? = { [weak self] event in
            guard let self else { return event }
            let isForward  = event.keyCode == Self.endKeyCode  || event.keyCode == Self.rightArrowKeyCode
            let isBackward = event.keyCode == Self.homeKeyCode || event.keyCode == Self.leftArrowKeyCode
            guard isForward || isBackward else { return event }

            Task { @MainActor [weak self] in
                guard let self else { return }
                if isForward {
                    self.modeCycleService.cycleForward()
                } else {
                    self.modeCycleService.cycleBackward()
                }
            }
            return nil // swallow the key so we don't paste End/Home into the target app
        }

        arrowKeyGlobalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
            _ = handler(event)
        }
        arrowKeyLocalMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            handler(event)
        }
    }

    private func removeArrowKeyMonitor() {
        if let monitor = arrowKeyGlobalMonitor {
            NSEvent.removeMonitor(monitor)
            arrowKeyGlobalMonitor = nil
        }
        if let monitor = arrowKeyLocalMonitor {
            NSEvent.removeMonitor(monitor)
            arrowKeyLocalMonitor = nil
        }
    }

    deinit {
        if let monitor = globalMonitor { NSEvent.removeMonitor(monitor) }
        if let monitor = arrowKeyGlobalMonitor { NSEvent.removeMonitor(monitor) }
        if let monitor = arrowKeyLocalMonitor { NSEvent.removeMonitor(monitor) }
    }
}
