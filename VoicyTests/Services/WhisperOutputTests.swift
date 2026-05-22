import Testing
@testable import Voicy

@Suite("DefaultTranscriptionService — cleanWhisperOutput")
struct WhisperOutputTests {

    @Test("Strips a single control token")
    func stripsSingleToken() {
        #expect(DefaultTranscriptionService.cleanWhisperOutput("<|startoftranscript|>Hello") == "Hello")
    }

    @Test("Strips multiple control tokens including timestamps and language")
    func stripsMultipleTokens() {
        let raw = "<|startoftranscript|><|de|><|transcribe|><|0.00|>Guten Tag<|5.20|>"
        #expect(DefaultTranscriptionService.cleanWhisperOutput(raw) == "Guten Tag")
    }

    @Test("Collapses runs of spaces and tabs")
    func collapsesWhitespace() {
        #expect(DefaultTranscriptionService.cleanWhisperOutput("Hello   \t  world") == "Hello world")
    }

    @Test("Trims leading and trailing whitespace")
    func trims() {
        #expect(DefaultTranscriptionService.cleanWhisperOutput("   Hello world   ") == "Hello world")
    }

    @Test("Plain text without tokens is unchanged")
    func plainUnchanged() {
        #expect(DefaultTranscriptionService.cleanWhisperOutput("Hello world") == "Hello world")
    }
}
