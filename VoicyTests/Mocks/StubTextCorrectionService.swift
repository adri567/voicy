@testable import Voicy
import Foundation

/// Error thrown by `StubTextCorrectionService` for the failure outcome.
struct StubProofreadError: Error {}

/// How the stub's `proofread(_:)` behaves.
enum ProofreadOutcome: Sendable {
    /// Returns a fixed corrected string.
    case success(String)
    /// Returns the input unchanged (simulates "nothing to fix").
    case echo
    /// Throws `StubProofreadError`.
    case failure
    /// Never returns (until cancelled) — exercises the timeout path.
    case hang
}

/// Configurable `TextCorrectionService` for proofread-flow tests. All config is
/// immutable `let` so the `nonisolated` protocol methods can read it without
/// actor hops.
final class StubTextCorrectionService: TextCorrectionService {
    private nonisolated let available: Bool
    private nonisolated let outcome: ProofreadOutcome
    private nonisolated let loadDelay: Duration

    nonisolated init(
        available: Bool = true,
        outcome: ProofreadOutcome = .success("corrected"),
        loadDelay: Duration = .zero
    ) {
        self.available = available
        self.outcome = outcome
        self.loadDelay = loadDelay
    }

    nonisolated func proofread(_ text: String) async throws -> String {
        try await produce(text)
    }

    nonisolated func rephrase(_ text: String) async throws -> String {
        try await produce(text)
    }

    private nonisolated func produce(_ text: String) async throws -> String {
        switch outcome {
        case .success(let result): return result
        case .echo:                return text
        case .failure:             throw StubProofreadError()
        case .hang:
            try await Task.sleep(for: .seconds(3600))
            return text
        }
    }

    nonisolated func ensureModelAvailable() -> Bool { available }
    nonisolated func isModelInstalled() -> Bool { available }
    nonisolated func loadModel(onProgress: (@Sendable (Double) -> Void)?) async throws {
        if loadDelay > .zero { try await Task.sleep(for: loadDelay) }
    }
    nonisolated func correct(_ text: String, mode: Mode, sourceLanguage: AppLanguage) async throws -> String { text }
    nonisolated func installModel(progress: @escaping @Sendable (DownloadPhase) -> Void) async throws {}
    nonisolated func removeModel() async throws {}
}
