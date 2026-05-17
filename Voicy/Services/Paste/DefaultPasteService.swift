import AppKit
import CoreGraphics

final class DefaultPasteService: PasteService {

    nonisolated init() {}

    func paste(_ text: String) {
        let pb = NSPasteboard.general
        let saved = pb.string(forType: .string)
        pb.clearContents()
        pb.setString(text, forType: .string)
        postCmdV()
        // Restore the user's previous clipboard *after* the paste has had time
        // to land in the target app. 300 ms was too tight — slow apps (Chrome,
        // some Electron clients) sometimes processed the Cmd+V *after* we'd
        // already restored, so the user got their old clipboard pasted instead
        // of the transcript. 1.2 s is a comfortable margin.
        //
        // Additionally, only restore if our text is still on the clipboard.
        // If the user copied something else in the meantime, leave it alone.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            guard pb.string(forType: .string) == text else { return }
            pb.clearContents()
            if let saved { pb.setString(saved, forType: .string) }
        }
    }

    private func postCmdV() {
        let src = CGEventSource(stateID: .hidSystemState)
        let keyDown = CGEvent(keyboardEventSource: src, virtualKey: 0x09, keyDown: true)
        let keyUp   = CGEvent(keyboardEventSource: src, virtualKey: 0x09, keyDown: false)
        keyDown?.flags = .maskCommand
        keyUp?.flags   = .maskCommand
        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
    }
}
