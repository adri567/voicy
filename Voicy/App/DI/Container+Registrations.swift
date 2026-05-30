import FactoryKit
import SwiftData

extension Container {
    /// Engine-specific singletons. Used by the Transcribe page so the user can
    /// pick the file-transcription engine independently of the global mic
    /// engine. Each is loaded lazily and shared with the mic path when it's
    /// the active global engine.
    var whisperTranscriptionService: Factory<DefaultTranscriptionService> {
        Factory(self) {
            MainActor.assumeIsolated { DefaultTranscriptionService() }
        }
        .singleton
    }

    var parakeetTranscriptionService: Factory<ParakeetTranscriptionService> {
        Factory(self) {
            MainActor.assumeIsolated { ParakeetTranscriptionService() }
        }
        .singleton
    }

    var transcriptionService: Factory<any TranscriptionService> {
        Factory(self) {
            MainActor.assumeIsolated {
                switch TranscriptionEngine.current {
                case .whisper:  Container.shared.whisperTranscriptionService()
                case .parakeet: Container.shared.parakeetTranscriptionService()
                }
            }
        }
    }

    /// Speaker-diarization (Sortformer via FluidAudio). Add-on to the
    /// transcription engines, not an alternative — runs in parallel when
    /// installed. If the user hasn't installed the model, the service is still
    /// constructed but `isModelInstalled()` returns false and callers skip the
    /// diarize step.
    var diarizationService: Factory<any DiarizationService> {
        Factory(self) {
            MainActor.assumeIsolated { FluidAudioDiarizationService() }
        }
        .singleton
    }

    var pasteService: Factory<any PasteService> {
        Factory(self) { DefaultPasteService() }
            .singleton
    }

    var textCorrectionService: Factory<any TextCorrectionService> {
        Factory(self) {
            MainActor.assumeIsolated { MLXTextCorrectionService() }
        }
        .singleton
    }

    var modelContainer: Factory<ModelContainer> {
        Factory(self) {
            do {
                return try ModelContainer(
                    for: TranscriptionEntry.self,
                    FileTranscriptionEntry.self,
                    Snippet.self
                )
            } catch {
                fatalError("Failed to create ModelContainer: \(error)")
            }
        }
        .singleton
    }

    var transcriptionHistoryService: Factory<any TranscriptionHistoryService> {
        Factory(self) {
            SwiftDataTranscriptionHistoryService(container: Container.shared.modelContainer())
        }
        .singleton
    }

    var fileTranscriptionHistoryService: Factory<any FileTranscriptionHistoryService> {
        Factory(self) {
            SwiftDataFileTranscriptionHistoryService(container: Container.shared.modelContainer())
        }
        .singleton
    }

    var snippetService: Factory<any SnippetService> {
        Factory(self) {
            DefaultSnippetService(container: Container.shared.modelContainer())
        }
        .singleton
    }

    var targetAppService: Factory<any TargetAppService> {
        Factory(self) { DefaultTargetAppService() }
            .singleton
    }

    var permissionService: Factory<any PermissionService> {
        Factory(self) { DefaultPermissionService() }
            .singleton
    }

    var modeCycleService: Factory<ModeCycleService> {
        Factory(self) {
            MainActor.assumeIsolated { ModeCycleService() }
        }
        .singleton
    }

    var audioInputDeviceService: Factory<any AudioInputDeviceService> {
        Factory(self) {
            MainActor.assumeIsolated { DefaultAudioInputDeviceService() }
        }
        .singleton
    }

    var updateService: Factory<any UpdateService> {
        Factory(self) {
            MainActor.assumeIsolated { SparkleUpdateService() }
        }
        .singleton
    }
}
