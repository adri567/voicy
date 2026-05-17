import AppKit
@preconcurrency import ApplicationServices
import FactoryKit
import Foundation

@MainActor
final class AppCoordinator {

    let viewModel = RecordingViewModel()
    let modeCycleService = Container.shared.modeCycleService()

    // NSEvent monitor tokens are accessed from the synchronous deinit (which is
    // non-isolated for @MainActor classes); marking them nonisolated(unsafe) is
    // the documented Apple pattern for this AppKit interop case. The tokens are
    // only ever set/cleared on MainActor methods, so there is no real race.
    nonisolated(unsafe) private var arrowKeyGlobalMonitor: Any?
    nonisolated(unsafe) private var arrowKeyLocalMonitor: Any?

    private var overlayController: RecordingOverlayWindowController?
    private var transcriptController: TranscriptPopupWindowController?
    private let pasteService: any PasteService = Container.shared.pasteService()
    private let targetAppService: any TargetAppService = Container.shared.targetAppService()
    private let hotkeyTap = HotkeyEventTap()
    
    // Gesture state for double-tap toggle. A second Fn press inside
    // `doubleTapWindow` after a previous release arms the persistent
    // toggle-recording mode. The bubble stays open until the next single
    // Fn press exits it. We can intercept Fn cleanly because the
    // HotkeyEventTap swallows the system's default Character Viewer
    // trigger — without that the OS would steal double-Fn.
    private var lastFnReleaseTime: Date?
    private var currentPressStartTime: Date?
    private var isToggleRecording: Bool = false
    private static let doubleTapWindow: TimeInterval = 0.35
    private static let tapDiscardThreshold: TimeInterval = 0.25

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
        hotkeyTap.onFnPress = { [weak self] in
            Task { @MainActor [weak self] in
                await self?.handleFnPress()
            }
        }
        hotkeyTap.onFnRelease = { [weak self] in
            Task { @MainActor [weak self] in
                await self?.handleFnRelease()
            }
        }
        hotkeyTap.enable()
    }

    private func handleFnPress() async {
        // Exit path for toggle mode: any Fn press while a toggle recording
        // is active stops + transcribes. We branch on this first so a
        // single tap is never re-interpreted as the start of a new gesture.
        if viewModel.state == .recording && isToggleRecording {
            isToggleRecording = false
            removeArrowKeyMonitor()
            await viewModel.toggleRecording()
            lastFnReleaseTime = Date()
            if !viewModel.transcript.isEmpty {
                pasteService.paste(viewModel.transcript)
                if viewModel.showTranscript {
                    let barFrame = overlayController?.window?.frame ?? .zero
                    transcriptController?.show(above: barFrame)
                }
            }
            return
        }

        guard viewModel.state == .idle
              || viewModel.state == .noModel
              || viewModel.state == .noBrain else { return }

        let now = Date()
        let isDoubleTap = lastFnReleaseTime
            .map { now.timeIntervalSince($0) < Self.doubleTapWindow } ?? false

        transcriptController?.hide()
        viewModel.clearTranscript()
        viewModel.captureTargetApp(targetAppService.captureCurrent())
        modeCycleService.resetCycle()
        installArrowKeyMonitor()
        currentPressStartTime = now
        isToggleRecording = isDoubleTap
        await viewModel.toggleRecording()
    }

    private func handleFnRelease() async {
        // In toggle mode, releasing the key does nothing — the recording
        // is held until the next single Fn press exits it (handled above).
        if isToggleRecording { return }

        let pressDuration = currentPressStartTime
            .map { Date().timeIntervalSince($0) } ?? 0
        currentPressStartTime = nil
        // Always update release time — the second tap of a double-tap
        // needs to see this timestamp to detect itself.
        lastFnReleaseTime = Date()

        guard viewModel.state == .recording else { return }

        // Too short to be a real hold — likely tap #1 of a double-tap or
        // an accidental brush. Drop the audio so nothing gets pasted.
        if pressDuration < Self.tapDiscardThreshold {
            removeArrowKeyMonitor()
            await viewModel.discardRecording()
            return
        }

        removeArrowKeyMonitor()
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

        // Capture a MainActor-bound cycle action so the AppKit callback (which
        // runs nonisolated) only needs to dispatch it.
        let onCycle: @MainActor @Sendable (Bool) -> Void = { [weak self] forward in
            guard let self else { return }
            if forward {
                self.modeCycleService.cycleForward()
            } else {
                self.modeCycleService.cycleBackward()
            }
        }

        arrowKeyGlobalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
            let isForward  = event.keyCode == Self.endKeyCode  || event.keyCode == Self.rightArrowKeyCode
            let isBackward = event.keyCode == Self.homeKeyCode || event.keyCode == Self.leftArrowKeyCode
            guard isForward || isBackward else { return }
            Task { @MainActor in onCycle(isForward) }
        }
        arrowKeyLocalMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            let isForward  = event.keyCode == Self.endKeyCode  || event.keyCode == Self.rightArrowKeyCode
            let isBackward = event.keyCode == Self.homeKeyCode || event.keyCode == Self.leftArrowKeyCode
            guard isForward || isBackward else { return event }
            Task { @MainActor in onCycle(isForward) }
            return nil // swallow the key so we don't paste End/Home into the target app
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
        if let monitor = arrowKeyGlobalMonitor { NSEvent.removeMonitor(monitor) }
        if let monitor = arrowKeyLocalMonitor { NSEvent.removeMonitor(monitor) }
    }
}
