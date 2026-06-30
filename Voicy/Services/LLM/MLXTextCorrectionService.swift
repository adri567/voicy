import Foundation
import OSLog
import MLXLLM
import MLXLMCommon
import MLXHuggingFace
import HuggingFace
import Tokenizers

actor MLXTextCorrectionService: TextCorrectionService {

    private var container: ModelContainer?
    /// In-flight load, shared by concurrent `loadModel()` callers so the model
    /// is loaded once instead of duplicated across overlapping calls.
    private var loadTask: Task<Void, Error>?

    init() {}

    func loadModel(onProgress: (@Sendable (Double) -> Void)? = nil) async throws {
        if container != nil { return }
        if let loadTask { return try await loadTask.value }
        let task = Task<Void, Error> { try await self.performLoad(onProgress: onProgress) }
        loadTask = task
        defer { loadTask = nil }
        try await task.value
    }

    private func performLoad(onProgress: (@Sendable (Double) -> Void)?) async throws {
        guard container == nil else { return }
        // Load-from-cache only. Downloads happen exclusively through
        // installModel(progress:), triggered from BrainView.
        guard isModelInstalled() else {
            Log.llm.debug("MLX: skipping auto-load — model not on disk")
            return
        }
        Log.llm.debug("MLX: loading \(Self.activeRegistryKey, privacy: .public) from cache")
        try await runLoad(onProgress: onProgress)
        Log.llm.debug("MLX: \(Self.activeRegistryKey, privacy: .public) loaded")
    }

    func installModel(progress: @escaping @Sendable (DownloadPhase) -> Void) async throws {
        if container != nil, isModelInstalled() { return }
        Log.llm.debug("MLX: installing \(Self.activeRegistryKey, privacy: .public)")
        progress(.preparing)
        // `runLoad` downloads *and* builds the container (GPU/RAM). The byte
        // fraction only covers the download; once it hits 1.0 the container is
        // still building, so map that tail to `.finalizing`.
        try await runLoad { fraction in
            progress(fraction >= 1.0 ? .finalizing : .downloading(fraction))
        }
        Log.llm.debug("MLX: \(Self.activeRegistryKey, privacy: .public) installed")
    }

    private func runLoad(onProgress: (@Sendable (Double) -> Void)?) async throws {
        let config = Self.configuration(for: Self.activeRegistryKey)
        container = try await #huggingFaceLoadModelContainer(
            configuration: config,
            progressHandler: { progress in
                guard progress.totalUnitCount > 0 else { return }
                let fraction = Double(progress.completedUnitCount) / Double(progress.totalUnitCount)
                let completed = progress.completedUnitCount / 1_000_000
                let total = progress.totalUnitCount / 1_000_000
                Log.llm.debug("MLX: \(fraction * 100, format: .fixed(precision: 1))% — \(completed) MB / \(total) MB")
                onProgress?(fraction)
            }
        )
    }

    /// Currently selected LLM registry key (from UserDefaults).
    /// Falls back to the default if the stored value is not in the supported
    /// library (e.g. `llama3_2_3B_4bit` was removed because of poor multilingual
    /// performance and Q&A-drift on translation prompts).
    nonisolated static var activeRegistryKey: String {
        let stored = UserDefaults.standard.string(forKey: Preferences.Key.llmRegistryKey) ?? defaultRegistryKey
        return supportedRegistryKeys.contains(stored) ? stored : defaultRegistryKey
    }

    nonisolated static let defaultRegistryKey = "gemma4_e2b_it_4bit"
    nonisolated static let supportedRegistryKeys = [
        "gemma4_e2b_it_4bit",
        "gemma4_e4b_it_4bit",
        "qwen2_5_7b",
    ]

    func correct(
        _ text: String,
        mode: Mode,
        sourceLanguage: AppLanguage
    ) async throws -> String {
        guard let container else { throw TextCorrectionError.modelNotLoaded }
        // `.raw` shouldn't reach this method — the recording pipeline branches
        // before calling. Be defensive and return the input unchanged.
        if mode.type == .raw { return text }

        let prompt = CorrectionPrompts.systemPrompt(for: mode, source: sourceLanguage)
        let wrapped = CorrectionPrompts.wrappedInput(for: mode, transcript: text)
        let session = ChatSession(container, instructions: prompt)
        // Deterministic sampling for every mode: pick the highest-probability
        // token at every step. Removes "creative" drift that small models
        // sometimes fall into (answering questions, drifting topic, etc.).
        session.generateParameters.temperature = 0
        session.generateParameters.topP = 1.0
        let response = try await session.respond(to: wrapped)
        let cleaned = CorrectionPrompts.stripReasoning(response)
            .trimmingCharacters(in: .whitespaces)
            .trimmingCharacters(in: .newlines)
        return cleaned.isEmpty ? text : cleaned
    }

    func proofread(_ text: String) async throws -> String {
        try await transform(text, instructions: CorrectionPrompts.proofreadSystemPrompt)
    }

    func rephrase(_ text: String) async throws -> String {
        try await transform(text, instructions: CorrectionPrompts.rephraseSystemPrompt)
    }

    /// Shared selection-transform path: feeds the tag-wrapped text through a
    /// deterministic ChatSession with the given system prompt and cleans the
    /// reply. Returns the input unchanged if the model emits nothing usable.
    private func transform(_ text: String, instructions: String) async throws -> String {
        guard let container else { throw TextCorrectionError.modelNotLoaded }

        let session = ChatSession(container, instructions: instructions)
        session.generateParameters.temperature = 0
        session.generateParameters.topP = 1.0
        let response = try await session.respond(to: "<TEXT>\n\(text)\n</TEXT>")
        let cleaned = CorrectionPrompts.stripReasoning(response)
            .trimmingCharacters(in: .whitespaces)
            .trimmingCharacters(in: .newlines)
        return cleaned.isEmpty ? text : cleaned
    }

    // MARK: - Download management

    nonisolated func isModelInstalled() -> Bool {
        Self.isInstalled(registryKey: Self.activeRegistryKey)
    }

    nonisolated func ensureModelAvailable() -> Bool {
        Self.ensureActiveBrainInstalled() != nil
    }

    func removeModel() async throws {
        container = nil
        try Self.remove(registryKey: Self.activeRegistryKey)
        Log.llm.debug("MLX: \(Self.activeRegistryKey, privacy: .public) removed from disk")
    }

    // MARK: - Static API (any model, not just the active one)

    nonisolated static func isInstalled(registryKey: String) -> Bool {
        guard let repoID = repoID(for: registryKey) else { return false }
        return ModelStorage.exists(at: ModelStorage.mlxPath(repoID: repoID))
    }

    /// True iff any supported brain is on disk — regardless of which one is
    /// currently the "active" registry key.
    nonisolated static func isAnyBrainInstalled() -> Bool {
        supportedRegistryKeys.contains { isInstalled(registryKey: $0) }
    }

    /// If the active brain isn't on disk but another supported brain is,
    /// promote that fallback to active in UserDefaults. Lets the user download
    /// a brain in BrainView without having to also click "Set as default" for
    /// the correction pipeline to pick it up.
    @discardableResult
    nonisolated static func ensureActiveBrainInstalled() -> String? {
        let current = activeRegistryKey
        if isInstalled(registryKey: current) { return current }
        guard let fallback = supportedRegistryKeys.first(where: { isInstalled(registryKey: $0) }) else {
            return nil
        }
        UserDefaults.standard.set(fallback, forKey: Preferences.Key.llmRegistryKey)
        return fallback
    }

    /// Downloads the model into the HuggingFace cache. Loads it briefly into a
    /// container to trigger the download, then discards the container — the
    /// files remain on disk. RAM-loading of the *active* model happens on next
    /// app launch. The byte fraction only covers the download; the container
    /// build that follows the last byte is reported as `.finalizing`.
    nonisolated static func install(registryKey: String, progress: @escaping @Sendable (DownloadPhase) -> Void) async throws {
        if isInstalled(registryKey: registryKey) { return }
        let config = configuration(for: registryKey)
        progress(.preparing)
        _ = try await #huggingFaceLoadModelContainer(
            configuration: config,
            progressHandler: { p in
                guard p.totalUnitCount > 0 else { return }
                let fraction = Double(p.completedUnitCount) / Double(p.totalUnitCount)
                progress(fraction >= 1.0 ? .finalizing : .downloading(fraction))
            }
        )
    }

    nonisolated static func remove(registryKey: String) throws {
        guard let repoID = repoID(for: registryKey) else { return }
        try ModelStorage.remove(at: ModelStorage.mlxPath(repoID: repoID))
    }

    nonisolated static func configuration(for registryKey: String) -> ModelConfiguration {
        switch registryKey {
        case "gemma4_e2b_it_4bit":  return LLMRegistry.gemma4_e2b_it_4bit
        case "gemma4_e4b_it_4bit":  return LLMRegistry.gemma4_e4b_it_4bit
        case "qwen2_5_7b":          return LLMRegistry.qwen2_5_7b
        default:                    return LLMRegistry.gemma4_e2b_it_4bit
        }
    }

    nonisolated static func repoID(for registryKey: String) -> String? {
        switch registryKey {
        case "gemma4_e2b_it_4bit": return "mlx-community/gemma-4-e2b-it-4bit"
        case "gemma4_e4b_it_4bit": return "mlx-community/gemma-4-e4b-it-4bit"
        case "qwen2_5_7b":         return "mlx-community/Qwen2.5-7B-Instruct-4bit"
        default: return nil
        }
    }
}

nonisolated enum TextCorrectionError: LocalizedError {
    case modelNotLoaded

    var errorDescription: String? {
        "Correction model not loaded yet."
    }
}
