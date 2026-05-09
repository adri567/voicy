import FactoryKit

extension Container {
    var transcriptionService: Factory<any TranscriptionService> {
        Factory(self) { DefaultTranscriptionService() }
            .singleton
    }
}
