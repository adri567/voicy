import Testing
@testable import Voicy

@MainActor
@Suite("BrainViewModel")
struct BrainViewModelTests {

    @Test("localRegistryKeys returns keys of local models only")
    func localKeys() {
        let vm = BrainViewModel()
        let models = [
            llmModel("g", registryKey: "gemma", location: .local),
            llmModel("c", registryKey: nil, location: .cloud),
            llmModel("q", registryKey: "qwen", location: .local)
        ]
        #expect(vm.localRegistryKeys(from: models) == ["gemma", "qwen"])
    }

    @Test("status(of:) reads the status for the model's registry key")
    func statusOf() {
        let vm = BrainViewModel()
        vm.statuses = ["gemma": .active]
        #expect(vm.status(of: llmModel("g", registryKey: "gemma")) == .active)
        #expect(vm.status(of: llmModel("c", registryKey: nil, location: .cloud)) == nil)
    }

    @Test("visibleModels (.all) sorts by status with cloud last, stable ties")
    func visibleAllSorted() {
        let vm = BrainViewModel()
        vm.filter = .all
        let models = [
            llmModel("a", registryKey: "ka", location: .local),    // notInstalled
            llmModel("b", registryKey: "kb", location: .local),    // active
            llmModel("cloud", registryKey: nil, location: .cloud), // cloud → last
            llmModel("d", registryKey: "kd", location: .local)     // installed
        ]
        vm.statuses = ["kb": .active, "kd": .installed]
        #expect(vm.visibleModels(models).map(\.id) == ["b", "d", "a", "cloud"])
    }

    @Test("visibleModels (.local) excludes cloud models")
    func visibleLocal() {
        let vm = BrainViewModel()
        vm.filter = .local
        let models = [
            llmModel("a", registryKey: "ka", location: .local),
            llmModel("cloud", registryKey: nil, location: .cloud)
        ]
        #expect(vm.visibleModels(models).map(\.id) == ["a"])
    }

    @Test("visibleModels (.installed) shows only installed or active models")
    func visibleInstalled() {
        let vm = BrainViewModel()
        vm.filter = .installed
        let models = [
            llmModel("a", registryKey: "ka", location: .local),
            llmModel("b", registryKey: "kb", location: .local)
        ]
        vm.statuses = ["kb": .installed] // ka → notInstalled, filtered out
        #expect(vm.visibleModels(models).map(\.id) == ["b"])
    }
}
