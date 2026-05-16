import Foundation

protocol SnippetService: Sendable {
    /// Apply every enabled snippet's trigger replacement to `text`.
    /// Pure string operation — no LLM, no network.
    nonisolated func apply(to text: String) async -> String

    /// All snippets, newest first. Used by the CRUD UI.
    nonisolated func all() async throws -> [SnippetDTO]

    /// Create a new snippet. Empty triggers are stripped; if none remain, throws.
    nonisolated func create(triggers: [String], replacement: String) async throws -> SnippetDTO

    /// Update by id. Same trigger/replacement rules as create.
    nonisolated func update(id: UUID, triggers: [String], replacement: String, enabled: Bool) async throws

    /// Permanently delete by id.
    nonisolated func delete(id: UUID) async throws
}

/// Sendable snapshot of a Snippet for crossing actor boundaries.
nonisolated struct SnippetDTO: Identifiable, Hashable, Sendable {
    let id: UUID
    let triggers: [String]
    let replacement: String
    let enabled: Bool
    let createdAt: Date
}

nonisolated enum SnippetError: LocalizedError {
    case emptyTriggers
    case emptyReplacement
    case notFound

    var errorDescription: String? {
        switch self {
        case .emptyTriggers:    return "A snippet needs at least one trigger phrase."
        case .emptyReplacement: return "A snippet needs a replacement text."
        case .notFound:         return "Snippet not found."
        }
    }
}
