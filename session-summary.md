# Session Summary

## Context
Voicy ist eine native macOS Menu Bar App (Swift 6.2 / SwiftUI, macOS 26.2+) für Voice-to-Text mit WhisperKit + Parakeet (FluidAudio) als Transcription-Engines und MLX-Swift (Gemma) für LLM-Post-Processing. Phase 1 (Mic-Pipeline), Phase 2 (Modi + Snippets + Brain + separate Transcribe-Page mit FileHistory) und Phase 3 (Diarization, mit Quality-Caveats) sind live. Diese Session: Phase-3-Commit, eine vollständige Übersicht aller offenen Themen, und ein größerer Hotkey-Refactor — von hardcoded Fn-Hold mit Mock-Settings hin zu einem **CGEventTap-basierten Fn-Capture mit Double-Tap-Toggle-Geste**.

---

## Current State

### Vollständig fertig + committed + gepusht

**`21fccb0` add speaker diarization via FluidAudio LS-EEND**
- Phase 3 (Diarization) Code aus vorheriger Session committed
- `TranscriptionSegment.speaker: Int?`, neuer `DiarizationSegment`-Type
- `DiarizationService` Protocol + `FluidAudioDiarizationService` Actor (LS-EEND, .cpuOnly)
- Pipeline: parallel zur Transkription via `async let` in `TranscribeViewModel.runFullPipeline`
- UI: Speaker-Toggle, „Speaker N"-Tags, Conversation-View, `DiarizationModelCard` in EngineView
- Memory: `phase3_diarization.md` aktualisiert (Sortformer→LS-EEND korrigiert), neue Memory `diarization_quality_paths.md` für die drei dokumentierten Verbesserungspfade

**`213d285` intercept Fn via CGEventTap, add double-tap toggle gesture**
- `HotkeyEventTap.swift` (NEU) — CGEventTap auf `cgSessionEventTap`, schluckt Fn-Transitions damit macOS NICHT mehr den Char-Viewer öffnet. Re-enabled sich selbst bei `tapDisabledByTimeout/UserInput`. Kapselt CFRunLoop-Source, MainActor.assumeIsolated im C-Callback-Pfad.
- `AppCoordinator` — NSEvent-flagsChanged-Monitor raus, HotkeyEventTap rein. Double-Fn-Detection (350ms Window) + Tap-Discard für Press <250ms.
- `TranscriptionService.cancelRecording()` neu im Protocol + beide Service-Implementierungen (`DefaultTranscriptionService`, `ParakeetTranscriptionService`). Macht nur `recorder.stop()` ohne Inference, damit `state` instant auf `.idle` flippt und der zweite Double-Tap nicht durch die Race verloren geht.
- `RecordingViewModel.discardRecording()` — nutzt jetzt das schnelle `cancelRecording()` statt des langsamen `stopAndTranscribe`.
- `HotkeyView` — komplett zu Info-Display umgebaut. Drei Gesture-Cards (Hold / Double-tap / Fn+Arrows). Keine interaktiven Mocks mehr.
- `HotkeyGestureCard.swift` (NEU) — Read-only-Card-Komponente.
- `KeyboardVisualization` vereinfacht (Fn fest highlighted, kein `TriggerOption`-Parameter mehr).
- **Gelöscht** (mit User-Confirm): `TriggerOption.swift`, `HotkeyMode.swift`, `HotkeyModeCard.swift`.
- Alle drei `TODO(hotkey-*)`-Marker sind weg.

### Vom User noch zu verifizieren

- **Char-Viewer-Suppression:** Fn in einem Textfeld drücken sollte nicht mehr den Emoji-Picker öffnen. Falls doch → Tap-Layer wechseln auf `.cghidEventTap`.
- **Double-Tap-Toggle:** Zwei schnelle Fn-Taps → Bubble bleibt → Fn-Single beendet.
- **Discard-Fix:** Sehr kurzer Single-Tap → kein leeres Transkript-Paste.

### Bekannte offene Issues (alle dokumentiert in Memory)

- **LS-EEND Diarization-Qualität mau** — drei Pfade in `diarization_quality_paths.md` (Pfad 1: `mergeSpeakers`-Smoothing; Pfad 2: Sortformer-Bug fixen; Pfad 3: Pyannote via ONNX).
- **Whisper-File-Casing** — File-Transkription liefert lowercase ohne Punctuation. Memory `whisper_file_casing_open.md` mit Sackgassen aus letzter Session. Next-Step laut Memory: Modellwechsel auf Small/Medium statt Large-v3-quantized.
- **Phase 3.5 Speaker-Edit** — Speaker-Namen editierbar machen via eigenes Mapping pro `FileTranscriptionEntry`.

---

## Key Decisions

| Entscheidung | Begründung |
|---|---|
| Statt Fn+Ctrl → CGEventTap + Double-Fn | Fn+Ctrl war Notlösung gegen macOS-Char-Viewer-Konflikt. Wenn wir CGEventTap eh einführen, voll umbauen — Double-Fn ist die intuitivere Geste, Fn+Ctrl wäre Verkaufsnachteil ggü. Wispr Flow. |
| `cancelRecording()` als echte Service-Methode | Statt `stopAndTranscribe()` + Result-Discard. Whisper-Inference dauert 500ms-1s, das hat die Double-Tap-Detection gebrochen — der zweite Tap kam bevor state wieder `.idle` war. Echtes Cancel ist instant. |
| `.cgSessionEventTap` statt `.cghidEventTap` | Session-Level reicht für unsere Use-Case, braucht nur Accessibility (haben wir schon), nicht Input-Monitoring extra. Falls Char-Viewer doch durchkommt → Eskalations-Pfad auf `.cghidEventTap`. |
| `MainActor.assumeIsolated` im CGEventTap-Callback | CFRunLoop-Callbacks auf Main-Thread sind faktisch MainActor, Swift kann's über C-Boundary nur nicht beweisen. `assumeIsolated` ist Apples empfohlener Pattern. |
| Tap schluckt NUR Fn-Transitions | Andere Modifier (Shift, Ctrl, Cmd) dürfen passieren — sonst würden wir System-Shortcuts in anderen Apps brechen. Check: `fnDown != fnIsDown` als Edge-Detector. |
| HotkeyView nicht konfigurierbar, sondern Info-Display | User-Entscheidung: Fn fest, keine User-Customization. Settings-Section wäre dann nur Mock — also umbauen zu Read-only-Erklärung. |
| `discardRecording()` löscht auch `pendingTargetApp` | Damit das Target-App-Snapshot nicht in den nächsten Recording-Cycle leakt. |

---

## Open Questions

- **CGEventTap-Verifikation:** Funktioniert der Char-Viewer-Block tatsächlich? Falls nein → Umstieg auf `.cghidEventTap`, evtl. plus `NSInputMonitoringUsageDescription` in den INFOPLIST-Build-Settings.
- **Diarization-Qualität:** Welcher der drei dokumentierten Pfade soll als nächstes angegangen werden? `mergeSpeakers`-Smoothing ist der billigste Probier-Step.
- **Whisper-File-Casing:** Modellwechsel auf Small/Medium wann?
- **Settings-Mocks aufräumen:** 9 `isMock: true` Toggles in SettingsView (Launch-at-login, MenuBar-Toggle, Sound, Audio-Input-Picker, Sensitivity, History-Toggle, Usage-Stats, Update-Channel, Smart-Punct). Reihenfolge / Priorität?
- **Pricing + App Store vs Direct (Phase 4):** Unverändert offen.
- **App Name:** Unverändert offen.

---

## Next Steps

1. **User testet Hotkey-Build live** — Char-Viewer-Suppression, Double-Tap-Toggle, Discard. Falls Char-Viewer doch durchkommt → `.cghidEventTap` umbauen.
2. **Diarization-Quality angehen** — Pfad 1 (mergeSpeakers-Smoothing) als günstigste Wette, dann ggf. Pfad 2 (Sortformer-Fix).
3. **Whisper-Casing wieder aufnehmen** — Small/Medium-Modell als Erstes testen.
4. **Settings-Mocks ausverdrahten** — Launch-at-Login + History-Toggle sind die Low-Hanging-Fruits (echtes Preferences-Persisting), Audio-Input-Picker braucht AVAudioEngine-Code.
5. **Updates-Pfad** — Check-for-updates / Release-Notes / Update-Channel sind komplett ungewired. Sparkle integrieren? Eigener Mini-Updater?
6. **Phase 3.5 Speaker-Edit** — `SpeakerName`-Mapping-Struct pro `FileTranscriptionEntry`.
7. **Phase 2 Restfeatures aus Notion** — AI Pointer (Cursor-Kontext + Voice-Command), System Actions (App/URL öffnen).
8. **Phase 4 Produktthemen** — App Name, Pricing, App Store vs Direct, WhisperKit-Modell-Bundling-Strategie.
