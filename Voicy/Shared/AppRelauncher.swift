import AppKit
import Foundation
import OSLog

enum AppRelauncher {
    /// Startet eine neue Instanz von Voicy und beendet danach die aktuelle.
    /// `open -n` zwingt eine separate Instanz statt nur die existierende zu aktivieren.
    ///
    /// `UserDefaults.synchronize()` ist nötig, weil `NSApp.terminate(nil)` den
    /// Prozess sonst beendet bevor pending writes (z.B. der gerade gesetzte
    /// `whisperModelID`) auf Disk gelandet sind — der Relaunch sieht dann den
    /// alten Wert und fällt auf den Default-Model zurück, der nicht installiert
    /// sein muss.
    @MainActor
    static func relaunch() {
        UserDefaults.standard.synchronize()

        let bundlePath = Bundle.main.bundlePath
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = ["-n", bundlePath]
        do {
            try process.run()
            NSApp.terminate(nil)
        } catch {
            Log.app.error("AppRelauncher: relaunch failed: \(String(describing: error), privacy: .public)")
        }
    }
}
