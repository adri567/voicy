import Testing
@testable import Voicy

@MainActor
@Suite("BrainBackend")
struct BrainBackendTests {

    @Test("Apple sentinel key resolves to the Foundation Models backend")
    func appleKeyResolvesToFoundationModels() {
        #expect(BrainBackend.resolve(registryKey: BrainBackend.appleRegistryKey) == .appleFoundationModels)
    }

    @Test("MLX keys, unknown keys and an unset key all resolve to MLX")
    func everythingElseResolvesToMLX() {
        #expect(BrainBackend.resolve(registryKey: "gemma4_e2b_it_4bit") == .mlx)
        #expect(BrainBackend.resolve(registryKey: "qwen2_5_7b") == .mlx)
        #expect(BrainBackend.resolve(registryKey: "totally_unknown") == .mlx)
        #expect(BrainBackend.resolve(registryKey: nil) == .mlx)
    }

    @Test("isBuiltIn is true only for the Apple brain")
    func isBuiltInOnlyForApple() {
        #expect(llmModel("a", registryKey: BrainBackend.appleRegistryKey).isBuiltIn)
        #expect(llmModel("b", registryKey: "gemma4_e2b_it_4bit").isBuiltIn == false)
        #expect(llmModel("c", registryKey: nil, location: .cloud).isBuiltIn == false)
    }
}
