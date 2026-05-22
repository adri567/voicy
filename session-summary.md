# Session Summary

## Context

Voicy ist eine native macOS-App (Swift 6.2 / SwiftUI, macOS 26.2+) für Voice-to-Text mit WhisperKit + Parakeet als Transcription-Engines und MLX-Swift (Gemma / Qwen / Llama) als optionalem LLM-Post-Processing. Diese Session hatte zwei klare Phasen:

1. **Polish + Hardening** — Droplet-Mode-Switch-Animation reparieren, Arrow-Keys während Recording wirklich global schlucken (Cursor-Sprung in Terminal/Xcode), Mistral als zu langsames Brain entfernen, komplette App-Lokalisierung Deutsch → Englisch, Settings auf nur funktionale Toggles zurechtstutzen, Main-Window-Mindestgröße reduzieren.
2. **Strategie-Diskussion** — Pricing-Modell, Cloud-Kosten-Realität, USP-Frage angesichts SuperWhisper/Wispr-Flow-Konkurrenz. Keine Code-Änderungen daraus, aber konzeptionelle Richtung für nächste Sprints abgesteckt.

Die App ist regulär funktional, läuft als Dock-App, hat Onboarding-Flow durchverkabelt, lokale Whisper + Parakeet + MLX-LLM + Sortformer-Diarization.

## Current State

### Committed in dieser Session

- **`e9db9ed`** — intercept cycle arrows, fix droplet transition, add ui sounds
  - `ArrowKeyEventTap.swift` neu: CGEventTap mit `.defaultTap` (statt `.listenOnly`) schluckt Home/End/←/→ system-wide während Recording. Ersetzt den alten `NSEvent.addGlobalMonitorForEvents`, der listen-only war.
  - `CycleBadge.swift`: interner `.id(mode.id)` + `.transition(...)` raus — kollidierte mit dem outer Setup in `OverlayView` und überschrieb die `.droplet`-Transition.
  - `OverlayView.swift`: `.transition(.scale(scale: 0, anchor: .leading).combined(with: .opacity))` mit `.spring(response: 0.4, dampingFraction: 1.0)` — critically-damped, kein Overshoot über 100%. Plus `.padding(.horizontal, 8)` + `.padding(.bottom, 6)` damit das NSPanel die Transition nicht clippt.
  - `SoundService.swift` neu: Purr (start) / Pop (stop) / Morse (mode-switch) via NSSound, respektiert `onboardingClickSounds`-Preference.
  - `AudioRecorder.swift`: crop'd 200ms head + tail um UI-Sound-Leak ins Mic zu verhindern.
  - `EngineView.swift` + `BrainView.swift`: „Import model →"-Buttons + Hugging-Face-Hints raus.
  - `EngineView.swift` + `DiarizationModelCard.swift`: „Beta"-Tag neben „◆ The Editorial" bzw. „Speaker recognition".

- **`ac2f753`** — translate remaining German UI strings to English, drop Mistral brain
  - Alle deutschen User-facing-Strings übersetzt: MainWindowView (Sidebar-Tooltips), SidebarSection (Verlauf → History), SnippetsView (Delete-Alert + Empty-State), SettingsView (Clear-History-Alerts, Toggle/Danger-Labels), Brain/EngineView (Activate/Delete-Alerts), DiarizationModelCard, TranscribePreviewCard/HistoryRow/SegmentRow (Context-Menüs + „Copied"-Toast), TranscribeDetailToggles („unavailable"), MenuBarStatusView (Quit, Open Voicy, Resume onboarding, alle Status-Labels), TranscriptPopupView, HistoryRow, DefaultTranscriptionService + DiarizationService + MLXTextCorrectionService (Error-Strings).
  - Mistral 7B raus aus `BrainView` (Library-Catalog), `OnboardingCatalog` (brains), `MLXTextCorrectionService` (`supportedRegistryKeys` + `configuration`/`repoID`-switches). Bestehende UserDefaults mit `"mistral7B4bit"` fallen via `activeRegistryKey`-Filter auf `defaultRegistryKey` (Gemma 4 E2B) zurück.

- **`4a73a73`** — trim Settings to functional toggles, shrink main window footprint
  - SettingsView: alle Mock-Toggles raus (Launch at login, Show menu bar icon, Input device, Trigger sensitivity, Smart punctuation, Save transcripts, Share usage data, Update channel). Sektionen „Audio" und „Updates" fallen komplett weg.
  - „Play a sound on start / stop" jetzt echt verkabelt via `@AppStorage(Preferences.Key.onboardingClickSounds)` — gleicher Key den `SoundService.enabled` liest.
  - 8 ungenutzte `@State`-Vars in SettingsView entfernt.
  - `MainWindowView.swift`: `minWidth: 1340 → 1200`, `minHeight: 760 → 680`.
  - `DesignSystem.swift`: `pageHPadding: 56 → 40`.
  - Headline-`maxWidth` in EngineView, BrainView, SnippetsView, SettingsView, TranscribeMasthead: `540/560 → 460` damit das Layout bei neuem Min nicht reißt.

### Bekannte offene Punkte (nicht-blockierend)

- **Sidebar NavItem vertikaler Jump beim Collapse**: User hatte gemeldet, dass beim Toggle Sidebar-Full ↔ Compact die Icon-Größen und vertikale Position springen. Ein Fix-Versuch (einheitliche HStack-Struktur, konstante Icon-Größe 16pt/22×22) wurde implementiert, vom User aber **wieder rückgängig** gemacht (per Linter-Notiz signalisiert). Aktueller Stand: Original-Code mit zwei separaten Layout-Branches (compact = bare Image 17pt/40×36, full = HStack mit Image 15pt/18×18 + Text). Problem besteht damit weiterhin — nächster Versuch braucht anderen Ansatz.
- **3 ungenutzte Settings-Komponenten-Files**: `SettingsSelectRow.swift`, `SettingsSliderRow.swift`, `SettingsRadioRow.swift` werden seit Mock-Toggle-Cleanup nicht mehr referenziert. User wurde gefragt ob löschen — noch keine Antwort.
- **9 `isMock: true`-Toggles in SettingsView** — alle entfernt. Dieser Punkt von letzter Session ist erledigt.
- **Whisper-File-Casing** (lowercase ohne Punctuation bei File-Transkription) — geparkt.
- **Diarization-Quality** (LS-EEND-Output mau) — geparkt.
- **Phase 3.5 Speaker-Edit** — geparkt.

## Key Decisions

| Entscheidung | Begründung |
|---|---|
| `ArrowKeyEventTap` als eigene Klasse, `.defaultTap` statt `.listenOnly` | NSEvent.addGlobalMonitorForEvents kann per API-Design keine Events schlucken. Nur CGEventTap mit `.defaultTap` darf nach `return nil` Events fallenlassen. Saubere Klasse analog zu `HotkeyEventTap`, nur aktiv während `arrowTap.enable()` in `startRecordingSession` → `disable()` in `finishRecording`. Minimaler System-Performance-Impact. |
| Droplet-Transition vereinfacht zu `.scale(scale: 0, anchor: .leading).combined(with: .opacity)` | Der Custom `Animatable`-`DropletEmerge`-ViewModifier funktionierte technisch, war aber unnötig komplex. Standard-SwiftUI-Transition macht visuell denselben „aus der Pillenkante wachsen"-Effekt und ist robust gegen Edge-Cases. |
| Critically-damped Spring (`dampingFraction: 1.0`) statt bouncy | User explizit: „nicht größer als 100%" beim Emerge. Bounce sah schlecht aus weil Badge dann kurz über die Pillen-Höhe wuchs. |
| `.padding(.horizontal, 8)` + `.padding(.bottom, 6)` als Window-Breathing-Room | NSPanel-Frame orientiert sich an Layout-Größe, nicht an `.scaleEffect`. Auch nach Switch zu critically-damped als Sicherheit drin gelassen — fängt zukünftige Animation-Anpassungen ab ohne Clipping-Regressionen. |
| Mistral 7B komplett aus 3 Stellen entfernt statt nur aus UI versteckt | Mistral war zu langsam für Translation-Prompts und qualitativ overlapped mit Gemma 4 E4B / Qwen 2.5 7B die schon im Catalog sind. Keine Mock-Hülle — sauberer Cut. UserDefaults-Migration kostenlos durch existierenden `supportedRegistryKeys.contains`-Filter. |
| Mock-Toggles in Settings komplett raus statt grayed-out | „Sektionen mit nur Mock-Inhalt" sah unfertig aus. Lieber weniger Sections die alle echt funktionieren, als Vollständigkeit vortäuschen. Sound-Toggle wurde verkabelt statt gelöscht weil `onboardingClickSounds`-Preference schon im SoundService gelesen wird — nur das Settings-Surface fehlte. |
| Window-Min auf 1200×680 + pageHPadding 40 + Headline-maxWidth 460 als Set | Untergrenze rechnerisch: Sidebar 256 + 2× pageHPadding 40 + Headline 460 + spacing 56 + activeCard 360 = 1228 — passt mit kleinem Puffer in 1200 (Detail-Bereich 944, davon Headline 460 + spacing + Card = 876, bleiben 68px Puffer). Alle vier Werte mussten zusammen angepasst werden. |

### Strategie-Entscheidungen aus Diskussion (nicht im Code)

| Thema | Vorläufige Richtung |
|---|---|
| Pricing-Modell | Hybrid: Free + Pro mit drei Optionen (€4.99/mo · €39/Jahr · €79 Lifetime). Cloud-Tier später separat (€8/mo). |
| Free-Tier Scope | Raw-Mode + Whisper Tiny/Small. Translation, Snippets unlimited, Custom Modes, Speaker Recognition hinter Pro-Paywall. |
| Cloud-LLM-Kosten | Realistisch: $0.30–0.80/User/Monat im Schnitt (Gemini 2.5 Flash oder GPT-4.1 Mini). Heavy-User bei harter 5000-Wörter/Tag-Quota max $2/Monat. Marge bei €8 Cloud-Sub komfortabel >70%. |
| USP-Richtung | **Meeting-Mode** als stärkster Differenzierungs-Kandidat: lokales Otter-Pendant mit Speaker-Diarization + LLM-Summary + Action-Items, alles on-device. Klare Marktlücke (Otter/Granola/Fireflies sind Cloud), nutzt bestehende Voicy-Bausteine (Whisper, Diarization, MLX-LLM), rechtfertigt eigenes Pro-Tier (€15–25/mo). Noch nicht final entschieden. |
| AI-Pointer-Klon (DeepMind-Feature) | Verworfen als eigenes Produkt. Stattdessen evtl. Light-Variante als Vision-augmented Cloud-Pro-Feature („Fn + Shift = mit Screenshot fragen") — kein eigener Strang. |

## Open Questions

- **NavItem-Sidebar-Jump**: nächster Lösungsweg unklar. User hat die einheitliche-HStack-Variante verworfen. Andere Optionen: (a) konstante vertikale Höhe via `.frame(height: 36)` auf das Button-Label statt Padding-Berechnung, (b) komplett separate Compact-Sidebar als eigene View mit eigenem Layout-Setup statt geteilter NavItem, (c) Icon-Größe konstant lassen aber die Hintergrund-Pille-Größe variieren. Braucht Diskussion bevor neuer Versuch.
- **3 unused Settings-Komponenten löschen?** — User-Bestätigung steht aus.
- **Meeting-Mode bauen?** — Strategie-Empfehlung gegeben, User-Entscheidung steht aus. Wenn ja: 4–8 Wochen Build-Effort.
- **Pricing finale Form** — €4.99/€39/€79 vorgeschlagen, kein finales Commit vom User.
- **Cloud-Tier zum Launch oder später?** — Empfehlung: erst Pro etablieren, Cloud nachschieben wenn API-LLMs als Brain-Option dazukommen.
- **Whisper-File-Casing** (Datei-Transkription lowercase ohne Punctuation) — vertagt.
- **Diarization-Quality** — 3 Verbesserungspfade dokumentiert, geparkt.

## Next Steps

1. **NavItem-Sidebar-Jump-Fix (Re-Approach)** — gemeinsam mit User klären welche Layout-Strategie er möchte: konstante Höhe + Icon-Center, oder separate Compact-Sidebar-Komponente, oder Hintergrund-Pille variiert. Erst dann implementieren.
2. **Unused Settings-Komponenten** entscheiden: löschen (`SettingsSelectRow.swift`, `SettingsSliderRow.swift`, `SettingsRadioRow.swift`) oder behalten. Klärung mit User.
3. **Meeting-Mode-Skizze** — falls Strategie-Entscheidung für USP-Richtung fällt: architektonisches Spike-Dokument (welche neuen Services, Pipeline für Long-Form-Recording + Live-Diarization + Post-Summary, neue Sidebar-Sektion „Meetings", Speicherformat für Meeting-Entries). Vor Build.
4. **Whisper-File-Casing** wieder aufnehmen (geparkt aus früheren Sessions).
5. **Diarization-Quality** — einen der 3 dokumentierten Pfade angehen (geparkt).
6. **Pricing-Implementation** — StoreKit 2 Skeleton, Receipt-Validation, Backend-Proxy-Skizze für Cloud-Tier. Erst wenn Pricing-Modell finalisiert ist.
