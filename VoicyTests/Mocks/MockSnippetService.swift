@testable import Voicy
import Foundation

/// Minimal `SnippetService` returning a fixed list from `all()`. Enough to drive
/// `SnippetsViewModel.reload()` so the snippet-count gate can be asserted. The
/// list is immutable (`let`) so every method is `nonisolated` and Sendable,
/// matching the protocol without actor hops — the CRUD methods are no-ops since
/// the gate tests only read the count.
final class MockSnippetService: SnippetService {
    private let stored: [SnippetDTO]

    nonisolated init(count: Int = 0) {
        self.stored = (0..<count).map { i in
            SnippetDTO(
                id: UUID(),
                triggers: ["t\(i)"],
                replacement: "r\(i)",
                enabled: true,
                createdAt: .now
            )
        }
    }

    nonisolated func apply(to text: String) async -> String { text }
    nonisolated func all() async throws -> [SnippetDTO] { stored }
    nonisolated func create(triggers: [String], replacement: String) async throws -> SnippetDTO {
        SnippetDTO(id: UUID(), triggers: triggers, replacement: replacement, enabled: true, createdAt: .now)
    }
    nonisolated func update(id: UUID, triggers: [String], replacement: String, enabled: Bool) async throws {}
    nonisolated func delete(id: UUID) async throws {}
}
