import Testing
@testable import Voicy

@Suite("SnippetService — normalize")
struct SnippetNormalizeTests {

    @Test("Lowercases")
    func lowercases() {
        #expect(DefaultSnippetService.normalize("Best Regards") == "best regards")
    }

    @Test("Dashes become spaces")
    func dashesBecomeSpaces() {
        #expect(DefaultSnippetService.normalize("E-Mail") == "e mail")
        #expect(DefaultSnippetService.normalize("E—Mail") == "e mail")
    }

    @Test("Multiple spaces collapsed")
    func multiSpaces() {
        #expect(DefaultSnippetService.normalize("hi    there") == "hi there")
    }

    @Test("Trailing whitespace stripped, leading kept (caller's job)")
    func trailingStripped() {
        #expect(DefaultSnippetService.normalize("hello   ") == "hello")
    }

    @Test("Leading dash does not produce leading space")
    func leadingDashNoLeadingSpace() {
        #expect(DefaultSnippetService.normalize("-Mail") == "mail")
        #expect(DefaultSnippetService.normalize("—Mail") == "mail")
    }
}
