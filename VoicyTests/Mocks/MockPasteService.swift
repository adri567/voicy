@testable import Voicy

/// Captures pasted text so the Cmd+V write-back fallback can be asserted without
/// touching the real pasteboard.
@MainActor
final class MockPasteService: PasteService {
    nonisolated init() {}

    private(set) var pasted: [String] = []

    func paste(_ text: String) { pasted.append(text) }
}
