# Session Summary

## Context
Voicy ist eine native macOS Menu Bar App (Swift/SwiftUI) für Voice-to-Text. Der User hält Fn gedrückt um aufzunehmen, lässt los → WhisperKit transkribiert → Text wird per Accessibility API / Cmd+V ins fokussierte Textfeld eingefügt. Ziel ist ein kommerzielles Produkt (Freemium + Abo). Aktueller Fokus: Phase 1 MVP — kein LLM.

**Tech Stack:** SwiftUI, MVVM, Factory DI, WhisperKit, Swift 6, macOS 26.2+

---

## Current State

### Vollständig fertig
- **Paste-Service** (`DefaultPasteService`): Clipboard + Cmd+V, funktioniert in allen Apps (Chrome, Electron, Terminal, native). `captureTarget()` entfernt, da Panels non-activating sind.
- **Audio-reaktive Waveform**: `AVAudioRecorder` mit `isMeteringEnabled`, Polling alle 60ms im ViewModel, exponentieller Glättungsfilter (70/30). `AnimatedWaveform` skaliert Amplitude per `level: Float` Parameter.
- **Transcribing-Animation**: `TranscribingDotsView` — 3 sequenziell pulsierende Punkte via `TimelineView`, gleiche Pill-Größe wie Recording-State (46×17pt Frame).
- **Overlay-Animationen**: `.spring(response: 0.45, dampingFraction: 0.72)` + `.scale(0.75, anchor: .bottom).combined(with: .opacity)` Transition auf jedem State — weiche Ein-/Ausblendungen.
- **Dev-Mode-Toggle**: `showTranscript: Bool` in `RecordingViewModel` (UserDefaults-persistent), Toggle-Button im Menü. Default: aus (stilles Pasten). Beim Einschalten erscheint Transcript-Popup nach jeder Transkription.
- **Multi-Monitor-Support**: `RecordingOverlayWindowController` trackt Mausposition alle 150ms via Timer, wechselt Screen automatisch wenn Maus auf anderen Monitor wandert. `TranscriptPopupWindowController` leitet Screen aus Overlay-Frame ab.
- **Folder-Struktur**: Bereinigt gemäß CLAUDE.md — `Features/Overlay/` aufgelöst, alle Overlay-Dateien in `Features/Recording/`.
- **Code-Cleanup**: `RecordingView.swift` (dead code, Tippfehler im Struct-Namen) gelöscht, `errorMessage` komplett entfernt.

### Bekannte Compiler-Warnungen (keine echten Fehler)
- SourceKit meldet sporadisch `No such module 'FactoryKit'`, `No such module 'WhisperKit'`, `Cannot find type 'RecordingViewModel' in scope` — stale Index, löst sich beim Build in Xcode.
- `[Aufregende Musik]` wurde vom Linter in `deinit` von `RecordingOverlayWindowController` eingefügt (Zeile 60) — muss entfernt werden.

### Offen / nicht implementiert
- Tests fehlen für alle neuen Features (PasteService, AudioLevel-Polling, Screen-Tracking)
- Kein Commit seit dem Initial Commit

---

## Key Decisions

| Entscheidung | Begründung |
|---|---|
| Paste via Clipboard + Cmd+V (nicht AXInsertText) | AXInsertText funktioniert nur in nativen AppKit-Feldern (~20% der Apps). Cmd+V ist universell. |
| AudioLevel-Polling im ViewModel (nicht im Service) | ViewModel koordiniert bereits den State; polling via `Task` mit 60ms-Intervall ist sauber und cancellable. |
| `nonisolated(unsafe)` für stored properties | Projekt nutzt `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`. Factory-Closures und `deinit` sind `nonisolated` — `nonisolated(unsafe)` ist der etablierte Workaround im Projekt. |
| Screen-Tracking via Timer (150ms) statt NSEvent.mouseMoved | `mouseMoved` feuert zu oft (jeder Frame). Timer mit Screen-Change-Check ist effizient — `setFrameOrigin` wird nur bei echtem Screen-Wechsel aufgerufen. |
| `PBXFileSystemSynchronizedRootGroup` | Projekt nutzt automatische Ordner-Synchronisierung — neue Dateien werden ohne `project.pbxproj`-Änderungen erkannt. |

---

## Open Questions
- Hotkey-Trigger: Double-Command als Alternative zu Fn? (macOS-Konflikte möglich)
- App Store vs. Direct Distribution
- Latenz-Ziel (ms) für Transkription
- WhisperKit Modell-Distribution für Produktion (Bundle vs. Download)
- Tests für neue Features schreiben?

---

## Next Steps
1. **Linter-Artifact fixen**: `[Aufregende Musik]` in `RecordingOverlayWindowController.swift` Zeile 60 im `deinit` entfernen
2. **Testen**: App bauen und alle Features manuell verifizieren — Paste in verschiedenen Apps, Audio-reaktive Waveform, Screen-Wechsel, Dev-Mode-Toggle
3. **Commit**: Alle Änderungen seit Initial Commit committen (viele unstaged changes)
4. **Tests schreiben**: PasteService, AudioLevel-Polling, Screen-Tracking
5. **Phase 2 planen**: Gemma 2B via MLX-Swift, Text-Cleanup, LLM-Modi
