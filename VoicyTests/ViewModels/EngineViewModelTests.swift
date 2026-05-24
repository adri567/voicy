import Testing
@testable import Voicy

@MainActor
@Suite("EngineViewModel")
struct EngineViewModelTests {

    @Test("whisperIDs filters to whisper-family library IDs")
    func whisperIDs() {
        let vm = EngineViewModel()
        let models = [
            engineModel("openai_whisper-small", family: .whisper),
            engineModel("v3", family: .parakeet)
        ]
        #expect(vm.whisperIDs(from: models) == ["openai_whisper-small"])
    }

    @Test("parakeetVersions filters to parakeet-family library IDs")
    func parakeetVersions() {
        let vm = EngineViewModel()
        let models = [
            engineModel("openai_whisper-small", family: .whisper),
            engineModel("v3", family: .parakeet)
        ]
        #expect(vm.parakeetVersions(from: models) == ["v3"])
    }

    @Test("sortedModels orders active → installed → downloading → not-installed")
    func sortedByStatus() {
        let vm = EngineViewModel()
        let models = [engineModel("a"), engineModel("b"), engineModel("c"), engineModel("d")]
        vm.statuses = [
            "a": .notInstalled,
            "b": .active,
            "c": .downloading(.downloading(0.5)),
            "d": .installed
        ]
        #expect(vm.sortedModels(models).map(\.libraryID) == ["b", "d", "c", "a"])
    }

    @Test("sortedModels keeps original order on status ties (stable)")
    func stableTies() {
        let vm = EngineViewModel()
        let models = [engineModel("a"), engineModel("b"), engineModel("c")]
        // No statuses → all default to .notInstalled → original order preserved.
        #expect(vm.sortedModels(models).map(\.libraryID) == ["a", "b", "c"])
    }
}
