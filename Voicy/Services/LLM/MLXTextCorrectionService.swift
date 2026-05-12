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
        print("[MLX] Loading Gemma 4 E2B…")
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
        print("[MLX] Gemma 4 E2B loaded")
    }

    nonisolated func correct(_ text: String) async throws -> String {
        guard let container else { throw TextCorrectionError.modelNotLoaded }
        let systemPrompt = await Self.systemPrompt
        let session = ChatSession(container, instructions: systemPrompt)
        let response = try await session.respond(to: text)
        let trimmed = response.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? text : trimmed
    }

    private static let systemPrompt =
        "Fix spelling, punctuation, capitalization. Remove filler words. Output ONLY the corrected text."
}

enum TextCorrectionError: LocalizedError {
    case modelNotLoaded

    var errorDescription: String? {
        "Korrektur-Modell ist noch nicht geladen."
    }
}

