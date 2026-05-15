import FactoryKit
import SwiftData

extension Container {
    var transcriptionService: Factory<any TranscriptionService> {
        Factory(self) {
            switch TranscriptionEngine.current {
            case .whisper:  DefaultTranscriptionService()
            case .parakeet: ParakeetTranscriptionService()
            }
        }
        .singleton
    }

    var pasteService: Factory<any PasteService> {
        Factory(self) { DefaultPasteService() }
            .singleton
    }

    var textCorrectionService: Factory<any TextCorrectionService> {
        Factory(self) { MLXTextCorrectionService() }
            .singleton
    }

    var modelContainer: Factory<ModelContainer> {
        Factory(self) {
            do {
                return try ModelContainer(for: TranscriptionEntry.self)
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

    var targetAppService: Factory<any TargetAppService> {
        Factory(self) { DefaultTargetAppService() }
            .singleton
    }

    var modeCycleService: Factory<ModeCycleService> {
        Factory(self) {
            MainActor.assumeIsolated { ModeCycleService() }
        }
        .singleton
    }
}
