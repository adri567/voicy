import FactoryKit

extension Container {
    var transcriptionService: Factory<any TranscriptionService> {
        Factory(self) { DefaultTranscriptionService() }
            .singleton
    }

    var pasteService: Factory<any PasteService> {
        Factory(self) { DefaultPasteService() }
            .singleton
    }
}
