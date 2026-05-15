import Foundation
import SwiftData

@Model
final class Snippet {
    var id: UUID
    var triggers: [String]
    var replacement: String
    var enabled: Bool
    var createdAt: Date

    init(
        triggers: [String],
        replacement: String,
        enabled: Bool = true,
        createdAt: Date = Date()
    ) {
        self.id = UUID()
        self.triggers = triggers
        self.replacement = replacement
        self.enabled = enabled
        self.createdAt = createdAt
    }
}
