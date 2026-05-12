import FactoryKit

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
}
