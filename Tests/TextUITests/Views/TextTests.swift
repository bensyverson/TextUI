import Testing
@testable import TextUI

@Suite("Text")
struct TextTests {
    // MARK: - Ideal Sizing (nil proposal)

    @Test("Ideal size of single-line text")
    func idealSingleLine() {
        let size = Text("Hello").sizeThatFits(.unspecified)
        #expect(size == Size2D(width: 5, height: 1))
    }

    @Test("Ideal size of multi-line text")
    func idealMultiLine() {
        let size = Text("AB\nCDEF\nG").sizeThatFits(.unspecified)
        #expect(size == Size2D(width: 4, height: 3))
    }

    @Test("Ideal size of empty string")
    func idealEmpty() {
        let size = Text("").sizeThatFits(.unspecified)
        #expect(size == Size2D(width: 0, height: 1))
    }

    // MARK: - Minimum Sizing (0 proposal)

    @Test("Minimum size is zero")
    func minimumSize() {
        let size = Text("Hello").sizeThatFits(.zero)
        #expect(size == .zero)
    }

    // MARK: - Maximum Sizing (.max proposal)

    @Test("Maximum size hugs to content")
    func maximumSize() {
        let size = Text("Hello").sizeThatFits(.max)
        #expect(size == Size2D(width: 5, height: 1))
    }

    // MARK: - Concrete Sizing

    @Test("Text wider than content hugs to content width")
    func widerThanContent() {
        let size = Text("Hi").sizeThatFits(SizeProposal(width: 80, height: 10))
        #expect(size == Size2D(width: 2, height: 1))
    }

    @Test("Text narrower than content wraps to proposed width")
    func narrowerThanContent() {
        let size = Text("Hello World").sizeThatFits(SizeProposal(width: 5, height: 10))
        #expect(size == Size2D(width: 5, height: 2))
    }

    // MARK: - CJK Width

    @Test("CJK characters count as double width")
    func cjkWidth() {
        let size = Text("你好").sizeThatFits(.unspecified)
        #expect(size == Size2D(width: 4, height: 1))
    }

    // MARK: - Rendering

    @Test("Renders single line into buffer")
    func renderSingleLine() {
        var buffer = Buffer(width: 10, height: 1)
        let region = Region(row: 0, col: 0, width: 10, height: 1)
        Text("Hello").render(into: &buffer, region: region)
        #expect(buffer.text == "Hello")
    }

    @Test("Renders multi-line text")
    func renderMultiLine() {
        var buffer = Buffer(width: 10, height: 3)
        let region = Region(row: 0, col: 0, width: 10, height: 3)
        Text("AB\nCD\nEF").render(into: &buffer, region: region)
        #expect(buffer.text == "AB\nCD\nEF")
    }

    @Test("Truncation: text wider than region is clipped")
    func renderTruncation() {
        var buffer = Buffer(width: 3, height: 1)
        let region = Region(row: 0, col: 0, width: 3, height: 1)
        Text("Hello").render(into: &buffer, region: region)
        #expect(buffer.text == "Hel")
    }

    @Test("Renders with style")
    func renderWithStyle() {
        var buffer = Buffer(width: 5, height: 1)
        let region = Region(row: 0, col: 0, width: 5, height: 1)
        Text("Hi", style: .bold).render(into: &buffer, region: region)
        #expect(buffer[0, 0].style == .bold)
        #expect(buffer[0, 1].style == .bold)
    }

    @Test("Renders at region offset")
    func renderAtOffset() {
        var buffer = Buffer(width: 10, height: 3)
        let region = Region(row: 1, col: 3, width: 5, height: 1)
        Text("AB").render(into: &buffer, region: region)
        #expect(buffer[1, 3].char == "A")
        #expect(buffer[1, 4].char == "B")
    }

    @Test("Height-limited region clips lines")
    func renderHeightClip() {
        var buffer = Buffer(width: 10, height: 2)
        let region = Region(row: 0, col: 0, width: 10, height: 1)
        Text("A\nB\nC").render(into: &buffer, region: region)
        #expect(buffer.text == "A")
    }
}
