import AppKit
import Foundation

/// Low-level CGEventTap that swallows the four cycle-arrow keys while a
/// recording session is active.
///
/// macOS transforms `fn + →` / `fn + ←` into End / Home at the HID layer,
/// so we accept both encodings (115/119 for Home/End, 123/124 for Left/Right
/// for apps that don't perform the fn transform).
///
/// Uses `.defaultTap` (not `.listenOnly`) so returning `nil` from the
/// callback actually drops the event before it reaches the focused app —
/// this is the entire point of using a CGEventTap over NSEvent's global
/// monitor, which can only observe.
@MainActor
final class ArrowKeyEventTap {

    var onCycle: ((Bool) -> Void)?

    nonisolated private static let endKeyCode: Int64 = 119
    nonisolated private static let homeKeyCode: Int64 = 115
    nonisolated private static let rightArrowKeyCode: Int64 = 124
    nonisolated private static let leftArrowKeyCode: Int64 = 123

    nonisolated(unsafe) private var tap: CFMachPort?
    nonisolated(unsafe) private var runLoopSource: CFRunLoopSource?

    func enable() {
        guard tap == nil else { return }

        let mask = CGEventMask(1 << CGEventType.keyDown.rawValue)
        let selfPointer = Unmanaged.passUnretained(self).toOpaque()

        let callback: CGEventTapCallBack = { _, type, event, refcon in
            guard let refcon else { return Unmanaged.passRetained(event) }
            let owner = Unmanaged<ArrowKeyEventTap>.fromOpaque(refcon).takeUnretainedValue()
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
            print("[ArrowKeyEventTap] tap creation failed — Accessibility permission missing?")
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

    nonisolated private func handleFromCallback(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            MainActor.assumeIsolated {
                if let tap = self.tap {
                    CGEvent.tapEnable(tap: tap, enable: true)
                }
            }
            return Unmanaged.passRetained(event)
        }
        guard type == .keyDown else {
            return Unmanaged.passRetained(event)
        }

        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        let isForward  = keyCode == Self.endKeyCode  || keyCode == Self.rightArrowKeyCode
        let isBackward = keyCode == Self.homeKeyCode || keyCode == Self.leftArrowKeyCode
        guard isForward || isBackward else {
            return Unmanaged.passRetained(event)
        }

        MainActor.assumeIsolated {
            self.onCycle?(isForward)
        }
        return nil
    }
}
