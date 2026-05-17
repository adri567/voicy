# Session Summary

## Context
Voicy ist eine native macOS Menu Bar App (Swift 6.2 / SwiftUI, macOS 26.2+) für Voice-to-Text mit WhisperKit + Parakeet (FluidAudio) als Transcription-Engines und MLX-Swift (Gemma) für LLM-Post-Processing. Phase 1 (Mic-Pipeline) und Phase 2 (Modi + Snippets + Brain + separate Transcribe-Page mit FileHistory) sind live. Diese Session adressierte UX-Refinements auf der Transcribe-Page, eine längere Debug-Saga zum Whisper-Casing-Problem bei File-Transkription, und den Start von **Phase 3 — Speaker-Diarization**.

---

## Current State

### Vollständig fertig + committed (`79310ad`)

**Transcribe UX-Verfeinerungen:**
- `HistoryRow` (Home) und `TranscribeHistoryRow` (Transcribe): Text-Selection mit Maus + Doppelklick = Copy-Aller-Text + Context-Menu
- `TranscribePreviewCard`: identisches Copy-Verhalten, Single-Click öffnet Detail
- `TranscribeDetailView`: neuer **Continuous-Text-Toggle** (Default ON), zeigt Fließtext statt Segmente; bei OFF bleibt die alte Segment-Liste mit Timestamps für spätere Diarization
- `TranscribeSegmentRow`: Doppelklick kopiert einzelnes Segment
- Truncated Texte (Filename, Preview) haben kein `textSelection(.enabled)` mehr → kein Re-Layout/Überlappen beim Klicken
- Parakeet-Segmentierung umgebaut: statt fixe 30s-Buckets jetzt Punctuation-/Pause-/Force-Split-Heuristik
- `cleanWhisperOutput` strippt Whisper-Control-Tokens (`<|...|>`)

**Settings — History löschen:**
- `TranscriptionHistoryService` + `FileTranscriptionHistoryService` haben neue `deleteAll()` Method
- `SwiftDataTranscriptionHistoryService` + `SwiftDataFileTranscriptionHistoryService` Implementierung via `context.delete(model:)`
- `SettingsView` Privacy-Section: zwei neue Buttons **„Home-Historie löschen"** und **„Transcribe-Historie löschen"** mit nativem Alert-Confirm
- `SettingsDangerButtonRow` erweitert mit `action` und `description`

### Implementiert in dieser Session, **noch nicht committed**

**Phase 3 — Speaker-Diarization:**
- Domain: `TranscriptionSegment.speaker: Int?` (optional, rückwärtskompatibel via JSON-Codable), neuer `DiarizationSegment` Value-Type
- Service-Layer: `DiarizationService` Protocol + `FluidAudioDiarizationService` Actor
- DI-Container: `diarizationService` Factory als Singleton
- Pipeline: `TranscribeViewModel.runFullPipeline` startet Diarization **parallel** zur Transkription via `async let`, wenn Modell installiert; `mergeSpeakers(into:diarization:)` Helper weist max-overlap-Speaker pro Segment zu
- UI: `TranscribeDetailToggles` „Speaker labels"-Toggle ist echt (`speakersAvailable: Bool` disabled bei fehlenden Daten); `TranscribeSegmentRow` rendert „Speaker N"-Accent-Tag; Continuous-Mode hat `speakerGroupedContinuousPanel` (Conversation-Style)
- EngineView: separate `DiarizationModelCard` mit Install/Downloading/Installed State
- Memory: `phase3_diarization.md` + MEMORY.md-Eintrag

### Bekannte offene Issues

**Sortformer-CoreML-Bug auf macOS 26:**
Alle FluidAudio-gepackten Sortformer-mlpackages (`Sortformer_v2.mlmodelc`, `Sortformer_v2.1.mlmodelc`) deklarieren `chunk_pre_encoder_embs_out` als sowohl Input UND Output Tensor. macOS 26 BNNS validiert strenger und wirft beim Compile `"Inputs and outputs must be distinct"`. MLModel-Init schlägt fehl, App-Hang aus User-Sicht.

**Fix:** Backend auf `LSEENDDiarizer` (DIHARD-3, 100ms step, .cpuOnly) umgestellt. Andere Modell-Architektur, kein BNNS-Bug. Trade-off: schlechtere DER (~17% vs Sortformers ~11%) aber funktioniert. Verifikation steht noch aus.

**Whisper-File-Casing offen:**
File-Transkription mit Whisper Large v3 quantized liefert lowercase ohne Punctuation; Mic funktioniert. Debug-Saga in dieser Session (silence-padding, peak-normalize, VAD-chunking, promptTokens, switched audioPath→audioArray) wurde komplett **rückgängig gemacht** auf User-Wunsch. Memory `whisper_file_casing_open.md` dokumentiert was probiert wurde, damit's beim nächsten Anlauf nicht von vorne losgeht.

### Verworfen in dieser Session
- **MLX Polish-Integration** für File-Transkription (kompletter Service+Prompt+ViewModel-Wiring): vom User explizit zurückgenommen
- **Per-Item Delete-Button** in Transcribe-History (Hover-Trash + Confirm-Alert): vom User explizit zurückgenommen

---

## Key Decisions

| Entscheidung | Begründung |
|---|---|
| Continuous-Mode als Default in DetailView | User-Wunsch: 9 Segmente für einen Sprecher sind zu viel. Segments-Toggle bleibt für später wenn Diarization läuft. |
| `lowercase()` in `Smart punctuation`-Toggle behalten | User hat einmal aktiv zurückgenommen — Punctuation-Toggle entfernt Punctuation UND lowercases. |
| Sortformer → LS-EEND wegen CoreML-Bug | Sortformer-mlpackages haben Tensor-Validation-Bug auf macOS 26 BNNS. LS-EEND ist andere Modell-Architektur ohne den Bug. |
| Diarization läuft immer (wenn Modell installiert) | User-Wahl: einmal install via Engine-View → läuft parallel beim Transcribe. Detail-Toggle ist nur Anzeige-Schalter. |
| Diarization nur für File-Transcribe | Mic ist Self-Dictation; Speaker-Erkennung dort nutzlos. |
| `mergeSpeakers` per max-time-overlap | Pragmatische Heuristik; Whisper-Segmente sind selten <2s, dominanter Speaker meist eindeutig. |
| Speaker-Namen erst mal nicht editierbar | Phase 3.5; Phase 3 testet erst ob Erkennung selbst gut genug ist. |
| Whisper-Casing-Debug vollständig rollback | User: „wir kümmern uns ein anderes mal darum". Memory-Eintrag dokumentiert die Sackgassen. |

---

## Open Questions
- **LS-EEND Verifikation:** Funktioniert der Install und das `processComplete(audioFileURL:)` ohne CoreML-Bug? Steht noch aus, User soll testen.
- **Speaker-Quality:** Wie sieht der Output bei einem echten 2-Speaker-Audio aus? DER vergleichbar mit Sortformer (was wir nicht nutzen können)?
- **Whisper-Casing:** Wann angehen? Modellwechsel auf Small/Medium ist der wahrscheinlichste Path laut Memory.
- **Phase 3.5 Speaker-Editierung:** Eigene `SpeakerName`-Mapping-Struct pro `FileTranscriptionEntry`, persist separat von `TranscriptionSegment.speaker`.
- **Sortformer-Fix bei FluidAudio upstream:** Issue beim Maintainer aufmachen? Wenn sie's fixen, könnten wir auf das bessere Modell zurück.

---

## Next Steps
1. **User testet** LS-EEND Install in EngineView und schickt Console-Logs
2. Bei Erfolg: **commit + push** Phase 3 Diarization
3. Bei Fehler: weitere Diarization-Library-Alternativen erkunden (WhisperKit SpeakerKit mit Pyannote?)
4. End-to-end **Test mit Multi-Speaker-Audio** — DetailView, Toggle, Continuous-Conversation-View prüfen
5. Phase 3.5 vorbereiten: Speaker-Namen editierbar machen (eigenes Mapping-Model)
6. Whisper-Casing-Thema wieder aufnehmen — als ersten Schritt anderes Whisper-Modell testen (Small/Medium statt Large v3 quantized)
7. Issue an FluidAudio aufmachen wegen Sortformer-`chunk_pre_encoder_embs_out`-Bug, falls sinnvoll
