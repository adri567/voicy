# Session Summary

## Context
Voicy ist eine native macOS Menu Bar App (Swift/SwiftUI, Swift 6.2, macOS 26.2+) für Voice-to-Text. Fn-Hotkey hält → WhisperKit/Parakeet transkribiert → Text wird via Accessibility-API/Cmd+V ins fokussierte Textfeld eingefügt. Optional Polish via MLX-Swift (Gemma & Co.) für Modi wie Translate / Email / Developer / Custom. Ziel: kommerzielles Freemium-Produkt. Aktueller Stand: Phase 1 MVP + Phase 2 LLM-Modi & Snippets bereits weitgehend drin.

In dieser Session ging es um einen **kompletten Architektur-Refactor** der gesamten Codebase entlang strenger Regeln, die der User vorgegeben hat: ein Typ pro File, keine verschachtelten View-Structs, keine Business-Logik in Views, keine `AnyView`, Apple's Approachable Concurrency mit `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, und die Skills (`swiftui-pro`, `swift-concurrency-pro`, `swift-testing-pro`) sollen in CLAUDE.md dokumentiert sein.

---

## Current State

### Vollständig fertig (dieser Session)

**Phase A — CLAUDE.md neu**
- Strikte One-Type-per-File-Regel mit Vertragspaar-Ausnahme (nested types, eng gekoppelte Protocol+DTO+Error)
- Folder-Struktur dokumentiert
- Apple Approachable Concurrency mit MainActor-Default als offizielle Strategie
- Skills-Sektion (wann swiftui-pro / swift-concurrency-pro / swift-testing-pro)

**Phase B — Concurrency**
- `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` bleibt (Apple's Empfehlung für SwiftUI-Apps)
- `DefaultTranscriptionService`, `ParakeetTranscriptionService`, `MLXTextCorrectionService` zu `actor` konvertiert — kein `nonisolated(unsafe)` mehr auf ihren Resource-Properties (WhisperKit, AsrManager, ModelContainer)
- `AudioRecorder` ist `nonisolated final class`, owned by transcription actor
- `Container+Registrations` nutzt `MainActor.assumeIsolated` für actor-Inits (konsistent mit `ModeCycleService`)
- AppCoordinator's NSEvent-Callback dispatcht via `Task { @MainActor }` statt `nonisolated(unsafe)` auf `previousFlags`
- `nonisolated(unsafe)` nur noch auf 5 Stellen: AppKit-Event-Tokens im `deinit` (AppCoordinator, RecordingOverlayWindowController) — dokumentiert warum

**Phase C — AnyView**
- 0 `AnyView` in der Codebase
- `ScreenShell` generisch über `<Title: View, LeftBody: View, LeftFooter: View, Right: View>` mit `@ViewBuilder title`
- SettingsView nutzt `@ViewBuilder` Rows statt `[AnyView]` Dictionary

**Phase D — File-Splits + Folder-Reorg**
- 134 Swift-Files (von ~63)
- Multi-Type-Files nur noch 5 — alle nested-type Vertragspaare (`LLMModel.Location`, `EngineModel.Family`, `SettingsRadioRow.Option`, `EngineViewModel.Status/Family`, `DS`-Namespace)
- Sections strukturiert nach Feature-Subfolder:
  - `Sections/Home/` — HomeView, HomeViewModel, HistoryRow, HistoryBucket, HistoryFilter, HistoryFilterChips, StatRow
  - `Sections/Brain/` — BrainView, BrainViewModel, LLMModel, LLMFilter, LLMRow, LocationChip, BrainFilterChip
  - `Sections/Engine/` — EngineView, EngineViewModel, EngineModel, EqualizerBars, ModelRow
  - `Sections/Modes/` — ModesView + 13 Helper-Komponenten
  - `Sections/Snippets/` — SnippetsView, SnippetsViewModel, SnippetRow, SnippetDraft, SnippetEditor
  - `Sections/Hotkey/` — HotkeyView, HotkeyMode, TriggerOption, HotkeyModeCard, KeyboardVisualization
  - `Sections/Settings/` — SettingsView + 10 Row/Section-Komponenten
  - `Sections/Shared/` — TrashButton, ProgressBar (Brain+Engine geteilt)
- Onboarding reorganisiert: `Components/` (ScreenShell, PrimaryButton, ...), `Screens/` (alle Screens + CardViews), `State/` (OnboardingState, OnboardingStep, OnboardingModel, OnboardingBrain, OnboardingCatalog)

**Phase E — Logik aus Views in ViewModels**
- `HomeViewModel` neu: filter, todayWords/Minutes/wpm, topDestinations, engineDisplayName, groupByDay + DateFormatters
- `BrainViewModel` erweitert: visibleModels (Filter+Sort), sortPriority, status(of:), activeModel(in:), localRegistryKeys(from:), filter
- `EngineViewModel` erweitert: sortedModels, whisperIDs(from:), parakeetVersions(from:), activeModel(in:), statusPriority
- Views sind jetzt rein UI — kein Filter-Switch, keine Date-Math, keine Computed Properties über Domain-Daten

**Build + Tests**
- Alle Builds nach jeder Phase grün
- Alle Tests grün (Snippet-Algorithmus, RecordingViewModel, ModeCycleService, UITests)

**Commit**
- `3aff162` — "restructure to one-type-per-file and isolate inference in actors" — 109 Files, +4743/-4664
- **Nicht gepusht** (Push wartet auf explizite User-Freigabe)

**MCP Server**
- Xcode-MCP via `claude mcp add --transport stdio xcode -- xcrun mcpbridge` hinzugefügt — wird nach Claude-Code-Neustart verfügbar

### Offen / nicht implementiert
- Tests für die neuen ViewModels (HomeViewModel, erweiterte Brain/EngineViewModel-Logik) fehlen
- Formelle Review-Pässe mit `swiftui-pro` und `swift-concurrency-pro` Skills wurden nicht gefahren (Phase F nur Build/Test verifiziert)
- Push to remote (`origin/main`) noch nicht erfolgt

---

## Key Decisions

| Entscheidung | Begründung |
|---|---|
| MainActor-Default behalten | User hat explizit zurück gefordert nachdem ich es zwischenzeitlich rausgenommen hatte. Apple's offizielle Empfehlung für SwiftUI-Apps (Approachable Concurrency, Swift 6.2+) |
| `actor` für stateful Services statt `final class` mit `nonisolated(unsafe)` | Cleaner: Resource-Properties (WhisperKit etc.) leben in der Actor-Isolation-Domain. `nonisolated(unsafe)` war Apple-akzeptiert aber strukturell schwächer. |
| `nonisolated(unsafe)` nur für AppKit-Interop in `deinit` | NSEvent-Monitor-Tokens müssen im sync `deinit` eines `@MainActor`-Klasse aufgeräumt werden — der einzige legitime Use-Case, mit Kommentar dokumentiert |
| Vertragspaare-Ausnahme (nested types) | User-Entscheidung: `LLMModel.Location`, `EngineModel.Family`, `SettingsRadioRow.Option` bleiben in ihrem Parent-File. Strict-rule-Konsistenz wäre Over-Engineering bei eng gekoppelten Helper-Enums. |
| Sub-Agents NICHT eingesetzt für File-Splits | User-Entscheidung: serieller Refactor mit Build-Verifikation nach jeder Phase — verlässlicher als parallele Sub-Agents bei strukturellem Refactor |
| Feature-Subfolders unter `Sections/` | User wollte explizit zusammengehörige View-Komponenten gruppiert sehen — Sections/Home/, Sections/Brain/ usw. statt flach |
| ViewModels nehmen Daten als Method-Parameter (`filtered(_ entries: ...)`) | `@Query` muss in der View bleiben (SwiftData-Constraint). VM kann nicht die Source-of-Truth halten, also stateless Transform-Methoden mit Inputs |
| MLX/Whisper/Parakeet Static-Lets brauchen `nonisolated` | Statics werden aus arbitrary Kontexten gelesen (UserDefaults, Disk-Checks) — müssen mit MainActor-Default explizit nonisolated sein |

---

## Open Questions
- Phase F: Sollen formelle `swiftui-pro` / `swift-concurrency-pro` Review-Pässe gefahren werden für detaillierte Empfehlungen?
- Tests für die neuen ViewModels schreiben (HomeViewModel, BrainViewModel-Erweiterungen, EngineViewModel-Erweiterungen)?
- Push zu `origin/main` jetzt oder warten?
- Phase 2 ist eigentlich schon im Code (Modes, Snippets, MLX, Brain) — wo formal abschließen?
- Xcode MCP nach Neustart: Welche Tools sind verfügbar, wie nutzen wir sie?

---

## Next Steps
1. **Push** `3aff162` zu `origin/main` (auf User-Befehl)
2. **Claude Code neu starten** damit der Xcode-MCP-Server verfügbar wird
3. **Tests** für die neuen ViewModel-Methoden (HomeViewModel.filtered, BrainViewModel.visibleModels, EngineViewModel.sortedModels) — Happy Path + Edge Cases
4. **swiftui-pro Review** über die neuen Section-Folders fahren — Apple HIG, Accessibility, Performance-Checks
5. **swift-concurrency-pro Review** über die neuen Actors + Container — Hotspot/Bug-Pattern-Check
6. **Phase 2 formell abschließen**: Status der MLX-Brain-Integration, Mode-Cycle, Snippets-Apply-Pipeline reviewen — was fehlt für Release-Reife?
7. **Phase 4 Distribution-Strategie** entscheiden: WhisperKit-Bundle vs. On-Demand-Download (in CLAUDE.md offen markiert)
