import Testing
@testable import Voicy

@Suite("String.wordCount")
struct StringWordCountTests {

    @Test("Empty string has no words")
    func empty() {
        #expect("".wordCount == 0)
        #expect("   ".wordCount == 0)
    }

    @Test("Single word")
    func single() {
        #expect("hello".wordCount == 1)
    }

    @Test("Multiple words with collapsed whitespace")
    func multiple() {
        #expect("hello world".wordCount == 2)
        #expect("one   two    three".wordCount == 3)
    }

    @Test("Newlines and tabs separate words")
    func mixedSeparators() {
        #expect("line one\nline two".wordCount == 4)
        #expect("a\tb\tc".wordCount == 3)
    }

    @Test("Leading and trailing whitespace ignored")
    func surroundingWhitespace() {
        #expect("  hello world  ".wordCount == 2)
    }
}
