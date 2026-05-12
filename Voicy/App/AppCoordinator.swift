import AppKit
@preconcurrency import ApplicationServices
import FactoryKit
import Foundation

@MainActor
final class AppCoordinator {

    let viewModel = RecordingViewModel()
    nonisolated(unsafe) private var globalMonitor: Any?
    nonisolated(unsafe) private var previousFlags: NSEvent.ModifierFlags = []
    private var overlayController: RecordingOverlayWindowController?
    private var transcriptController: TranscriptPopupWindowController?
    private let pasteService: any PasteService = Container.shared.pasteService()

    func setup() {
        guard overlayController == nil else { return }
        let trusted = AXIsProcessTrustedWithOptions([kAXTrustedCheckOptionPrompt.takeRetainedValue(): true] as CFDictionary)
        if !trusted {
            let url = URL(string: "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_Accessibility")!
            NSWorkspace.shared.open(url)
        }
        overlayController = RecordingOverlayWindowController(viewModel: viewModel)
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
        guard viewModel.state == .idle else { return }
        transcriptController?.hide()
        viewModel.clearTranscript()
        await viewModel.toggleRecording()
    }

    private func handleFnRelease() async {
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

    deinit {
        if let monitor = globalMonitor { NSEvent.removeMonitor(monitor) }
    }
}
