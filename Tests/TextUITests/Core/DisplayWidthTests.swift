import Testing
@testable import TextUI

@Suite("DisplayWidth")
struct DisplayWidthTests {
    // MARK: - Character.displayWidth

    @Test("ASCII characters are width 1")
    func asciiWidth() {
        #expect(Character("A").displayWidth == 1)
        #expect(Character("z").displayWidth == 1)
        #expect(Character("!").displayWidth == 1)
        #expect(Character(" ").displayWidth == 1)
    }

    @Test("Digits are width 1, not 2")
    func digitsAreNotWide() {
        #expect(Character("0").displayWidth == 1)
        #expect(Character("1").displayWidth == 1)
        #expect(Character("9").displayWidth == 1)
    }

    @Test("Emoji with presentation are width 2")
    func emojiPresentation() {
        #expect(Character("😀").displayWidth == 2)
        #expect(Character("👋").displayWidth == 2)
        #expect(Character("🎉").displayWidth == 2)
        #expect(Character("🔥").displayWidth == 2)
    }

    @Test("CJK characters are width 2")
    func cjkWidth() {
        #expect(Character("你").displayWidth == 2)
        #expect(Character("好").displayWidth == 2)
        #expect(Character("漢").displayWidth == 2)
        #expect(Character("字").displayWidth == 2)
    }

    @Test("Hangul syllables are width 2")
    func hangulWidth() {
        #expect(Character("한").displayWidth == 2)
        #expect(Character("글").displayWidth == 2)
    }

    @Test("Fullwidth forms are width 2")
    func fullwidthWidth() {
        #expect(Character("Ａ").displayWidth == 2)
        #expect(Character("１").displayWidth == 2)
    }

    @Test("Simple ZWJ sequences are width 2")
    func simpleZWJ() {
        #expect(Character("👨‍💻").displayWidth == 2)
        #expect(Character("👩‍🔬").displayWidth == 2)
    }

    @Test("Complex ZWJ sequences are width 2")
    func complexZWJ() {
        #expect(Character("👩‍👩‍👧‍👦").displayWidth == 2)
        #expect(Character("👩🏼‍❤️‍💋‍👨🏾").displayWidth == 2)
        #expect(Character("👨🏻‍🦰").displayWidth == 2)
    }

    @Test("Flag emoji are width 2")
    func flagWidth() {
        #expect(Character("🇺🇸").displayWidth == 2)
        #expect(Character("🇯🇵").displayWidth == 2)
    }

    @Test("Skin tone modifiers produce width 2")
    func skinToneWidth() {
        #expect(Character("👋🏽").displayWidth == 2)
        #expect(Character("👍🏿").displayWidth == 2)
    }

    @Test("Keycap sequences are width 2")
    func keycapWidth() {
        #expect(Character("1️⃣").displayWidth == 2)
        #expect(Character("2️⃣").displayWidth == 2)
    }

    @Test("VS-16 promotes text emoji to width 2")
    func vs16Width() {
        // ☺ without VS-16 is width 1, with VS-16 (☺️) is width 2
        #expect(Character("☺️").displayWidth == 2)
    }

    @Test("Combining marks produce width 0")
    func combiningMarksZeroWidth() {
        // Standalone combining acute accent
        let combining = Character("\u{0301}")
        #expect(combining.displayWidth == 0)
    }

    @Test("Characters with combining marks are width 1")
    func accentedCharacterWidth() {
        // café — the é is a single grapheme cluster (e + combining acute)
        #expect(Character("é").displayWidth == 1)
    }

    @Test("Hiragana and Katakana are width 2")
    func japaneseKanaWidth() {
        #expect(Character("あ").displayWidth == 2)
        #expect(Character("ア").displayWidth == 2)
    }

    // MARK: - String.displayWidth

    @Test("ASCII string width equals count")
    func asciiStringWidth() {
        #expect("Hello".displayWidth == 5)
        #expect("abc".displayWidth == 3)
    }

    @Test("CJK string width is double the count")
    func cjkStringWidth() {
        #expect("你好".displayWidth == 4)
    }

    @Test("Mixed ASCII and CJK string")
    func mixedStringWidth() {
        #expect("Hi你好".displayWidth == 6)
    }

    @Test("Mixed ASCII and emoji string")
    func mixedEmojiStringWidth() {
        #expect("Hi👋".displayWidth == 4)
    }

    @Test("Empty string width is 0")
    func emptyStringWidth() {
        #expect("".displayWidth == 0)
    }

    @Test("String with combining marks")
    func combiningStringWidth() {
        // "café" — 4 grapheme clusters, all width 1
        #expect("café".displayWidth == 4)
    }

    @Test("String with multiple emoji")
    func multipleEmojiWidth() {
        #expect("🇺🇸🇯🇵".displayWidth == 4)
    }
}
