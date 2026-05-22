import Foundation
@testable import Voicy

/// Builds a `SnippetDTO` with sensible defaults for snippet-matching tests.
func snippet(_ triggers: [String], _ replacement: String, enabled: Bool = true) -> SnippetDTO {
    SnippetDTO(
        id: UUID(),
        triggers: triggers,
        replacement: replacement,
        enabled: enabled,
        createdAt: Date()
    )
}
