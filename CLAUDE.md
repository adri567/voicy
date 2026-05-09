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
| Transcription | WhisperKit by Argmax (CoreML, Apple Silicon, MIT) |
| Whisper Model | `small` (~500 MB), Default-Bundle |
| LLM (Phase 2+) | Gemma 2B via MLX-Swift (~1.5 GB), lokal gebundelt |
| Paste | macOS Accessibility API |
| Language | Swift 6 |
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

### Rules
- ViewModels enthalten Business Logic — keine rohen Service-Calls in Views
- Views sind pure UI — kein State außer lokalem `@State` für UI-Details
- Service-Protokolle in Domain definiert, Implementierungen in Services
- ViewModels sind `@Observable final class` — nie `ObservableObject`
- Jeder Service hat ein Protokoll (für Testbarkeit via Factory)

---

## Folder Structure

```
Voicy/
├── App/
│   ├── VoicyApp.swift
│   └── DI/
│       └── Container+Registrations.swift
├── Features/
│   ├── MenuBar/          ← NSStatusBar / MenuBarExtra
│   ├── Recording/        ← Aufnahme UI + ViewModel
│   ├── Modes/            ← LLM-Modi (Phase 2)
│   ├── ResearchAgent/    ← Research-Overlay (Phase 3)
│   └── Settings/         ← Einstellungen
├── Domain/
│   ├── Models/           ← Value Types (TranscriptionResult, RecordingMode …)
│   └── Services/         ← Service-Protokolle
├── Services/
│   ├── Transcription/    ← WhisperKit-Wrapper
│   ├── LLM/              ← MLX-Swift / Gemma-Wrapper (Phase 2)
│   ├── Hotkey/           ← Globaler Hotkey
│   └── Paste/            ← Accessibility API Paste
└── Shared/
    ├── Extensions/
    └── UI/               ← Wiederverwendbare View-Komponenten
```

---

## Naming Conventions

- Models: Substantiv ohne Prefix (z.B. `TranscriptionResult`, `RecordingMode`)
- Service-Protokolle: Verb-Substantiv + `Service` (z.B. `TranscriptionService`, `PasteService`)
- Service-Implementierungen: `Default` + Protokollname (z.B. `DefaultTranscriptionService`)
- ViewModels: Feature + `ViewModel` (z.B. `RecordingViewModel`)
- Views: Feature + `View` (z.B. `RecordingView`)
- DI-Keys in Factory: lowerCamelCase des Protokollnamens (z.B. `transcriptionService`)

---

## SwiftUI Patterns

Dieses Projekt nutzt macOS 14+ Observation — **nicht** das alte `ObservableObject`-Muster.

- ViewModels sind `@Observable final class` (nie `ObservableObject`)
- Views besitzen ihr ViewModel via `@State private var viewModel = MyViewModel()`
- Nie `@StateObject`, `@ObservedObject`, `@EnvironmentObject` verwenden
- Geteilter App-State via `.environment()` übergeben und `@Environment(AppState.self)` lesen
- Views sind pure UI — Logic gehört ins ViewModel

```swift
// ViewModel
@Observable final class RecordingViewModel {
    @ObservationIgnored @Injected(\.transcriptionService) private var transcription
}

// View
struct RecordingView: View {
    @State private var viewModel = RecordingViewModel()
}
```

---

## Dependency Injection

**Framework:** Factory (hmlongco/Factory)

- Alle Dependencies in `Container`-Extensions registriert (`Container+Registrations.swift`)
- ViewModels resolven Services via `@Injected(\.serviceName)`
- Services erhalten Dependencies per Initializer
- Nie Singletons — immer Factory
- Für Tests: `Container.shared.transcriptionService.register { MockTranscriptionService() }`
- Nach jedem Test: `Container.shared.reset()`

---

## Phasen

### Phase 1 — MVP (aktueller Fokus)
> Mikrofon → WhisperKit → Rohtext → Paste. Kein LLM.
- Menu Bar App Grundgerüst
- WhisperKit Integration (Aufnahme + Transkription)
- Globaler Hotkey (systemweit)
- Paste ins aktive Textfeld (Accessibility API)

### Phase 2 — Gemma + Modi
Gemma 2B via MLX-Swift, Text-Cleanup, LLM-Modi (`Tab + Buchstabe`), System Actions, Snippets

### Phase 3 — Power Features
Research Agent (async, Overlay), Custom Modi, Voice-Keywords, Multilingual

### Phase 4 — Produkt & Distribution
App Name, Pricing, App Store vs. Direct Distribution, Onboarding

---

## Bekannte Probleme & offene Architekturentscheidungen

### WhisperKit Modell-Distribution
WhisperKit lädt CoreML-Modelle beim ersten Start von Hugging Face (`argmaxinc/whisperkit-coreml`). Das ist für Phase 1 akzeptabel, aber für Distribution problematisch:
- Abhängigkeit von externer Infrastruktur (HF kann down sein, Modell-Namen können sich ändern)
- ~500 MB Download-Erfahrung beim User
- Kein Offline-Betrieb möglich

**Optionen für Phase 4:**
1. Modell direkt in App bündeln (+500 MB App-Grösse, kein Download)
2. Eigener Download-Server (volle Kontrolle)
3. `openai_whisper-tiny` (~150 MB) als Default, `small` optional

**Aktueller Stand:** `DefaultTranscriptionService` nutzt `openai_whisper-small` via Hugging Face. Entscheidung zur Distribution-Strategie offen.

---

## Testing
- Tests für jedes neue Feature, außer explizit anders besprochen
- Tests vor Abschluss eines Tasks ausführen
- Happy path + Edge Cases — keine trivialen Tests
- Services per Factory mocken (siehe DI-Abschnitt)

---

## What Claude Must NEVER Do
- Business Logic in eine View schreiben
- Services direkt aus Views aufrufen — immer über ViewModel
- `@StateObject`, `@ObservedObject` oder `@EnvironmentObject` verwenden
- Singletons für Dependency Management verwenden — immer Factory
- LLM-Code in Phase 1 einbauen (erst wenn Phase 1 stabil läuft)
- API Keys, URLs oder Credentials hardcoden
- Dependencies außerhalb von `Container`-Extensions registrieren
- `@unchecked Sendable` als Abkürzung für Concurrency-Fehler verwenden

---

## Offene Entscheidungen
- Hotkey-Trigger: Double-Command (testen, macOS-Konflikte möglich) oder konfigurierbar
- App Store vs. Direct Distribution
- App Name
- Latenz-Ziel (ms) für Transkription

---

## Learnings
- Factory-Closures sind `@Sendable nonisolated`. Services mit `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` brauchen `nonisolated(unsafe)` auf allen stored properties + `nonisolated init()`.
- Test-Suites die `@MainActor`-ViewModels testen müssen mit `@MainActor` annotiert werden, sonst schlägt Swift 6 Isolation fehl.
