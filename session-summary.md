# Session Summary

## Context
Voicy ist eine native macOS Menu Bar App (Swift 6.2 / SwiftUI, macOS 26.2+) für Voice-to-Text mit WhisperKit + Parakeet (FluidAudio) als Transcription-Engines und MLX-Swift (Gemma) für LLM-Post-Processing. Phase 1 (Mic-Pipeline), Phase 2 (Modi + Snippets + Brain + separate Transcribe-Page mit FileHistory) und Phase 3 (Diarization, mit Quality-Caveats) sind live. Diese Session hatte zwei Hauptthemen: (1) ein **mehrstündiger Deep-Dive zum Fn-Hotkey + Character-Viewer-Suppression**, in dem wir versucht haben, Wispr Flow's Verhalten zu replizieren — am Ende mit pragmatischer Lösung über User-System-Setting; (2) ein **Onboarding-UI-Cleanup** auf Basis von User-Feedback.

---

## Current State

### Vollständig fertig + im Build (aber NICHT committed/gepusht)

**Fn-Hotkey-Architektur — final:**
- `HotkeyEventTap.swift` reduziert auf reinen **listen-only CGEventTap** (`.cgSessionEventTap`, `.listenOnly`). Keine Suppression-Versuche mehr im Code. Nur Detection von Fn-Edges via `event.flags.contains(.maskSecondaryFn)`.
- **Gesture-State-Machine** in `AppCoordinator` neu gebaut: `idle → pendingHold → hold/toggle`. Single-Tap (< 300ms) macht NICHTS (keine Bubble, kein Recording). Hold (> 300ms) startet push-to-talk. Doppel-Fn (2 schnelle Taps) startet persistent toggle mode. Single-Fn im Toggle beendet + transkribiert.
- `LSUIElement = YES` in pbxproj — Voicy ist jetzt Menüleisten-only ohne Dock-Icon.
- `PermissionService.disableFnKey()` schreibt `AppleFnUsageType=0` in beide Host-Scopes (AnyHost + CurrentHost) + ruft `activateSettings -u` + `killall -HUP cfprefsd` + 4 verschiedene `NSDistributedNotification` Names.

**Onboarding-UI-Cleanup:**
- `WelcomeScreen` — "Voicy Press"-Tagline raus, Footer ("ESC TO QUIT/v0.4 BETA") raus, Button auf "Begin Setup" gekürzt. Lädt AppIcon-Asset wenn vorhanden.
- `OnboardingStep` — `.allSet` entfernt. `PracticeScreen` ist letzter Step.
- `PracticeScreen` — nimmt `onFinish`-Callback, ruft `persistFinalChoices + onFinish` beim "Open Voicy"-Button.
- `AllSetScreen.swift` gelöscht.
- `AccessibilityScreen` — Mock-Liste reduziert auf nur Voicy-Zeile, mit Voicy-Icon aus AppIcon-Asset.
- `NavFooter` in Microphone/Accessibility/FnKey — "I'll do this later"/"Deny"-Option ENTFERNT. Continue-Button `disabled` bis Permission granted.
- `ModelScreen` / `OnboardingCatalog` — Parakeet ist jetzt Recommended (statt Whisper Small). Default-`modelID = "parakeet"`.
- Neuer `FnKeyScreen.swift` als Onboarding-Step mit "Free up Fn key" Button + Live-Status-Polling.

### Offen — DAS Hauptproblem

**Char-Viewer-Suppression auf macOS 26 funktioniert NICHT programmatisch.**
- Voicy schreibt `AppleFnUsageType=0` korrekt in die Plist (verifiziert via `defaults read`).
- Voicy-UI zeigt "Set to Do Nothing" weil unser Read den 0-Wert sieht.
- ABER: System Settings UI zeigt weiterhin "Show Emoji & Symbols", UND Char-Viewer kommt bei Fn-Druck.
- **HIToolbox-Daemon cached den alten Wert intern** und reagiert weder auf `activateSettings -u`, noch auf `killall -HUP cfprefsd`, noch auf irgendeine der 4 getesteten NSDistributedNotifications.
- Apple's System Settings UI nutzt vermutlich eine **private XPC-Schnittstelle** zum HIToolbox-Daemon — die kennen wir ohne Disassembly nicht.
- User-Statement: "Ich muss kein Logout machen wenn ich es manuell in System Settings umstelle" — also gibt es einen Weg, wir kennen ihn nur nicht.

### Bekannte offene Issues

- Char-Viewer-Suppression (siehe oben) — User hat klar gesagt er will programmatische Lösung, akzeptiert keine Logout-Friktion.
- Diarization-Qualität mau (`diarization_quality_paths.md`)
- Whisper-File-Casing (`whisper_file_casing_open.md`)
- 9 `isMock: true` Toggles in SettingsView

---

## Key Decisions

| Entscheidung | Begründung |
|---|---|
| Char-Viewer-Suppression NICHT mehr im Code, sondern via System-Setting | ~6h Code-Side-Exploration ergebnislos: `.cgSessionEventTap` + `return nil` reicht nicht auf macOS 26; `.cghidEventTap` desynced Modifier-State; Carbon RegisterEventHotKey lehnt Modifier-only ab; IOHIDManager-Seize braucht kext; CGSSetSymbolicHotKeyEnabled hat keine ID für Globe/Fn. Reverse-Engineering von Wispr (Asar-Extraction, Binary-Inspection mit `otool`, `strings`, `nm`, `r2`) zeigte: Wispr nutzt einen separaten Swift-Helper, aber auch dort kein offensichtlicher Trick. |
| LSUIElement = YES | Voicy ist Menu Bar App, sollte kein Dock-Icon haben. Wispr's Helper macht es genauso. Außerdem Hypothese (nicht bestätigt) dass TCC sich für LSUIElement-Apps anders verhält. |
| Gesture: Single-Tap = NICHTS | Vorher hat Single-Tap recording gestartet und beim short release wieder discarded → Bubble flackerte und manchmal blieb sie hängen wegen Tap-Race. Neue State-Machine: Bubble erscheint nur bei eindeutig hold (> 300ms) oder beim zweiten Tap eines Doppels. |
| Parakeet als Recommended Model | User-Entscheidung. Parakeet ist schneller und englisch-fokussiert. |
| Permissions verpflichtend (kein Skip) | User-Entscheidung. Verhindert dass User in einen halb-konfigurierten Zustand kommt. |
| AllSetScreen entfernt | User-Entscheidung. PracticeScreen führt direkt zu "Open Voicy". |
| `passRetained` statt `passUnretained` im Tap-Callback | Drei Reference-Implementierungen (Wispr/VoiceInk/yetone) machen alle passRetained. macOS released das Event nach Callback; `passUnretained` kann zu freed-event-Pointer führen. Verifiziert als subtiler ARC-Bug. |
| Reverse-Engineering investiert obwohl unsicherer Ausgang | User-Direktive: "es muss eine Lösung geben". 3 parallele Recherche-Agents + lokale r2-Disassembly + Wispr-asar-Extraction. Ergebnis: bekannte Mechanismen alle widerlegt, Wispr's exakter Trick bleibt unklar. |

---

## Open Questions

- **Fn-Key-Suppression der Showstopper:** Wie löst Wispr Flow es? Unsere 4 Trigger (Plist beide Hosts + activateSettings + cfprefsd HUP + 4 NSDistributedNotifications) reichen nicht. Vermutung: private XPC zu HIToolbox-Daemon.
- **Drei realistische Pfade noch nicht entschieden:**
  - (A) Logout-Hinweis nach "Free up Fn key"-Klick — funktioniert garantiert, aber User-Friktion
  - (B) AppleScript-Hack der System Settings UI öffnet und programmatisch die Dropdown ändert — fragile, kann pro macOS-Version brechen
  - (C) Live-`sample` auf System Settings App während User manuell klickt — riskant, kann fruchtlos sein, braucht User-Mitarbeit für ~30 Sekunden Terminal
- **Onboarding wurde nicht durchgetestet:** UI-Cleanup ist im Code, aber User muss durchklicken ob alle Screens sauber rendern, AppIcon korrekt geladen wird, etc.

---

## Next Steps

1. **User-Entscheidung zum FnKey-Pfad** (A/B/C oben) einholen und implementieren.
2. **Onboarding durchtesten** — `killall Voicy && defaults delete de.voicy.as.Voicy onboardingCompleted && open ...` und alle Screens durchklicken.
3. **AppIcon-Asset** verifizieren — Welcome und Accessibility Screens versuchen `NSImage(named: "AppIcon")`. Falls leer, Fallback greift (RoundedRectangle mit waveform-Icon).
4. **Wenn FnKey gelöst:** Committen + pushen. Aktueller Stand hat eine Menge ungestester Änderungen die noch nicht commited sind seit letztem Commit `8b2e8fd document Fn suppression as best-effort`.
5. **Memory-Update** nach Fn-Lösung: `hotkey_hid_tap_required.md` reflektiert noch den vorherigen Stand mit listen-only Tap + System-Setting-Approach.
6. **Phase 3.5 Speaker-Edit** weiter (geparkt).
7. **Whisper-Casing** weiter (geparkt).
