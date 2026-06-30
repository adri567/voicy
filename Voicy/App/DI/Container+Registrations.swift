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

    /// Backend-specific singletons. The active brain selects which one the
    /// shared `textCorrectionService` resolves to — mirroring how the
    /// transcription engines are registered above. MLX runs downloaded
    /// Gemma/Qwen models; Foundation Models wraps Apple's built-in on-device
    /// model (zero download).
    var mlxTextCorrectionService: Factory<MLXTextCorrectionService> {
        Factory(self) {
            MainActor.assumeIsolated { MLXTextCorrectionService() }
        }
        .singleton
    }

    var foundationModelsTextCorrectionService: Factory<FoundationModelsTextCorrectionService> {
        Factory(self) { FoundationModelsTextCorrectionService() }
            .singleton
    }

    var textCorrectionService: Factory<any TextCorrectionService> {
        Factory(self) {
            switch BrainBackend.current {
            case .mlx:
                Container.shared.mlxTextCorrectionService()
            case .appleFoundationModels:
                Container.shared.foundationModelsTextCorrectionService()
            }
        }
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

    var selectionService: Factory<any SelectionService> {
        Factory(self) {
            MainActor.assumeIsolated { DefaultSelectionService() }
        }
        .singleton
    }

    /// Plan/entitlement source of truth. Reads the Pro flag from UserDefaults;
    /// later backed by the Lemon Squeezy license check. Not a singleton — it's a
    /// stateless UserDefaults reader, so a fresh instance per resolution is both
    /// correct and keeps tests from leaking a cached plan across suites.
    var entitlementService: Factory<any EntitlementService> {
        Factory(self) {
            MainActor.assumeIsolated { DefaultEntitlementService() }
        }
    }

    /// Metered-usage counters (rolling word window + monthly file minutes).
    /// Stateless over UserDefaults — see `entitlementService` for why it's not a
    /// singleton.
    var usageTrackingService: Factory<any UsageTrackingService> {
        Factory(self) {
            MainActor.assumeIsolated { DefaultUsageTrackingService() }
        }
    }

    /// Keychain-backed secure storage for the license key + instance id.
    /// Stateless and thread-safe — a fresh instance per resolution is fine.
    var secureStore: Factory<any SecureStore> {
        Factory(self) { KeychainStore() }
    }

    /// Lemon Squeezy license API client. Singleton: holds the shared URLSession
    /// and carries no per-call state.
    var lemonSqueezyClient: Factory<any LemonSqueezyClient> {
        Factory(self) { DefaultLemonSqueezyClient() }
            .singleton
    }

    /// License lifecycle (activate/validate/deactivate) and the sole writer of
    /// the Pro flag once a real store is wired up. Singleton so the launch-time
    /// refresh and the Settings UI share one instance.
    var licenseService: Factory<any LicenseService> {
        Factory(self) {
            MainActor.assumeIsolated { DefaultLicenseService() }
        }
        .singleton
    }

    /// Observable mirror of the Pro flag for the UI. Singleton so the window
    /// (via `.environment`) and the Settings/launch paths share one instance.
    var entitlementStore: Factory<EntitlementStore> {
        Factory(self) {
            MainActor.assumeIsolated { EntitlementStore() }
        }
        .singleton
    }

    /// Crash reporting + telemetry. Resolves to the Sentry-backed service only
    /// when a real DSN is bundled (`Sentry.plist`); otherwise a no-op, so dev
    /// and test builds never start the SDK. Singleton so launch-time `start()`
    /// and the Settings toggle share one instance.
    var telemetryService: Factory<any TelemetryService> {
        Factory(self) {
            let config = SentryConfig.loadFromBundle()
            return config.isConfigured
                ? DefaultTelemetryService(config: config)
                : NoopTelemetryService()
        }
        .singleton
    }
}
