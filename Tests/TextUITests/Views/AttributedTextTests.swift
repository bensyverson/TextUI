import Testing
@testable import TextUI

@Suite("AttributedText")
struct AttributedTextTests {
    @Test("Multi-span sizing")
    func multiSpanSizing() {
        let view = AttributedText {
            AttributedText.TextSpan("Hello", style: .bold)
            AttributedText.TextSpan(" World", style: .plain)
        }
        let size = sizeThatFits(view, proposal: SizeProposal(width: 20, height: 5))
        #expect(size.width == 11) // "Hello World"
        #expect(size.height == 1)
    }

    @Test("Truncation respects proposal")
    func truncation() {
        let view = AttributedText {
            AttributedText.TextSpan("Hello", style: .bold)
            AttributedText.TextSpan(" World", style: .plain)
        }
        let size = sizeThatFits(view, proposal: SizeProposal(width: 7, height: 1))
        #expect(size.width == 7)
    }

    @Test("Render with mixed styles")
    func renderMixedStyles() {
        let view = AttributedText {
            AttributedText.TextSpan("AB", style: .bold)
            AttributedText.TextSpan("CD", style: Style(fg: .red))
        }
        var buffer = Buffer(width: 4, height: 1)
        let region = Region(row: 0, col: 0, width: 4, height: 1)
        render(view, into: &buffer, region: region)
        #expect(buffer[0, 0].char == "A")
        #expect(buffer[0, 0].style.bold)
        #expect(buffer[0, 1].char == "B")
        #expect(buffer[0, 1].style.bold)
        #expect(buffer[0, 2].char == "C")
        #expect(buffer[0, 2].style.fg == .red)
        #expect(buffer[0, 3].char == "D")
        #expect(buffer[0, 3].style.fg == .red)
    }

    @Test("Empty spans have zero size")
    func emptySpans() {
        let view = AttributedText([])
        let size = sizeThatFits(view, proposal: SizeProposal(width: 20, height: 5))
        #expect(size == .zero)
    }

    @Test("Single span equivalent to Text")
    func singleSpan() {
        let attrText = AttributedText {
            AttributedText.TextSpan("Hello", style: .plain)
        }
        let text = Text("Hello")
        let attrSize = sizeThatFits(attrText, proposal: SizeProposal(width: 20, height: 5))
        let textSize = sizeThatFits(text, proposal: SizeProposal(width: 20, height: 5))
        #expect(attrSize.width == textSize.width)
    }

    @Test("Ideal size reports total width")
    func idealSize() {
        let view = AttributedText {
            AttributedText.TextSpan("AB", style: .plain)
            AttributedText.TextSpan("CD", style: .bold)
        }
        let size = sizeThatFits(view, proposal: .unspecified)
        #expect(size.width == 4)
        #expect(size.height == 1)
    }

    @Test("Render truncates spans at region boundary")
    func renderTruncation() {
        let view = AttributedText {
            AttributedText.TextSpan("ABCDE", style: .plain)
        }
        var buffer = Buffer(width: 3, height: 1)
        let region = Region(row: 0, col: 0, width: 3, height: 1)
        render(view, into: &buffer, region: region)
        #expect(buffer[0, 0].char == "A")
        #expect(buffer[0, 1].char == "B")
        #expect(buffer[0, 2].char == "C")
    }
}
