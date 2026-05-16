import Foundation

nonisolated struct TranscribeLanguage: Hashable, Identifiable {
    let code: String
    let flag: String
    let name: String
    let native: String

    var id: String { code }
}
