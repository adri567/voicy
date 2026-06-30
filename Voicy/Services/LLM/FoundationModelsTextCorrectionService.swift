import Foundation
import FoundationModels
import OSLog

/// `TextCorrectionService` backed by Apple's built-in on-device model
/// (`SystemLanguageModel.default`, Apple Intelligence). Unlike the MLX backend
/// there is nothing to download or load into RAM — the model ships with the OS
/// and is resident whenever Apple Intelligence is on — so the install/remove/
/// load methods are no-ops and "installed" means "available".
///
/// Stateless: the only stored value is the `Sendable` model handle, so this is a
/// `nonisolated final class` rather than an actor. Each correction spins up a
/// fresh single-turn `LanguageModelSession` (Apple's guidance for independent
/// requests), mirroring how the MLX backend creates a `ChatSession` per call.
nonisolated final class FoundationModelsTextCorrectionService: TextCorrectionService {

    private let model = SystemLanguageModel.default

    /// Greedy sampling — the deterministic-output counterpart to the MLX
    /// backend's `temperature = 0`. Keeps small-model "creative drift"
    /// (answering questions, switching topic) out of the correction path.
    private static let deterministic = GenerationOptions(temperature: 0)

    init() {}

    // MARK: - Correction

    func correct(
        _ text: String,
        mode: Mode,
        sourceLanguage: AppLanguage
    ) async throws -> String {
        // `.raw` never reaches here — the recording pipeline branches first.
        if mode.type == .raw { return text }
        guard model.isAvailable else { throw TextCorrectionError.modelNotLoaded }

        let instructions = CorrectionPrompts.systemPrompt(for: mode, source: sourceLanguage)
        let wrapped = CorrectionPrompts.wrappedInput(for: mode, transcript: text)
        return await respond(instructions: instructions, prompt: wrapped, fallback: text)
    }

    func proofread(_ text: String) async throws -> String {
        guard model.isAvailable else { throw TextCorrectionError.modelNotLoaded }
        return await respond(
            instructions: CorrectionPrompts.proofreadSystemPrompt,
            prompt: "<TEXT>\n\(text)\n</TEXT>",
            fallback: text
        )
    }

    func rephrase(_ text: String) async throws -> String {
        guard model.isAvailable else { throw TextCorrectionError.modelNotLoaded }
        return await respond(
            instructions: CorrectionPrompts.rephraseSystemPrompt,
            prompt: "<TEXT>\n\(text)\n</TEXT>",
            fallback: text
        )
    }

    /// Runs one deterministic single-turn request. On any generation failure
    /// (context-window overflow, guardrail refusal, unsupported language, …) it
    /// degrades to the untouched input rather than failing the whole dictation —
    /// the user still gets their raw transcript.
    private func respond(instructions: String, prompt: String, fallback: String) async -> String {
        let session = LanguageModelSession(instructions: instructions)
        do {
            let response = try await session.respond(to: prompt, options: Self.deterministic)
            let cleaned = CorrectionPrompts.stripReasoning(response.content)
                .trimmingCharacters(in: .whitespaces)
                .trimmingCharacters(in: .newlines)
            return cleaned.isEmpty ? fallback : cleaned
        } catch {
            Log.llm.error("FoundationModels: correction failed — \(error.localizedDescription, privacy: .public)")
            return fallback
        }
    }

    // MARK: - Download management (no-ops: the model ships with the OS)

    func loadModel(onProgress: (@Sendable (Double) -> Void)? = nil) async throws {
        if model.isAvailable { onProgress?(1.0) }
    }

    func installModel(progress: @escaping @Sendable (DownloadPhase) -> Void) async throws {
        // Nothing to download — the OS manages the model. Signal completion so
        // any UI awaiting a terminal phase resolves cleanly.
        progress(.finalizing)
    }

    func removeModel() async throws {}

    func isModelInstalled() -> Bool { model.isAvailable }

    func ensureModelAvailable() -> Bool { model.isAvailable }

    // MARK: - Availability (UI)

    /// Maps the framework's availability into the UI-facing `BrainAvailability`,
    /// keeping the `FoundationModels` import contained to this file.
    static func availability() -> BrainAvailability {
        switch SystemLanguageModel.default.availability {
        case .available:
            return .available
        case .unavailable(.deviceNotEligible):
            return .unavailable(reason: "Not supported on this Mac.")
        case .unavailable(.appleIntelligenceNotEnabled):
            return .unavailable(reason: "Turn on Apple Intelligence in System Settings.")
        case .unavailable(.modelNotReady):
            return .unavailable(reason: "Apple Intelligence is still preparing — try again shortly.")
        case .unavailable:
            return .unavailable(reason: "Currently unavailable.")
        }
    }
}
