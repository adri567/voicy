# Session Summary

## Context

Voicy ist eine native macOS App (Swift 6.2 / SwiftUI, macOS 26.2+) für Voice-to-Text mit WhisperKit + Parakeet als Transcription-Engines und MLX-Swift (Gemma & Co.) als LLM für Post-Processing. Diese Session hatte zwei große Stränge:

1. **Onboarding wirklich nutzbar machen** — Engine- und Brain-Downloads waren entweder schlecht verkabelt (Model-Auto-Download verwirrend) oder reines UI-Mock (Brain-Screen). Plus PracticeScreen, der nicht funktionierte. Plus zwischen Onboarding und MainWindow nicht klar persistierte Engine-Wahl, die das ViewModel auf den falschen Service laufen ließ.
2. **Diverse Recording-Bugs fixen + Polish** — stuck pill nach Model-Load-Race, paste-race mit altem Clipboard, hardcoded German in beiden Engines, sound-leak ins Mikrofon, fehlende Mode-Switch-Animation.

Die App ist jetzt eine Dock-App (war Menubar-only mit `LSUIElement = YES`) — User soll beim ersten Start direkt ins Onboarding-Window kommen.

## Current State

### Committed (commit `3b5b9c1`, gepushed)
- **Onboarding**: Engine- und Brain-Downloads echt verkabelt mit progress bars + 100% Continue-Gate. `selectAndDownloadBrain` analog zu `selectAndDownloadModel`. Brain-Catalog auf 5 echte MLX registryKeys (Gemma 2B/4B, Mistral, Qwen, Llama). Engine-Choice direkt in `persistEngineChoice` persistiert bei Karten-Klick (statt erst am Onboarding-Ende). Nach Install wird per `loadAfterInstall` der App-Singleton-Service warm gemacht — kein lazy-load mehr beim ersten Fn-Press.
- **PracticeScreen**: TextEditor mit FocusState + auto-focus → Voicy's Cmd+V landet im Notepad. Live-Status aus `viewModel.state`.
- **Recording-Fixes**: `cancelStartIfPending` + `bailIfCanceled` gegen orphan `.recording`-Sessions wenn Release während Lazy-Load. `startInProgress`-Guard gegen Re-entry. `holdDelay` von 300 ms → 150 ms. Rescue-Path im `handleFnPress` für stuck-pill-Recovery. Paste-Race: Restore-Delay 300 ms → 1.2 s + content-check.
- **App-Lifecycle**: `LSUIElement` entfernt → reguläre Dock-App. `setup()` läuft ab Launch, idempotent, ohne `onboardingCompleted`-Gate. `viewModel.service` als computed property (statt `@Injected`) — engine-switch ohne App-Restart. `reloadActiveModel()` nach Onboarding-Finish.
- **Language**: `TranscriptionService.stopAndTranscribe(language:)` — Whisper und Parakeet respektieren jetzt die aktive Sprache statt hardcoded German.
- **Permissions**: lazy reads, denied → System Settings öffnen + polling. FnKey-Screen mit "Open Keyboard Settings"-Button immer sichtbar.

### Uncommitted (in dieser Session danach)
- **Sounds** (`SoundService.swift`): drei Events — `Purr` für Start (0.25 Volume), `Pop` für Stop (0.25), `Morse` für Mode-Switch (0.08, deutlich leiser). NSSound-Cache mit `stop()` vor `play()` für zuverlässigen Retrigger. Respektiert `clickSounds`-Toggle, default-on.
- **Audio-Crop** (`AudioRecorder.swift`): erste und letzte 200 ms werden weggeschnitten — gegen UI-Sound-Leak in Mic.
- **Warning-Text in OverlayView**: gelb → weiß für "No voice model installed" und "No AI model installed".
- **Mode-Switch-Animation** (Droplet): Custom `AnyTransition.modifier` mit `Animatable`-Konformanz (sonst snapped's). Bouncier Spring (response 0.5, dampingFraction 0.5). `.id(cycle.activeMode.id)` zwingt SwiftUI zu removal+insertion.

### Offen / unverifiziert
- **Droplet-Animation visuell**: User berichtete sie funktioniere nicht, danach Animatable-Konformanz + sichtbarere Spring eingebaut. Ungetestet.
- **Whisper-File-Casing** (von früherer Session geparkt).
- **Diarization-Quality mau** (geparkt).
- **9 `isMock: true`-Toggles in SettingsView** noch nicht funktional.

## Key Decisions

| Entscheidung | Begründung |
|---|---|
| `viewModel.service` als computed property statt `@Injected` | `@Injected` cached den Service beim ViewModel-Init — also vor der Engine-Wahl im Onboarding. Computed property resolved bei jedem Zugriff aus `TranscriptionEngine.current` → live engine-switch ohne App-Relaunch. |
| `setup()` ohne `onboardingCompleted`-Gate | `setup()` triggert keine Permission-Prompts mehr (die wurden in die Onboarding-Buttons verlagert) und ist idempotent. PracticeScreen braucht den Hotkey-Tap aktiv, bevor Onboarding abgeschlossen ist. |
| `LSUIElement`-Key **komplett entfernt** (statt `NO` setzen) | Eindeutig — `NO` kann von macOS Launch Services gecached werden und die App taucht als Accessory auf. Ohne Key ist die Standard-GUI-App-Semantik garantiert. |
| Brain-Catalog auf 5 echte registryKeys + Gemma 2B als recommended | Catalog war vorher Mock mit Phantasie-IDs (`phi35`, `qwen14b`) die im MLXTextCorrectionService gar nicht existieren. Jetzt deckungsgleich mit `BrainView` und `supportedRegistryKeys`. Gemma 2B = Default-Brain = recommended. |
| Brain-Continue blockiert bis 100% (skip-card always available) | Wenn der OnboardingState beim `onFinish` zerstört wird, würde ein mid-stream Brain-Download abbrechen. Gate verhindert das, Skip ist klare Alternative. |
| `loadAfterInstall(model)` nach Download | Static `install()` baut ein Throwaway-WhisperKit/AsrManager um die Files zu downloaden — die App-Singleton-Instanz bleibt leer. Ohne expliziten Singleton-Load wäre die erste Fn-Press 2–3 s mit lazy-load belastet. |
| `persistEngineChoice` direkt beim Modell-Klick (nicht erst am Onboarding-Ende) | Sonst resolved `viewModel.service` während PracticeScreen den falschen (Default-Whisper-)Service und Recording schlägt fehl. |
| Audio-Crop 200 ms beidseitig im Recorder | Belt-and-suspenders gegen UI-Sound-Leak ins Mic. User wartet typischerweise > 150 ms nach Start-Sound bevor er redet → kein Speech-Verlust. |
| NSSound + System-Sounds für UI-Feedback | Keine Asset-Files, keine Lizenz. Apple liefert `Purr`, `Pop`, `Morse` etc. mit. Per-Sound Volume getrennt. |
| Mode-Switch-Animation braucht `Animatable`-Konformanz | Plain `ViewModifier` in `AnyTransition.modifier` snapt ohne `Animatable`. SwiftUI braucht `animatableData` (hier `AnimatablePair<CGFloat, AnimatablePair<CGFloat, Double>>`) für mid-frame-Interpolation. |
| `.id(cycle.activeMode.id)` auf `CycleBadge` | Ohne Identity-Change ist die View für SwiftUI nur eine Property-Update → keine `transition` greift. Mit `.id()` erkennt SwiftUI removal + insertion → Droplet-Transition feuert. |
| `holdDelay` 300 → 150 ms | 300 ms war designed gegen Bubble-Flackern bei kurzen Taps. User empfand die Latenz aber als zu lang. 150 ms ist noch oberhalb typischer Tap-Dauer (80–100 ms). |
| Paste-Restore 300 ms → 1.2 s + Content-Check | 300 ms war zu kurz für langsame Apps (Chrome, Electron) — manchmal pastete Voicy das alte Clipboard statt des transkribierten Texts. |

## Open Questions

- **Droplet-Animation visuell**: Mit `Animatable`-Konformanz + bouncier Spring sollte sie sichtbar sein. Verifikation durch User steht aus. Falls weiter nicht sichtbar → vermutlich Build-Cache, sonst tieferes Debug nötig.
- **Mode-Switch-Sound-Volume 0.08**: Ggf. weiter feinjustieren. Vielleicht sogar 0.04 — User wollte "deutlich leiser".
- **Audio-Crop 200 ms**: Falls User merkt dass erste/letzte Silben abgeschnitten werden → reduzieren auf 100 ms.
- **PracticeScreen Recording-Erlebnis bei langsamem ersten Load**: Wenn das Modell direkt nach Onboarding-Download noch nicht im RAM ist (sollte nicht passieren mit `loadAfterInstall`), wäre der erste Fn-Press immer noch träge. Robustheitstest ausstehend.
- **Whisper-File-Casing**: lowercase-Output ohne Punctuation bei Datei-Transkription. Vertagt.
- **Diarization-Quality**: LS-EEND-Output mau, drei Verbesserungspfade dokumentiert, geparkt.
- **Phase 3.5 Speaker-Edit**: geparkt.

## Next Steps

1. **Droplet-Animation testen**: App vollständig rebuilden (Cmd+R aus Xcode) und während Recording Fn+→/← drücken. Die Kugel sollte horizontal-gestreckt aus der Pill-Kante kommen, mit Spring-Overshoot zur Runde nachschwingen. Falls's funktioniert: weiter mit Schritt 2. Falls nicht: tieferes Debug — vielleicht `withAnimation`-Wrapper in `cycleForward/cycleBackward` setzen, oder Animation auf einen `.scaleEffect(...).animation(...)` direkt am `CycleBadge` ziehen.
2. **Sound-Volumes final feinjustieren** falls User-Feedback dazu kommt.
3. **Commit + push** der uncommitted Änderungen: Sounds, Audio-Crop, weißer Warning, Droplet-Animation. Eine Commit-Message in der Art von `add UI sounds with audio-cropping; droplet mode-switch transition`.
4. **Sound-Toggle in Settings-View** exposieren — aktuell nur via Onboarding (`onboarding.clickSounds`). User sollte ihn auch nachträglich umstellen können.
5. **9 `isMock: true`-Toggles in SettingsView** verkabeln oder entfernen.
6. **Whisper-File-Casing** wieder aufnehmen (geparkt).
7. **Diarization-Quality** wieder aufnehmen (geparkt).
