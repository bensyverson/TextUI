import Testing
@testable import TextUI

@Suite("Text Wrapping")
struct TextWrappingTests {
    // MARK: - Word Wrapping

    @Test("Wraps at word boundaries")
    func wordBoundaryWrap() {
        let lines = Text.wordWrap("Hello World", maxWidth: 5)
        #expect(lines == ["Hello", "World"])
    }

    @Test("Wraps multiple words across lines")
    func multiWordWrap() {
        let lines = Text.wordWrap("one two three four", maxWidth: 9)
        #expect(lines == ["one two", "three", "four"])
    }

    @Test("No wrap when line fits")
    func noWrapWhenFits() {
        let lines = Text.wordWrap("Hi", maxWidth: 10)
        #expect(lines == ["Hi"])
    }

    @Test("Character-wraps words longer than maxWidth")
    func characterWrapLongWord() {
        let lines = Text.wordWrap("ABCDEFGHIJ", maxWidth: 4)
        #expect(lines == ["ABCD", "EFGH", "IJ"])
    }

    @Test("CJK character wrapping respects double-width")
    func cjkCharacterWrap() {
        // 你好世界 = 4 chars, 8 display width
        let lines = Text.wordWrap("你好世界", maxWidth: 4)
        #expect(lines == ["你好", "世界"])
    }

    @Test("Empty string wraps to single empty line")
    func emptyStringWrap() {
        let lines = Text.wordWrap("", maxWidth: 10)
        #expect(lines == [""])
    }

    @Test("Zero maxWidth returns single empty line")
    func zeroMaxWidth() {
        let lines = Text.wordWrap("Hello", maxWidth: 0)
        #expect(lines == [""])
    }

    // MARK: - sizeThatFits with Wrapping

    @Test("sizeThatFits wraps when proposed width is narrower")
    func sizeThatFitsWraps() {
        let text = Text("Hello World")
        let size = text.sizeThatFits(SizeProposal(width: 5, height: 10))
        #expect(size == Size2D(width: 5, height: 2))
    }

    @Test("sizeThatFits with nil width does not wrap")
    func sizeThatFitsNoWrapNilWidth() {
        let text = Text("Hello World")
        let size = text.sizeThatFits(.unspecified)
        #expect(size == Size2D(width: 11, height: 1))
    }

    @Test("sizeThatFits wraps multi-line text with explicit newlines")
    func sizeThatFitsMultiLineWrap() {
        let text = Text("AB CD\nEF GH IJ")
        let size = text.sizeThatFits(SizeProposal(width: 5, height: 10))
        // "AB CD" fits in 5, "EF GH" wraps to "EF GH" (5) but "IJ" on next line
        #expect(size == Size2D(width: 5, height: 3))
    }

    // MARK: - Line Limit

    @Test("lineLimit caps number of lines in sizeThatFits")
    func lineLimitSizeThatFits() {
        let text = Text("one two three four five six")
        var ctx = RenderContext()
        ctx.lineLimit = 2
        let size = text.sizeThatFits(SizeProposal(width: 5, height: 10), context: ctx)
        // Without limit: wraps to many lines. With limit 2: height = 2
        #expect(size.height == 2)
        #expect(size.width == 5)
    }

    @Test("lineLimit(1) with long text renders single truncated line")
    func lineLimit1Render() {
        var buffer = Buffer(width: 10, height: 1)
        let region = Region(row: 0, col: 0, width: 10, height: 1)
        var ctx = RenderContext()
        ctx.lineLimit = 1
        // "Hello World and more" wraps to ["Hello", "World and", "more"] at width 10.
        // lineLimit=1 reconstructs: "Hello World and more", tail-truncates to 10.
        Text("Hello World and more").render(into: &buffer, region: region, context: ctx)
        #expect(buffer.text == "Hello Wor\u{2026}")
    }

    // MARK: - Truncation Mode

    @Test("truncationMode(.tail) — ellipsis at end (default)")
    func truncationTail() {
        let result = Text.truncate("Hello World", toWidth: 8, mode: .tail)
        #expect(result == "Hello W\u{2026}")
    }

    @Test("truncationMode(.head) — ellipsis at start")
    func truncationHead() {
        let result = Text.truncate("Hello World", toWidth: 8, mode: .head)
        #expect(result == "\u{2026}o World")
    }

    @Test("truncationMode(.middle) — ellipsis in middle")
    func truncationMiddle() {
        let result = Text.truncate("Hello World", toWidth: 8, mode: .middle)
        // availableWidth=7, leading=4, trailing=3
        #expect(result == "Hell\u{2026}rld")
    }

    @Test("No truncation when line fits")
    func noTruncation() {
        let result = Text.truncate("Hi", toWidth: 10, mode: .tail)
        #expect(result == "Hi")
    }

    @Test("Truncation to width 1 returns just ellipsis")
    func truncateToOne() {
        let result = Text.truncate("Hello", toWidth: 1, mode: .tail)
        #expect(result == "\u{2026}")
    }

    @Test("Head truncation renders correctly with lineLimit")
    func headTruncationRender() {
        var buffer = Buffer(width: 10, height: 1)
        let region = Region(row: 0, col: 0, width: 10, height: 1)
        var ctx = RenderContext()
        ctx.lineLimit = 1
        ctx.truncationMode = .head
        // "Hello World and more" reconstructs to full text, head-truncates to 10.
        // Head truncation keeps last 9 chars: " and more" → "… and more"
        Text("Hello World and more").render(into: &buffer, region: region, context: ctx)
        #expect(buffer.text == "\u{2026} and more")
    }

    // MARK: - Multiline Text Alignment

    @Test("multilineTextAlignment(.center) centers shorter wrapped lines")
    func centerAlignment() {
        var buffer = Buffer(width: 11, height: 2)
        let region = Region(row: 0, col: 0, width: 11, height: 2)
        var ctx = RenderContext()
        ctx.multilineTextAlignment = .center
        // "Hello World" is 11 wide, fits on one line at width 11
        // But "Hi\nWorld" has lines of different widths
        Text("Hi\nWorld").render(into: &buffer, region: region, context: ctx)
        // "Hi" (2 wide) centered in 11 → offset 4
        // "World" (5 wide) centered in 11 → offset 3
        #expect(buffer[0, 4].char == "H")
        #expect(buffer[0, 5].char == "i")
        #expect(buffer[1, 3].char == "W")
    }

    @Test("multilineTextAlignment(.trailing) right-aligns wrapped lines")
    func trailingAlignment() {
        var buffer = Buffer(width: 10, height: 2)
        let region = Region(row: 0, col: 0, width: 10, height: 2)
        var ctx = RenderContext()
        ctx.multilineTextAlignment = .trailing
        Text("Hi\nWorld").render(into: &buffer, region: region, context: ctx)
        // "Hi" (2 wide) trailing in 10 → offset 8
        // "World" (5 wide) trailing in 10 → offset 5
        #expect(buffer[0, 8].char == "H")
        #expect(buffer[0, 9].char == "i")
        #expect(buffer[1, 5].char == "W")
    }

    @Test("Default alignment is leading")
    func leadingAlignmentDefault() {
        var buffer = Buffer(width: 10, height: 2)
        let region = Region(row: 0, col: 0, width: 10, height: 2)
        Text("Hi\nWorld").render(into: &buffer, region: region)
        #expect(buffer[0, 0].char == "H")
        #expect(buffer[1, 0].char == "W")
    }

    // MARK: - Wrapping + Rendering

    @Test("Wrapped text renders correctly")
    func wrappedTextRender() {
        var buffer = Buffer(width: 5, height: 3)
        let region = Region(row: 0, col: 0, width: 5, height: 3)
        Text("Hello World").render(into: &buffer, region: region)
        #expect(buffer.text == "Hello\nWorld")
    }

    @Test("Wrapped text with explicit newlines renders correctly")
    func wrappedWithNewlines() {
        var buffer = Buffer(width: 6, height: 4)
        let region = Region(row: 0, col: 0, width: 6, height: 4)
        Text("AB CD\nEF GH").render(into: &buffer, region: region)
        #expect(buffer.text == "AB CD\nEF GH")
    }
}
