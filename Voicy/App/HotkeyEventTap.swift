import AppKit
import Foundation

/// Low-level CGEventTap that observes the Fn modifier globally.
///
/// Tries to swallow the event (return `nil`) on Fn transitions so the
/// system Character Viewer never opens — but `.cgSessionEventTap` fires
/// after macOS has already routed Fn to its system handler on modern
/// versions, so the picker may still appear. Hotkey detection works
/// reliably regardless; suppression is best-effort.
@MainActor
final class HotkeyEventTap {

    var onFnPress: (() -> Void)?
    var onFnRelease: (() -> Void)?

    // The CFMachPort + run-loop source must be reachable from `deinit`,
    // which is nonisolated for @MainActor classes — same pattern as the
    // NSEvent tokens in AppCoordinator.
    nonisolated(unsafe) private var tap: CFMachPort?
    nonisolated(unsafe) private var runLoopSource: CFRunLoopSource?
    private var fnIsDown: Bool = false

    func enable() {
        guard tap == nil else { return }

        let mask = CGEventMask(1 << CGEventType.flagsChanged.rawValue)
        let selfPointer = Unmanaged.passUnretained(self).toOpaque()

        let callback: CGEventTapCallBack = { _, type, event, refcon in
            guard let refcon else { return Unmanaged.passUnretained(event) }
            let owner = Unmanaged<HotkeyEventTap>.fromOpaque(refcon).takeUnretainedValue()
            return owner.handleFromCallback(type: type, event: event)
        }

        guard let newTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: callback,
            userInfo: selfPointer
        ) else {
            print("[HotkeyEventTap] tap creation failed — Accessibility permission missing?")
            return
        }

        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, newTap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: newTap, enable: true)

        self.tap = newTap
        self.runLoopSource = source
    }

    func disable() {
        if let tap { CGEvent.tapEnable(tap: tap, enable: false) }
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }
        tap = nil
        runLoopSource = nil
    }

    deinit {
        if let tap { CGEvent.tapEnable(tap: tap, enable: false) }
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }
    }

    /// Called from the tap's CFRunLoop callback. Because the source was
    /// added to the main run loop, this runs on the main thread — which is
    /// the MainActor's thread, but Swift can't prove that across the C
    /// callback boundary. We assume MainActor isolation explicitly.
    nonisolated private func handleFromCallback(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            // System suspended us (typical when our callback was slow). Just
            // re-enable and let this particular event through.
            MainActor.assumeIsolated {
                if let tap = self.tap {
                    CGEvent.tapEnable(tap: tap, enable: true)
                }
            }
            return Unmanaged.passUnretained(event)
        }
        guard type == .flagsChanged else {
            return Unmanaged.passUnretained(event)
        }

        let fnDown = event.flags.contains(.maskSecondaryFn)
        let isFnTransition = MainActor.assumeIsolated {
            self.dispatchTransition(fnDown: fnDown)
        }
        // Best-effort: swallow Fn transitions so other apps don't see them.
        // The system Character Viewer may still trigger on macOS 14+ because
        // .cgSessionEventTap runs after that routing decision.
        return isFnTransition ? nil : Unmanaged.passUnretained(event)
    }

    private func dispatchTransition(fnDown: Bool) -> Bool {
        guard fnDown != fnIsDown else { return false }
        fnIsDown = fnDown
        if fnDown {
            onFnPress?()
        } else {
            onFnRelease?()
        }
        return true
    }
}
