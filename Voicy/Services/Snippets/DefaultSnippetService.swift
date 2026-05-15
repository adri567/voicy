import Foundation
import SwiftData

final class DefaultSnippetService: SnippetService {

    private let container: ModelContainer

    nonisolated init(container: ModelContainer) {
        self.container = container
    }

    // MARK: - CRUD

    nonisolated func all() async throws -> [SnippetDTO] {
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<Snippet>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        let entities = try context.fetch(descriptor)
        return entities.map(Self.toDTO)
    }

    nonisolated func create(triggers: [String], replacement: String) async throws -> SnippetDTO {
        let cleanedTriggers = Self.cleanTriggers(triggers)
        guard !cleanedTriggers.isEmpty else { throw SnippetError.emptyTriggers }
        let cleanedReplacement = replacement.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanedReplacement.isEmpty else { throw SnippetError.emptyReplacement }

        let context = ModelContext(container)
        let snippet = Snippet(triggers: cleanedTriggers, replacement: cleanedReplacement)
        context.insert(snippet)
        try context.save()
        return Self.toDTO(snippet)
    }

    nonisolated func update(id: UUID, triggers: [String], replacement: String, enabled: Bool) async throws {
        let cleanedTriggers = Self.cleanTriggers(triggers)
        guard !cleanedTriggers.isEmpty else { throw SnippetError.emptyTriggers }
        let cleanedReplacement = replacement.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanedReplacement.isEmpty else { throw SnippetError.emptyReplacement }

        let context = ModelContext(container)
        let descriptor = FetchDescriptor<Snippet>(
            predicate: #Predicate { $0.id == id }
        )
        guard let snippet = try context.fetch(descriptor).first else {
            throw SnippetError.notFound
        }
        snippet.triggers = cleanedTriggers
        snippet.replacement = cleanedReplacement
        snippet.enabled = enabled
        try context.save()
    }

    nonisolated func delete(id: UUID) async throws {
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<Snippet>(
            predicate: #Predicate { $0.id == id }
        )
        guard let snippet = try context.fetch(descriptor).first else {
            throw SnippetError.notFound
        }
        context.delete(snippet)
        try context.save()
    }

    // MARK: - Apply (the match algorithm)

    nonisolated func apply(to text: String) async -> String {
        guard !text.isEmpty else { return text }
        let snippets: [SnippetDTO]
        do {
            snippets = try await all()
        } catch {
            return text
        }
        let active = snippets.filter(\.enabled)
        guard !active.isEmpty else { return text }
        return Self.applyReplacements(text: text, snippets: active)
    }

    // MARK: - Testable pure logic

    /// Apply all active snippets' triggers to `text`. Pure function — no IO.
    /// Algorithm:
    /// 1. Normalize both sides (lowercase, dashes→spaces, multi-spaces collapsed).
    /// 2. For every trigger, find all match-ranges in the normalized text.
    /// 3. Resolve conflicts: longest match wins; on ties, leftmost wins.
    /// 4. Map normalized ranges back to original-text indices and splice replacements.
    nonisolated static func applyReplacements(text: String, snippets: [SnippetDTO]) -> String {
        let normalized = NormalizedText(original: text)
        var candidates: [Match] = []

        for snippet in snippets {
            for trigger in snippet.triggers {
                let triggerNorm = normalize(trigger)
                guard !triggerNorm.isEmpty else { continue }
                candidates.append(contentsOf: findMatches(
                    triggerNorm: triggerNorm,
                    replacement: snippet.replacement,
                    in: normalized.normalized
                ))
            }
        }

        // Standalone case: text is essentially just a trigger (with optional
        // trailing punctuation). Strip terminal punctuation from the normalized
        // text and try once more, so "best regards." still matches.
        if candidates.isEmpty {
            let stripped = stripTrailingPunctuation(normalized.normalized)
            if stripped != normalized.normalized {
                for snippet in snippets {
                    for trigger in snippet.triggers {
                        let triggerNorm = normalize(trigger)
                        guard !triggerNorm.isEmpty else { continue }
                        if stripped == triggerNorm {
                            return snippet.replacement
                        }
                    }
                }
            }
            return text
        }

        // Sort: longest first; ties go leftmost first.
        candidates.sort { lhs, rhs in
            if lhs.length != rhs.length { return lhs.length > rhs.length }
            return lhs.startNorm < rhs.startNorm
        }

        // Greedy: accept candidates that don't overlap any already-accepted match.
        var accepted: [Match] = []
        for candidate in candidates {
            let endNorm = candidate.startNorm + candidate.length
            let conflict = accepted.contains { existing in
                let existingEnd = existing.startNorm + existing.length
                return candidate.startNorm < existingEnd && endNorm > existing.startNorm
            }
            if !conflict { accepted.append(candidate) }
        }

        // Apply in original-text order, right-to-left (so earlier ranges
        // stay valid as we splice).
        accepted.sort { $0.startNorm > $1.startNorm }
        var result = Array(text)
        for match in accepted {
            let origStart = normalized.originalIndex(forNormalized: match.startNorm)
            let origEnd = normalized.originalIndex(forNormalized: match.startNorm + match.length)
            guard origStart <= origEnd, origEnd <= result.count else { continue }
            result.replaceSubrange(origStart..<origEnd, with: Array(match.replacement))
        }
        return String(result)
    }

    // MARK: - Normalization

    /// Normalize for comparison: lowercase, dashes → space, collapse whitespace.
    /// Leading whitespace is also dropped so a string that starts with a dash
    /// (e.g. Whisper outputting "-Mail") doesn't get a spurious leading space.
    nonisolated static func normalize(_ s: String) -> String {
        var out = ""
        out.reserveCapacity(s.count)
        var lastWasSpace = false
        for ch in s.lowercased() {
            if ch == "-" || ch == "—" || ch == "–" || ch == "_" {
                if !lastWasSpace, !out.isEmpty { out.append(" ") }
                lastWasSpace = true
            } else if ch.isWhitespace {
                if !lastWasSpace, !out.isEmpty { out.append(" ") }
                lastWasSpace = true
            } else {
                out.append(ch)
                lastWasSpace = false
            }
        }
        if out.hasSuffix(" ") { out.removeLast() }
        return out
    }

    nonisolated private static func stripTrailingPunctuation(_ s: String) -> String {
        var out = s
        while let last = out.last, ".,;:!?".contains(last) || last.isWhitespace {
            out.removeLast()
        }
        return out
    }

    nonisolated private static func cleanTriggers(_ triggers: [String]) -> [String] {
        let trimmed = triggers
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        // Dedupe (case-insensitive) preserving first occurrence.
        var seen = Set<String>()
        var out: [String] = []
        for t in trimmed {
            let key = t.lowercased()
            if seen.insert(key).inserted { out.append(t) }
        }
        return out
    }

    // MARK: - Matching

    nonisolated private struct Match {
        let startNorm: Int  // index into normalized.normalized
        let length: Int     // length in normalized chars
        let replacement: String
    }

    /// Find all non-overlapping word-boundary matches of `triggerNorm` in
    /// `haystackNorm`. Both inputs must already be normalized.
    nonisolated private static func findMatches(
        triggerNorm: String,
        replacement: String,
        in haystackNorm: String
    ) -> [Match] {
        guard !triggerNorm.isEmpty, !haystackNorm.isEmpty else { return [] }
        let hay = Array(haystackNorm)
        let needle = Array(triggerNorm)
        let n = needle.count
        var matches: [Match] = []
        var i = 0
        while i <= hay.count - n {
            // Word-boundary check on the left.
            if i > 0 {
                let before = hay[i - 1]
                if before.isLetter || before.isNumber {
                    i += 1
                    continue
                }
            }
            // Compare needle.
            var ok = true
            for k in 0..<n {
                if hay[i + k] != needle[k] { ok = false; break }
            }
            if !ok {
                i += 1
                continue
            }
            // Word-boundary check on the right.
            let rightIdx = i + n
            if rightIdx < hay.count {
                let after = hay[rightIdx]
                if after.isLetter || after.isNumber {
                    i += 1
                    continue
                }
            }
            matches.append(Match(startNorm: i, length: n, replacement: replacement))
            i += n
        }
        return matches
    }

    // MARK: - DTO mapping

    nonisolated private static func toDTO(_ s: Snippet) -> SnippetDTO {
        SnippetDTO(
            id: s.id,
            triggers: s.triggers,
            replacement: s.replacement,
            enabled: s.enabled,
            createdAt: s.createdAt
        )
    }
}

// MARK: - Normalized text with index map

/// Holds the normalized form of an input string plus an index mapping back
/// to the original. Each character in `normalized` carries the index of the
/// FIRST original character that contributed to it.
nonisolated private struct NormalizedText {
    let normalized: String
    private let mapping: [Int]  // mapping[i] = index in original

    init(original: String) {
        let chars = Array(original)
        var out = ""
        var map: [Int] = []
        out.reserveCapacity(chars.count)
        map.reserveCapacity(chars.count)

        var lastWasSpace = false
        var lastSpaceOrigIdx = 0
        for (idx, ch) in chars.enumerated() {
            let scalar = ch.lowercased().first ?? ch
            if ch == "-" || ch == "—" || ch == "–" || ch == "_" {
                if !lastWasSpace, !out.isEmpty {
                    out.append(" ")
                    map.append(idx)
                }
                lastWasSpace = true
                lastSpaceOrigIdx = idx
            } else if ch.isWhitespace {
                if !lastWasSpace, !out.isEmpty {
                    out.append(" ")
                    map.append(idx)
                }
                lastWasSpace = true
                lastSpaceOrigIdx = idx
            } else {
                out.append(scalar)
                map.append(idx)
                lastWasSpace = false
            }
        }
        // Trim trailing whitespace from normalized but keep mapping consistent.
        if out.hasSuffix(" ") {
            out.removeLast()
            if !map.isEmpty { map.removeLast() }
        }
        _ = lastSpaceOrigIdx  // silence unused warning
        self.normalized = out
        self.mapping = map
    }

    /// Map a normalized character index to the corresponding original index.
    /// `normalizedIndex` may be equal to `mapping.count` (end-of-string) and
    /// will return the count of original characters.
    func originalIndex(forNormalized normalizedIndex: Int) -> Int {
        if normalizedIndex <= 0 { return 0 }
        if normalizedIndex >= mapping.count {
            return (mapping.last ?? -1) + 1
        }
        return mapping[normalizedIndex]
    }
}
