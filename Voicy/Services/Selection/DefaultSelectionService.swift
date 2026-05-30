import AppKit
@preconcurrency import ApplicationServices
import Foundation
import OSLog

/// Polls the frontmost application's focused UI element for its selected text
/// via the Accessibility API. A timer-like `Task` loop on the main actor reads
/// `kAXSelectedTextAttribute` every `pollInterval` and yields a deduped
/// `SelectionState`.
///
/// Polling (rather than `kAXSelectedTextChangedNotification`) is deliberate:
/// it is uniform across apps that expose AX selection at all, handles focus and
/// app switches for free, and avoids per-app observer lifecycle. Apps that
/// don't expose `kAXSelectedTextAttribute` (many Electron/web views) simply
/// never report a selection — a graceful no-op.
@MainActor
final class DefaultSelectionService: SelectionService {

    nonisolated let selectionChanges: AsyncStream<SelectionState>
    private nonisolated let continuation: AsyncStream<SelectionState>.Continuation

    private var pollTask: Task<Void, Never>?
    private var lastState: SelectionState

    /// ~350 ms balances responsiveness against idle cost; a single AX read per
    /// tick is sub-millisecond for cooperative apps.
    private static let pollInterval: Duration = .milliseconds(350)

    /// Upper bound on a single AX request. The AX default is ~6 s, which would
    /// freeze the main actor if a target app is unresponsive. 0.25 s keeps the
    /// poll loop snappy while still succeeding for healthy apps.
    private static let axTimeout: Float = 0.25

    nonisolated init() {
        let (stream, continuation) = AsyncStream<SelectionState>.makeStream(
            bufferingPolicy: .bufferingNewest(1)
        )
        self.selectionChanges = stream
        self.continuation = continuation
        self.lastState = .none
    }

    func start() {
        guard pollTask == nil else { return }
        pollTask = Task { [weak self] in
            while !Task.isCancelled {
                self?.tick()
                try? await Task.sleep(for: Self.pollInterval)
            }
        }
    }

    func stop() {
        pollTask?.cancel()
        pollTask = nil
        emit(.none)
    }

    func currentSelection() -> SelectionState {
        Self.readSelection()
    }

    func setSelectedText(_ text: String) -> Bool {
        guard let element = Self.focusedElement() else { return false }
        let status = AXUIElementSetAttributeValue(
            element, kAXSelectedTextAttribute as CFString, text as CFTypeRef
        )
        return status == .success
    }

    private func tick() {
        emit(Self.readSelection())
    }

    private func emit(_ state: SelectionState) {
        guard state != lastState else { return }
        lastState = state
        continuation.yield(state)
    }

    // MARK: - Accessibility

    /// The focused UI element of the frontmost non-Voicy app, with a bounded
    /// messaging timeout so an unresponsive target can't stall the caller.
    private static func focusedElement() -> AXUIElement? {
        guard let app = NSWorkspace.shared.frontmostApplication,
              app.bundleIdentifier != Bundle.main.bundleIdentifier else {
            return nil
        }
        let axApp = AXUIElementCreateApplication(app.processIdentifier)
        AXUIElementSetMessagingTimeout(axApp, axTimeout)

        var focused: CFTypeRef?
        guard AXUIElementCopyAttributeValue(axApp, kAXFocusedUIElementAttribute as CFString, &focused) == .success,
              let focused else {
            return nil
        }
        return unsafeDowncast(focused, to: AXUIElement.self)
    }

    private static func readSelection() -> SelectionState {
        guard let element = focusedElement() else { return .none }

        var selected: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, kAXSelectedTextAttribute as CFString, &selected) == .success,
              let text = selected as? String else {
            return .none
        }

        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? .none : SelectionState(hasSelection: true, selectedText: text)
    }
}
