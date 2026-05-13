import Foundation
import MLXLLM
import MLXLMCommon
import MLXHuggingFace
import HuggingFace
import Tokenizers

final class MLXTextCorrectionService: TextCorrectionService {

    nonisolated(unsafe) private var container: ModelContainer?

    nonisolated init() {}

    nonisolated func loadModel(onProgress: (@Sendable (Double) -> Void)? = nil) async throws {
        guard container == nil else { return }
        // Load-from-cache only. Downloads happen exclusively through
        // installModel(progress:), triggered from BrainView.
        guard isModelInstalled() else {
            print("[MLX] Skipping auto-load — Gemma not on disk")
            return
        }
        print("[MLX] Loading Gemma 4 E2B from cache…")
        try await runLoad(onProgress: onProgress)
        print("[MLX] Gemma 4 E2B loaded")
    }

    nonisolated func installModel(progress: @escaping @Sendable (Double) -> Void) async throws {
        if container != nil, isModelInstalled() {
            progress(1.0)
            return
        }
        print("[MLX] Installing Gemma 4 E2B…")
        try await runLoad(onProgress: progress)
        progress(1.0)
        print("[MLX] Gemma 4 E2B installed")
    }

    private nonisolated func runLoad(onProgress: (@Sendable (Double) -> Void)?) async throws {
        container = try await #huggingFaceLoadModelContainer(
            configuration: LLMRegistry.gemma4_e2b_it_4bit,
            progressHandler: { progress in
                guard progress.totalUnitCount > 0 else { return }
                let fraction = Double(progress.completedUnitCount) / Double(progress.totalUnitCount)
                let completed = progress.completedUnitCount / 1_000_000
                let total = progress.totalUnitCount / 1_000_000
                print(String(format: "[MLX] %.1f%% — %d MB / %d MB", fraction * 100, completed, total))
                onProgress?(fraction)
            }
        )
    }

    nonisolated func correct(
        _ text: String,
        sourceLanguage: AppLanguage,
        targetLanguage: AppLanguage?
    ) async throws -> String {
        guard let container else { throw TextCorrectionError.modelNotLoaded }
        let prompt = Self.systemPrompt(source: sourceLanguage, target: targetLanguage)
        let session = ChatSession(container, instructions: prompt)
        let response = try await session.respond(to: text)
        let trimmed = response.trimmingCharacters(in: .whitespaces).trimmingCharacters(in: .newlines)
        return trimmed.isEmpty ? text : trimmed
    }

    // MARK: - Download management

    /// Hugging Face repo ID for the active model. Single source of truth — keep in
    /// sync with the `LLMRegistry.gemma4_e2b_it_4bit` configuration.
    nonisolated private static let repoID = "mlx-community/gemma-4-e2b-it-4bit"

    nonisolated func isModelInstalled() -> Bool {
        ModelStorage.exists(at: ModelStorage.mlxPath(repoID: Self.repoID))
    }

    nonisolated func removeModel() async throws {
        container = nil
        try ModelStorage.remove(at: ModelStorage.mlxPath(repoID: Self.repoID))
        print("[MLX] Gemma 4 E2B removed from disk")
    }

    // MARK: - Prompts

    nonisolated private static func systemPrompt(source: AppLanguage, target: AppLanguage?) -> String {
        if let target {
            let sourceSample = LanguageCatalog.samplePreviews[source.code] ?? ""
            let targetSample = LanguageCatalog.samplePreviews[target.code] ?? ""
            return """
            You are a voice-transcript translator. The user dictates in \(source.name) and wants the result in \(target.name).

            Do all three in one step:
            1. Remove filler words, stutters and repeated words typical for spoken \(source.name).
            2. Fix punctuation, capitalization and grammar.
            3. Translate the cleaned text into \(target.name).

            Output ONLY the final \(target.name) text. No prefix, no quotes, no explanation, no original.

            Example:
            Input (\(source.name)): \(sourceSample)
            Output (\(target.name)): \(targetSample)
            """
        }
        return """
        Fix spelling, punctuation, capitalization. Remove filler words. \
        The input is in \(source.name). Keep the text in \(source.name) — do not translate. \
        Output ONLY the corrected text, nothing else.
        """
    }
}

enum TextCorrectionError: LocalizedError {
    case modelNotLoaded

    var errorDescription: String? {
        "Korrektur-Modell ist noch nicht geladen."
    }
}
