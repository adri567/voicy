import Testing
@testable import Voicy

@Suite("SnippetService — applyReplacements")
struct SnippetApplyTests {

    @Test("Single match in middle of sentence")
    func singleMatch() {
        let result = DefaultSnippetService.applyReplacements(
            text: "vielen dank und best regards an alle",
            snippets: [snippet(["best regards"], "Beste Grüße, Adrian")]
        )
        #expect(result == "vielen dank und Beste Grüße, Adrian an alle")
    }

    @Test("Two different triggers in one sentence")
    func twoDifferentTriggers() {
        let result = DefaultSnippetService.applyReplacements(
            text: "schick es an meine email, best regards",
            snippets: [
                snippet(["meine email"], "adrian@example.com"),
                snippet(["best regards"], "Beste Grüße, Adrian")
            ]
        )
        #expect(result == "schick es an adrian@example.com, Beste Grüße, Adrian")
    }

    @Test("Same trigger twice — both replaced")
    func sameTriggerTwice() {
        let result = DefaultSnippetService.applyReplacements(
            text: "sende eine email, ich antworte per email",
            snippets: [snippet(["email"], "E-Mail")]
        )
        #expect(result == "sende eine E-Mail, ich antworte per E-Mail")
    }

    @Test("Case-insensitive matching")
    func caseInsensitive() {
        let result = DefaultSnippetService.applyReplacements(
            text: "Best Regards everyone",
            snippets: [snippet(["best regards"], "Beste Grüße")]
        )
        #expect(result == "Beste Grüße everyone")
    }

    @Test("Word boundary prevents mid-word match")
    func wordBoundary() {
        let result = DefaultSnippetService.applyReplacements(
            text: "bestseller list",
            snippets: [snippet(["best"], "BEST")]
        )
        #expect(result == "bestseller list")
    }

    @Test("Longest trigger wins on overlap")
    func longestWins() {
        let result = DefaultSnippetService.applyReplacements(
            text: "meine email",
            snippets: [
                snippet(["email"], "E-Mail"),
                snippet(["meine email"], "adrian@example.com")
            ]
        )
        #expect(result == "adrian@example.com")
    }

    @Test("Shorter trigger still matches when alone")
    func shorterAloneStillMatches() {
        let result = DefaultSnippetService.applyReplacements(
            text: "email",
            snippets: [
                snippet(["email"], "E-Mail"),
                snippet(["meine email"], "adrian@example.com")
            ]
        )
        #expect(result == "E-Mail")
    }

    @Test("Trigger followed by punctuation matches, punctuation preserved")
    func trailingPunctuationPreserved() {
        let result = DefaultSnippetService.applyReplacements(
            text: "best regards.",
            snippets: [snippet(["best regards"], "Beste Grüße, Adrian")]
        )
        // The trigger matches (word-boundary on the right is satisfied by '.'),
        // and the period stays as the speaker's terminal punctuation.
        #expect(result == "Beste Grüße, Adrian.")
    }

    @Test("Dash-and-space variants normalize equivalently")
    func dashSpaceVariants() {
        let s = [snippet(["e mail"], "E-Mail-Adresse")]
        #expect(DefaultSnippetService.applyReplacements(text: "meine E-Mail", snippets: s) == "meine E-Mail-Adresse")
        #expect(DefaultSnippetService.applyReplacements(text: "meine E Mail", snippets: s) == "meine E-Mail-Adresse")
        // "email" (without space or dash) is intentionally NOT matched —
        // user must add it as an explicit alias.
        #expect(DefaultSnippetService.applyReplacements(text: "meine email", snippets: s) == "meine email")
    }

    @Test("Adding an alias bridges the zero-space case")
    func aliasBridgesZeroSpace() {
        let s = [snippet(["e mail", "email"], "E-Mail-Adresse")]
        #expect(DefaultSnippetService.applyReplacements(text: "meine email", snippets: s) == "meine E-Mail-Adresse")
    }

    @Test("Multiple aliases — any trigger matches same replacement")
    func aliasesMatch() {
        let s = snippet(["best regards", "kind regards", "regards"], "Beste Grüße")
        #expect(DefaultSnippetService.applyReplacements(text: "kind regards", snippets: [s]) == "Beste Grüße")
        #expect(DefaultSnippetService.applyReplacements(text: "regards everyone", snippets: [s]) == "Beste Grüße everyone")
    }

    @Test("Empty input returns empty")
    func emptyInput() {
        let result = DefaultSnippetService.applyReplacements(
            text: "",
            snippets: [snippet(["x"], "y")]
        )
        #expect(result.isEmpty)
    }

    @Test("No matches leaves text untouched")
    func noMatches() {
        let result = DefaultSnippetService.applyReplacements(
            text: "hallo welt",
            snippets: [snippet(["foo"], "bar")]
        )
        #expect(result == "hallo welt")
    }

    @Test("Leftmost-longest on true overlap")
    func leftmostLongest() {
        // "email best" and "best regards" overlap on the word "best".
        // Longer ("best regards" = 12 chars vs "email best" = 10 chars) wins;
        // leftmost only matters on length tie.
        let result = DefaultSnippetService.applyReplacements(
            text: "email best regards",
            snippets: [
                snippet(["email best"], "X"),
                snippet(["best regards"], "Y")
            ]
        )
        // Longest is "best regards" (12), so Y wins; "email " stays untouched.
        #expect(result == "email Y")
    }
}
