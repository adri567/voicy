import AppKit
import Foundation

enum AppRelauncher {
    /// Startet eine neue Instanz von Voicy und beendet danach die aktuelle.
    /// `open -n` zwingt eine separate Instanz statt nur die existierende zu aktivieren.
    @MainActor
    static func relaunch() {
        let bundlePath = Bundle.main.bundlePath
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = ["-n", bundlePath]
        do {
            try process.run()
            NSApp.terminate(nil)
        } catch {
            print("[AppRelauncher] Relaunch failed: \(error)")
        }
    }
}
