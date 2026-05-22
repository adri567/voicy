import Foundation

extension String {
    /// Number of whitespace/newline-separated words. Single shared definition
    /// so word counts stay consistent across history stats, transcript
    /// segments, and file entries.
    nonisolated var wordCount: Int {
        split(whereSeparator: { $0.isWhitespace || $0.isNewline }).count
    }
}
