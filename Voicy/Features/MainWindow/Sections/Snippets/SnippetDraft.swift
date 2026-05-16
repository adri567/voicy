import Foundation

struct SnippetDraft: Identifiable {
    let id: UUID
    let existingID: UUID?
    var triggers: [String]
    var replacement: String
    var enabled: Bool

    init() {
        self.id = UUID()
        self.existingID = nil
        self.triggers = [""]
        self.replacement = ""
        self.enabled = true
    }

    init(_ snippet: SnippetDTO) {
        self.id = UUID()
        self.existingID = snippet.id
        self.triggers = snippet.triggers
        self.replacement = snippet.replacement
        self.enabled = snippet.enabled
    }
}
