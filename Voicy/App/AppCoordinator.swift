import AppKit
@preconcurrency import ApplicationServices
import FactoryKit
import Foundation

@MainActor
final class AppCoordinator {

    let viewModel = RecordingViewModel()
    let modeCycleService = Container.shared.modeCycleService()

    private var overlayController: RecordingOverlayWindowController?
    private var transcriptController: TranscriptPopupWindowController?
    private let pasteService: any PasteService = Container.shared.pasteService()
    private let targetAppService: any TargetAppService = Container.shared.targetAppService()
    private let hotkey = HotkeyEventTap()
    private let arrowTap = ArrowKeyEventTap()
    
    // Gesture state machine.
    //
    //   idle           — no recording, no bubble
    //   pendingHold    — Fn was just pressed; we wait `holdDelay` before
    //                    promoting to .hold. If released first, nothing
    //                    happens. If a second press arrives within
    //                    `doubleTapWindow` of the prior release we enter
    //                    .toggle instead.
    //   hold           — push-to-talk: bubble visible while Fn is held,
    //                    on release we stop + transcribe + paste.
    //   toggle         — entered on double-Fn; bubble persists until the
    //                    next Fn press, which stops + transcribes + pastes.
    //
    // A short single tap does NOT make the bubble appear — we only show
    // the bubble once we know the gesture is genuinely a hold or a toggle.
    private enum HotkeyGesture { case idle, pendingHold, hold, toggle }
    private var gesture: HotkeyGesture = .idle
    private var lastFnReleaseTime: Date?
    private var pendingHoldTask: Task<Void, Never>?
    private static let doubleTapWindow: TimeInterval = 0.35
    // 150 ms is the floor we can go without the bubble visibly flickering for
    // accidental short taps. Higher feels sluggish; lower starts mis-firing on
    // very quick fingers. Used to be 300 ms but that felt laggy in practice.
    private static let holdDelay: TimeInterval = 0.15

    /// Sets up the recording stack (overlay, transcript popup, hotkey tap).
    /// Idempotent — safe to call from both the AppDelegate launch path and
    /// from the onboarding `practice` screen, which needs the hotkey + pill
    /// live so the user can do a real "first try" before completing setup.
    ///
    /// The earlier `onboardingCompleted` gate has been removed: `setup()`
    /// no longer triggers any permission prompts (those moved to the
    /// onboarding action buttons), and `HotkeyEventTap.enable()` simply
    /// no-ops when Accessibility isn't granted yet.
    func setup() {
        guard overlayController == nil else { return }
        overlayController = RecordingOverlayWindowController(viewModel: viewModel, cycle: modeCycleService)
        transcriptController = TranscriptPopupWindowController(viewModel: viewModel)
        overlayController?.show()
        registerHotkey()
    }

    private func registerHotkey() {
        hotkey.onFnPress = { [weak self] in
            Task { @MainActor [weak self] in
                await self?.handleFnPress()
            }
        }
        hotkey.onFnRelease = { [weak self] in
            Task { @MainActor [weak self] in
                await self?.handleFnRelease()
            }
        }
        hotkey.enable()

        arrowTap.onCycle = { [weak self] forward in
            guard let self else { return }
            if forward {
                self.modeCycleService.cycleForward()
            } else {
                self.modeCycleService.cycleBackward()
            }
        }
    }

    private func handleFnPress() async {
        // Toggle exit: any press while in toggle stops + transcribes.
        // Clearing lastFnReleaseTime here prevents this press being
        // misread as the first half of a new double-tap.
        if gesture == .toggle {
            gesture = .idle
            lastFnReleaseTime = nil
            await finishRecording()
            return
        }

        // Rescue path: an orphaned recording is active (state == .recording)
        // but the gesture machine thinks we're idle — typically the result of
        // a missed release event (CGEventTap got disabled+re-enabled) or a
        // race between model-load and release. Treat this press as a stop so
        // the user can always dismiss a stuck bubble with one Fn tap.
        if gesture == .idle, viewModel.state == .recording {
            await finishRecording()
            return
        }

        guard viewModel.state == .idle
              || viewModel.state == .noModel
              || viewModel.state == .noBrain else { return }

        let now = Date()
        let isDoubleTap = lastFnReleaseTime
            .map { now.timeIntervalSince($0) < Self.doubleTapWindow } ?? false

        // Cancel any leftover delayed-hold task from a previous press.
        pendingHoldTask?.cancel()
        pendingHoldTask = nil

        if isDoubleTap {
            // Second press of a double-tap — enter persistent toggle mode
            // immediately. Bubble appears now.
            gesture = .toggle
            await startRecordingSession()
            return
        }

        // First press of an unknown gesture. Defer the start until we
        // know whether it's a real hold or just a single tap — we don't
        // want to flash a bubble for transient taps.
        gesture = .pendingHold
        pendingHoldTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(Int(Self.holdDelay * 1000)))
            guard let self, !Task.isCancelled else { return }
            guard self.gesture == .pendingHold else { return }
            self.gesture = .hold
            await self.startRecordingSession()
        }
    }

    private func handleFnRelease() async {
        switch gesture {
        case .toggle:
            // Toggle release: nothing to do, bubble persists until next press.
            // We don't update lastFnReleaseTime — toggle exit is press-driven.
            return

        case .pendingHold:
            // Released before hold threshold — single short tap. This *is* a
            // valid double-tap candidate (first half of a potential double),
            // so record the release time for the next press to compare against.
            pendingHoldTask?.cancel()
            pendingHoldTask = nil
            gesture = .idle
            lastFnReleaseTime = Date()
            return

        case .hold:
            // A real hold ran for ≥ holdDelay — way longer than the
            // doubleTapWindow. Treating its release as a double-tap candidate
            // would mis-arm toggle mode on the next press, so clear instead.
            gesture = .idle
            lastFnReleaseTime = nil
            await finishRecording()
            return

        case .idle:
            // Press was ignored (e.g. state == .loadingModel). Do NOT update
            // lastFnReleaseTime — otherwise a subsequent legitimate press
            // once the model finished loading would be misread as the second
            // half of a double-tap and silently arm toggle mode.
            return
        }
    }

    private func startRecordingSession() async {
        transcriptController?.hide()
        viewModel.clearTranscript()
        viewModel.captureTargetApp(targetAppService.captureCurrent())
        modeCycleService.resetCycle()
        arrowTap.enable()
        SoundService.playRecordingStart()
        await viewModel.toggleRecording()
    }

    private func finishRecording() async {
        arrowTap.disable()

        // Hold-release edge case: the user is letting go *while* the model
        // is still being lazy-loaded for this very session. Without this
        // bailout the in-flight start would flip the bubble to .recording
        // moments later and leave it stranded with no way to dismiss.
        if viewModel.state == .loadingModel {
            viewModel.cancelStartIfPending()
            return
        }

        SoundService.playRecordingStop()
        await viewModel.toggleRecording()
        if !viewModel.transcript.isEmpty {
            pasteService.paste(viewModel.transcript)
            if viewModel.showTranscript {
                let barFrame = overlayController?.window?.frame ?? .zero
                transcriptController?.show(above: barFrame)
            }
        }
    }
}
