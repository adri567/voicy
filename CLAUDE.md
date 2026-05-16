# Voicy — CLAUDE.md

## Project Overview
Native macOS Menu Bar App (Swift/SwiftUI) — Voice-to-Text mit KI-gestützter Textverarbeitung.
Ziel: kommerzielles Produkt (Freemium + Abo). Aktueller Fokus: **Phase 1 MVP** (kein LLM).

---

## Tech Stack

| Layer | Technology |
|---|---|
| UI | SwiftUI (primary), AppKit only where SwiftUI is insufficient |
| Architecture | MVVM |
| DI | Factory (hmlongco/Factory) |
| Transcription | WhisperKit (CoreML, Apple Silicon, MIT) + Parakeet (FluidAudio) |
| LLM (Phase 2+) | MLX-Swift (Gemma / Foundation Models austauschbar) |
| Paste | macOS Accessibility API |
| Language | Swift 6.2 (strict concurrency) |
| Minimum macOS | 26.2 |
| Platform | macOS Menu Bar App (Windows optional Phase 4) |

---

## Architecture

### Layer Responsibilities

```
Presentation Layer  →  SwiftUI Views + ViewModels
Service Layer       →  Business Logic, Transcription, LLM, Hotkey, Paste
Domain              →  Models, Service Protocols
```

**Dependency direction:** Views → ViewModels → Services (via protocol)
ViewModels resolve Services via Factory. Services kennen keine ViewModels oder Views.

### Core Rules
- ViewModels enthalten **alle** Business Logic, Filter-Computed-Properties, Date-Math, Sortier-Logik
- Views sind **pure UI** — kein State außer reinem UI-Detail-State (Hover, Sheet-open-Flag, Focus). Keine `init`-Logik, keine Computed Properties über Daten, keine Date-Math, kein `if`/`switch` über Domain-Werte
- Service-Protokolle in `Domain/Services/` definiert, Implementierungen in `Services/`
- ViewModels sind `@Observable @MainActor final class` — nie `ObservableObject`
- Jeder Service hat ein Protokoll (für Testbarkeit via Factory)

---

## File Organisation — STRIKT

### One Type per File
**Jeder** `struct`, `class`, `enum`, `actor` lebt in seinem eigenen `.swift`-File. Der Filename matched den Typnamen 1:1.

### Erlaubte Ausnahmen (nur diese, sonst nichts)
1. **Vertragspaare**: Ein Service-Protocol darf seinen DTO und seine Error-Enum im selben File haben, wenn sie ausschließlich Teil des Vertrags sind (`SnippetService.swift` mit `SnippetDTO` + `SnippetError`).
2. **Eng gekoppelte Modell-Paare**: Ein Wrapper-Modell und sein zugehöriges Type-Enum, das **nur** dort verwendet wird (`Mode` + `ModeType`).
3. Private `extension` desselben Typs.

**Niemals** erlaubt:
- Zwei `View`-Structs im selben File (auch keine private Helper-Views — eigenes File in einem `Components/`-Subfolder)
- Ein View-Struct verschachtelt innerhalb eines anderen Structs
- Helper-Structs wie `Match`, `Bucket`, `Draft`, `Model`, `Option` neben dem Hauptstruct — eigenes File
- `private struct` neben dem Hauptstruct, wenn es eine echte Komponente ist

### Folder Structure
```
Voicy/
├── App/
│   ├── VoicyApp.swift
│   ├── AppCoordinator.swift
│   └── DI/
│       └── Container+Registrations.swift
├── Domain/
│   ├── Models/           ← Value Types pro File
│   └── Services/         ← Service-Protokolle pro File
├── Services/
│   ├── Transcription/
│   ├── LLM/
│   ├── Snippets/
│   ├── Modes/
│   ├── Permissions/
│   ├── Paste/
│   ├── Audio/
│   ├── History/
│   └── TargetApp/
├── Features/
│   ├── MenuBar/
│   ├── Recording/
│   │   ├── Views/        ← OverlayView, TranscriptPopupView, CycleBadge …
│   │   ├── ViewModels/
│   │   └── Controllers/  ← Window-Controller
│   ├── MainWindow/
│   │   ├── Views/
│   │   ├── ViewModels/
│   │   ├── Sections/
│   │   │   ├── Home/        ← HomeView + private Komponenten pro File
│   │   │   ├── Brain/
│   │   │   ├── Engine/
│   │   │   ├── Modes/
│   │   │   ├── Snippets/
│   │   │   ├── Settings/
│   │   │   └── Hotkey/
│   │   └── Components/   ← Shared Section-Komponenten
│   └── Onboarding/
│       ├── Screens/
│       ├── Components/
│       └── ViewModels/
└── Shared/
    ├── DesignSystem/     ← DS.swift + Modifiers + Components pro File
    ├── UI/               ← Wiederverwendbare View-Komponenten pro File
    └── Utilities/        ← Preferences, ModelStorage, AppRelauncher pro File
```

---

## Naming Conventions
- Models: Substantiv ohne Prefix (`TranscriptionResult`, `RecordingMode`)
- Service-Protokolle: Verb-Substantiv + `Service` (`TranscriptionService`, `PasteService`)
- Service-Implementierungen: `Default` + Protokollname (`DefaultTranscriptionService`)
- ViewModels: Feature + `ViewModel` (`RecordingViewModel`)
- Views: Feature + `View` (`HomeView`)
- DI-Keys in Factory: lowerCamelCase des Protokollnamens (`transcriptionService`)

---

## SwiftUI Patterns

Projekt nutzt macOS 14+ Observation — **nicht** das alte `ObservableObject`-Muster.

- ViewModels: `@Observable @MainActor final class`
- Views besitzen ihr ViewModel via `@State private var viewModel = MyViewModel()`
- Nie `@StateObject`, `@ObservedObject`, `@EnvironmentObject`
- Geteilter App-State via `.environment()` und `@Environment(AppState.self)`
- **Kein `AnyView`** — generische Views (`<Content: View>`) oder `@ViewBuilder` benutzen
- Views sind pure UI — Logik gehört ins ViewModel

```swift
// ViewModel
@Observable @MainActor final class RecordingViewModel {
    @ObservationIgnored @Injected(\.transcriptionService) private var transcription
}

// View
struct RecordingView: View {
    @State private var viewModel = RecordingViewModel()
    var body: some View { … }
}
```

---

## Swift 6 Concurrency

Das Projekt nutzt **Apple's Approachable Concurrency** mit `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`. Das ist Apple's empfohlener Default für SwiftUI-Apps ab Swift 6.2 und ihr klarer Push für die Zukunft — UI-Code ist die Norm, Services sind die Ausnahme die isoliert wird.

Was das bedeutet:
- **Jeder Typ ohne explizite Isolation ist `@MainActor`** — Views, ViewModels, View-Helpers
- **SwiftUI-Views** sind sowieso `@MainActor` (vom `View`-Protokoll), Setting ändert daran nichts
- **ViewModels** sind durch den Default automatisch `@MainActor` — keine zusätzliche Annotation nötig (darf aber explizit sein, ist redundant aber harmlos)
- **Services** müssen aktiv aus MainActor ausgebrochen werden:
  - Mit internem mutable State → `actor` (cleanste Variante — eigener Isolation Domain, keine `nonisolated(unsafe)` Properties nötig)
  - Stateless oder mit `let`-only Sendable State → `final class` mit `nonisolated` keyword auf Init und Methoden
  - Value Types (Models, Enums, Structs ohne Mutation) → `nonisolated` auf Type-Level
- **Service-Protokolle** müssen ihre Methoden `nonisolated func` deklarieren, damit Actor- und nonisolated-Class-Implementierungen beide konform sind
- **Static members** in Services brauchen `nonisolated` damit sie aus jedem Kontext erreichbar bleiben (UserDefaults-Reads, Disk-Checks etc.)
- **Factory-Closures** sind `@Sendable nonisolated` — Services brauchen entsprechend nonisolated Init oder actor (actor-Inits sind implicitly nonisolated)
- **Niemals** `@unchecked Sendable` oder `nonisolated(unsafe)` als Abkürzung. `nonisolated(unsafe)` ist nur akzeptiert für AppKit-Interop bei Tokens die in nonisolated deinit aufgeräumt werden müssen, mit Kommentar warum es sicher ist.

Konkret in diesem Projekt:
- WhisperKit, Parakeet, MLX-Services sind `actor` — saubere Isolation für Background-Inferenz
- AudioRecorder ist `nonisolated final class` — owned by transcription actor, wird aus dessen Isolation Domain aufgerufen
- DefaultSnippetService, SwiftDataTranscriptionHistoryService: `final class` mit nonisolated methods — Sendable über `let container: ModelContainer`
- DefaultPasteService, DefaultTargetAppService: `final class` mit MainActor-defaults (NSPasteboard/AXUIElement gehören auf Main), nur `nonisolated init()` für Factory-Konstruktion

---

## Dependency Injection

**Framework:** Factory (hmlongco/Factory)

- Alle Dependencies in `Container`-Extensions registriert (`Container+Registrations.swift`)
- ViewModels resolven Services via `@Injected(\.serviceName)`
- Services erhalten Dependencies per Initializer
- Nie Singletons — immer Factory
- Tests: `Container.shared.transcriptionService.register { MockTranscriptionService() }` + `Container.shared.reset()` nach jedem Test

---

## Skills

Im Projekt installierte Skills unter `.claude/skills/` — vor und während der jeweiligen Arbeit anwenden.

| Skill | Anwendung |
|---|---|
| `swiftui-pro` | **Pflicht** vor und nach jedem SwiftUI-View-Touch. Reviewed deprecated APIs, View-Hierarchie, Data-Flow, Navigation, Performance, Accessibility, Hygiene. Bei grösseren View-Refactors als Abschluss-Review laufen lassen. |
| `swift-concurrency-pro` | **Pflicht** vor jeder Änderung an `actor`/`@MainActor`/`async`/`await`/`Task`/`Sendable`. Reviewed Hotspots, Strukturierte vs. unstrukturierte Concurrency, Cancellation, AsyncStream, Bug-Patterns. Bei Concurrency-Refactors als Vor- und Nach-Review. |
| `swift-testing-pro` | **Pflicht** vor jedem neuen Test oder XCTest-Migration. Reviewed `@Test`/`@Suite`/Tags/Async-Tests/Confirmations/Exit-Tests. |

**Reihenfolge bei einem Feature-Refactor**: Concurrency-Review → SwiftUI-Review → Implementierung → SwiftUI-Review post-implementation → Tests via Testing-Pro.

---

## Phasen

### Phase 1 — MVP (aktueller Fokus)
> Mikrofon → WhisperKit → Rohtext → Paste. Kein LLM.

### Phase 2 — Gemma + Modi
Gemma 2B via MLX-Swift, Text-Cleanup, LLM-Modi, System Actions, Snippets

### Phase 3 — Power Features
Research Agent (async, Overlay), Custom Modi, Voice-Keywords, Multilingual

### Phase 4 — Produkt & Distribution
App Name, Pricing, App Store vs. Direct Distribution, Onboarding

---

## Bekannte Probleme & offene Architekturentscheidungen

### WhisperKit Modell-Distribution
WhisperKit lädt CoreML-Modelle beim ersten Start von Hugging Face (`argmaxinc/whisperkit-coreml`).
- Abhängigkeit von externer Infrastruktur
- ~500 MB Download-Erfahrung beim User
- Kein Offline-Betrieb möglich

**Optionen für Phase 4:**
1. Modell direkt in App bündeln (+500 MB App-Grösse, kein Download)
2. Eigener Download-Server (volle Kontrolle)
3. `openai_whisper-tiny` (~150 MB) als Default, `small` optional

---

## Testing
- Tests für jedes neue Feature, außer explizit anders besprochen
- Tests vor Abschluss eines Tasks ausführen
- Happy path + Edge Cases — keine trivialen Tests
- Services per Factory mocken
- `swift-testing-pro` Skill vor neuen Tests konsultieren

---

## What Claude Must NEVER Do
- Business Logic in eine View schreiben (auch keine Filter-Switches, keine Date-Math, kein `init` mit Berechnungen)
- Services direkt aus Views aufrufen — immer über ViewModel
- `AnyView` verwenden
- Zwei View-Structs in dasselbe File packen
- Eine View-Struct innerhalb eines Structs verschachteln
- `@StateObject`, `@ObservedObject` oder `@EnvironmentObject` verwenden
- Singletons für DI verwenden — immer Factory
- LLM-Code in Phase 1 einbauen (erst wenn Phase 1 stabil läuft)
- API Keys, URLs oder Credentials hardcoden
- Dependencies außerhalb von `Container`-Extensions registrieren
- `@unchecked Sendable` oder `nonisolated(unsafe)` als Abkürzung verwenden (nur für AppKit-Interop wo es nachweislich nötig ist, mit Begründung im Kommentar)
- Project-wide `SWIFT_DEFAULT_ACTOR_ISOLATION` ändern (steht auf `MainActor` per Apple's Empfehlung)
- Helper-Structs neben dem Hauptstruct deklarieren (eigenes File in `Components/`)

---

## Offene Entscheidungen
- Hotkey-Trigger: Double-Command vs. konfigurierbar
- App Store vs. Direct Distribution
- App Name
- Latenz-Ziel (ms) für Transkription

---

## Learnings
- Test-Suites, die `@MainActor`-ViewModels testen, müssen mit `@MainActor` annotiert werden, sonst schlägt Swift 6 Isolation fehl.
