import Testing
@testable import Voicy

@Suite("MLXTextCorrectionService — prompts")
struct MLXPromptTests {

    private var german: AppLanguage { LanguageCatalog.language(for: "de") }

    // MARK: - stripReasoning

    @Test("stripReasoning keeps only the text after </think>")
    func stripReasoningRemovesBlock() {
        #expect(MLXTextCorrectionService.stripReasoning("<think>analysis</think>Result") == "Result")
    }

    @Test("stripReasoning leaves text without a think tag unchanged")
    func stripReasoningNoTag() {
        #expect(MLXTextCorrectionService.stripReasoning("Plain answer") == "Plain answer")
    }

    // MARK: - wrappedInput

    @Test("translate input is wrapped in TRANSLATE tags")
    func wrapTranslate() {
        let wrapped = MLXTextCorrectionService.wrappedInput(
            for: Mode(type: .translate, targetCode: "en"),
            transcript: "hallo"
        )
        #expect(wrapped.contains("<TRANSLATE>"))
        #expect(wrapped.contains("hallo"))
    }

    @Test("developer input is wrapped in INPUT tags")
    func wrapDeveloper() {
        let wrapped = MLXTextCorrectionService.wrappedInput(for: Mode(type: .developer), transcript: "fix bug")
        #expect(wrapped.contains("<INPUT>"))
    }

    @Test("custom with spliced {{transcript}} returns the nudge message")
    func wrapCustomSpliced() {
        let mode = Mode(type: .custom, prompt: "Rewrite this: {{transcript}}")
        let wrapped = MLXTextCorrectionService.wrappedInput(for: mode, transcript: "hi")
        #expect(wrapped == "Follow the instructions above on the spliced transcript.")
    }

    @Test("custom without placeholder wraps the transcript in INPUT tags")
    func wrapCustomPlain() {
        let mode = Mode(type: .custom, prompt: "Make it formal")
        let wrapped = MLXTextCorrectionService.wrappedInput(for: mode, transcript: "hi")
        #expect(wrapped.contains("<INPUT>"))
    }

    // MARK: - systemPrompt

    @Test("translate prompt locks the target language")
    func systemPromptTranslate() {
        let prompt = MLXTextCorrectionService.systemPrompt(
            for: Mode(type: .translate, targetCode: "en"),
            source: german
        )
        #expect(prompt.contains("OUTPUT LANGUAGE"))
        #expect(prompt.contains("English"))
    }

    @Test("developer prompt targets technical English")
    func systemPromptDeveloper() {
        let prompt = MLXTextCorrectionService.systemPrompt(for: Mode(type: .developer), source: german)
        #expect(prompt.contains("technical English"))
    }

    @Test("email prompt enforces greeting and sign-off structure")
    func systemPromptEmail() {
        let prompt = MLXTextCorrectionService.systemPrompt(for: Mode(type: .email), source: german)
        #expect(prompt.lowercased().contains("greeting"))
        #expect(prompt.lowercased().contains("sign-off"))
    }

    @Test("raw prompt is empty — no LLM call expected")
    func systemPromptRaw() {
        #expect(MLXTextCorrectionService.systemPrompt(for: Mode(type: .raw), source: german).isEmpty)
    }
}
