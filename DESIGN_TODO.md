# Voicy Editorial-Design — offene Implementierungen

Stand: 2026-05-12. Diese Datei listet alle Stellen auf, an denen das aktuelle UI Mock-Daten oder Demo-Toggles zeigt, die noch keine echte Backend-Anbindung haben. Quelle: Claude Design Bundle (`voicy/project/`).

Die Mock-Stellen sind im Code mit `// MOCK:` und `// TODO(...)` markiert, jeweils mit dem Tag-Namen aus der unten stehenden Tabelle.

---

## Foundation

| Tag | Status | Notiz |
|---|---|---|
| **Custom Fonts** | TODO | System-Fonts (`.system(_:design:)`) statt Lora / Inter Tight / JetBrains Mono. Visual nahe, aber nicht pixel-genau. Custom-Fonts bundeln: Fonts/-Folder + `UIAppFonts` (auf macOS: einfach in Bundle, Xcode registriert auto). |
| **VoicyLogo Asset** | ✓ Done | `Assets.xcassets/VoicyLogo.imageset` als Template-Image (rendert in Foreground-Color). |

---

## HomeView

| Tag | Status | Notiz |
|---|---|---|
| **history-filter** | MOCK | Filter-Chips ("All", "Pinned", "Whisper", "Parakeet") in `HomeView/FilterChips` — UI-only, kein Filter wird angewendet. Implementierung: `@State` für aktiven Filter, dann `entries.filter { ... }` vor Bucket-Gruppierung. |
| **paste-target** | MOCK | Spalte "Sent to {app}" zeigt nur Engine-Namen. Für echte App-Identification: vor `pasteService.paste(...)` einen Snapshot der `NSWorkspace.shared.frontmostApplication` nehmen und in `TranscriptionEntry` speichern (neue Felder: `targetAppBundleID`, `targetAppName`). Stelle: `AppCoordinator.handleFnRelease`. |
| **top-destinations** | MOCK | "Top destinations"-Liste im Stats-Panel ist hardcoded. Wird echt sobald **paste-target** geliefert hat. |
| **stats-words** | ✓ Done | Words / WPM / Minuten heute werden aus echten `TranscriptionEntry`-Daten berechnet. |

---

## EngineView

| Tag | Status | Notiz |
|---|---|---|
| **engine-catalog** | MOCK | 5 Modelle in `EngineView.models`, davon nur Whisper Small + Parakeet TDT v3 real. Distil-Whisper EN, Voicy Edge, Whisper Turbo sind Visual-Placeholders mit erfundenen Specs (size/accuracy/speed). Für echte Multi-Modell-Unterstützung müssen jeweils eigene Service-Implementierungen her. |
| **model-download** | MOCK | "Download"-Buttons triggern nichts. Echter Download bräuchte: URLSession-basierter HF-Pull, Progress-Callback (FluidAudio macht das schon, WhisperKit auch), Persistierung welche Modelle installiert sind. |
| **import-model** | MOCK | "Import model →" Button am Footer ist tot. Echte HF-URL-Import-UI fehlt. |
| **active-card-stats** | MOCK | Accuracy 94%, Latency 1.4s im "Now serving"-Block sind hardcoded je Engine. Echtes Benchmarking ist nicht trivial — kann konstant pro Modell aus Empirie fallen. |

---

## HotkeyView

| Tag | Status | Notiz |
|---|---|---|
| **hotkey-rebind** | MOCK | Trigger-Picker zeigt 5 Optionen, nur Fn ist wirklich aktiv. Echte Rebind-Logic: `AppCoordinator.registerHotkey()` muss konfigurierbar werden (KeyCode + ModifierFlags aus Settings). Bibliothek **KeyboardShortcuts** (sindresorhus) ist Standard. |
| **hotkey-mode** | MOCK | Hold / Toggle / Double-tap — nur Hold ist echt. Toggle: NSEvent flagsChanged → Tap-Down toggelt zwischen `.recording` und `.idle`. Double-Tap: Window von ~300ms zwischen zwei taps. |
| **hotkey-record** | MOCK | "Record a custom shortcut"-Button tut nichts. Braucht Eigene Recorder-UI oder die KeyboardShortcuts-Library. |
| **conflict-detection** | MOCK | "conflicts: none detected" ist statisch. macOS hat keine offizielle Conflict-Detection-API — müsste man heuristisch machen. |

---

## SettingsView

| Tag | Status | Notiz |
|---|---|---|
| **launch-at-login** | MOCK | Toggle ohne Effekt. Implementierung: `ServiceManagement.framework` → `SMAppService.mainApp.register()`. Voicy braucht dafür Entitlement und einen Login-Item-Helper-Pfad. |
| **menubar-toggle** | MOCK | Wenn off → Menu-Bar-Icon ausblenden. SwiftUI's `MenuBarExtra` lässt sich via Scene-State-Binding togglen (`isInserted`). |
| **sound-toggle** | MOCK | Start/Stop-Sound abspielen. `NSSound("Tink", currentlyPlaying: false)?.play()` in `RecordingViewModel.startRecording` / `stopAndTranscribe`. |
| **audio-input** | MOCK | Picker zeigt 3 Demo-Devices. Echt: `AVCaptureDevice.devices(for: .audio)` enumerieren + ID merken + im `AudioRecorder.start()` als `inputDeviceID` passen. |
| **sensitivity** | MOCK | Slider hat keinen Effekt. Was "trigger sensitivity" technisch bedeutet, ist nicht definiert — entfernen, oder Mapping auf VAD-Schwellwert. |
| **smart-punct** | MOCK | Toggle. Whisper macht Punktuation eh standardmäßig. Wenn off: würde Punktuation aus Output strippen. Niedrige Prio. |
| **history-toggle** | MOCK | "Save transcripts on this Mac" — wenn off, `historyService.save(...)` skippen. Einfacher Fix. |
| **usage-stats** | MOCK | Toggle für Telemetry — kein Analytics-Backend, also Mock-only. |
| **history-clear** | MOCK | "Delete all transcripts" — `modelContext.delete(model: TranscriptionEntry.self)` o.ä., einfach implementierbar. |
| **update-channel** | MOCK | Radio Stable/Beta/Manual — braucht Update-Mechanismus (Sparkle?). Komplett Eigenes Thema. |
| **updates** | MOCK | "Check for updates" Button. Selbes Thema. |
| **release-notes** | MOCK | "Release notes" Button. Verlinkt nirgendwohin. |
| **correction-enabled** | ✓ Done | KI-Korrektur-Toggle ist echt (`RecordingViewModel.correctionEnabled`). |
| **transcript-popup-toggle** | ✓ Done | Transkript-Popup-Toggle ist echt. |

---

## SnippetsView

| Tag | Status | Notiz |
|---|---|---|
| **snippets** | MOCK | Komplettes Feature ist Placeholder. Datenmodell + Trigger-Phrase-Engine + Expansion-Editor — eigener großer PR. |

---

## Side-effects bei diesem Refactor

- **Engine-Picker im Menu-Bar** ist raus (war redundant geworden, ist jetzt im Main-Window unter Engine).
- **Transcript-Toggle im Menu-Bar** ist raus (jetzt im Main-Window unter Settings → Transcription).
- **Korrektur-Toggle im Menu-Bar** bleibt (Quick-Switch). Spiegelt auch das Setting im Main-Window.
- **MainWindow** ist jetzt **`HStack` mit Custom-Sidebar** statt `NavigationSplitView`. Der Editorial-Design-Anspruch braucht Pixel-Kontrolle, die NavigationSplitView nicht liefert.

---

## Obsolet gewordene Files

Folgende Files wurden durch die neuen Section-Views ersetzt und sind **unused** (Build passt aber durch). User-Confirmation für Cleanup-Run nötig:

- `Voicy/Features/MainWindow/Sections/HistoryView.swift` — ersetzt durch `HomeView`
- `Voicy/Features/MainWindow/Sections/GeneralSettingsView.swift` — ersetzt durch `SettingsView`
- `Voicy/Features/MainWindow/Sections/EngineSettingsView.swift` — ersetzt durch `EngineView`
- `Voicy/Features/MainWindow/Sections/HotkeySettingsView.swift` — ersetzt durch `HotkeyView`
- `Voicy/Features/MainWindow/Sections/AboutView.swift` — Inhalt jetzt in `SettingsView`'s About-Card
