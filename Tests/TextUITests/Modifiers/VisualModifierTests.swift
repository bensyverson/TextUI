import Testing
@testable import TextUI

@MainActor
@Suite("Visual Modifiers")
struct VisualModifierTests {
    // MARK: - StyledView

    @Test("bold() adds bold to rendered cells")
    func boldAddsAttribute() {
        let view = Text("AB").bold()
        var buffer = Buffer(width: 2, height: 1)
        let region = Region(row: 0, col: 0, width: 2, height: 1)
        render(view, into: &buffer, region: region)
        #expect(buffer[0, 0].style.bold)
        #expect(buffer[0, 1].style.bold)
    }

    @Test("foregroundColor sets fg on cells")
    func foregroundSetsColor() {
        let view = Text("AB").foregroundColor(.red)
        var buffer = Buffer(width: 2, height: 1)
        let region = Region(row: 0, col: 0, width: 2, height: 1)
        render(view, into: &buffer, region: region)
        #expect(buffer[0, 0].style.fg == .red)
        #expect(buffer[0, 1].style.fg == .red)
    }

    @Test("Chaining bold and foregroundColor applies both")
    func chainingStyles() {
        let view = Text("A").bold().foregroundColor(.red)
        var buffer = Buffer(width: 1, height: 1)
        let region = Region(row: 0, col: 0, width: 1, height: 1)
        render(view, into: &buffer, region: region)
        #expect(buffer[0, 0].style.bold)
        #expect(buffer[0, 0].style.fg == .red)
    }

    @Test("Styled view preserves child's existing style")
    func preservesChildStyle() {
        let view = Text("A", style: Style(fg: .blue)).bold()
        var buffer = Buffer(width: 1, height: 1)
        let region = Region(row: 0, col: 0, width: 1, height: 1)
        render(view, into: &buffer, region: region)
        // bold merges in, fg stays blue (override has nil fg)
        #expect(buffer[0, 0].style.bold)
        #expect(buffer[0, 0].style.fg == .blue)
    }

    @Test("foregroundColor overrides child fg")
    func fgOverridesChildFg() {
        let view = Text("A", style: Style(fg: .blue)).foregroundColor(.red)
        var buffer = Buffer(width: 1, height: 1)
        let region = Region(row: 0, col: 0, width: 1, height: 1)
        render(view, into: &buffer, region: region)
        #expect(buffer[0, 0].style.fg == .red)
    }

    @Test("Styled view does not affect sizing")
    func sizeUnchanged() {
        let text = Text("Hello")
        let styled = text.bold().foregroundColor(.red)
        let textSize = sizeThatFits(text, proposal: SizeProposal(width: 20, height: 5))
        let styledSize = sizeThatFits(styled, proposal: SizeProposal(width: 20, height: 5))
        #expect(textSize == styledSize)
    }

    @Test("style() applies full style override")
    func fullStyleOverride() {
        let view = Text("A").style(Style(fg: .green, bold: true, italic: true))
        var buffer = Buffer(width: 1, height: 1)
        let region = Region(row: 0, col: 0, width: 1, height: 1)
        render(view, into: &buffer, region: region)
        #expect(buffer[0, 0].style.fg == .green)
        #expect(buffer[0, 0].style.bold)
        #expect(buffer[0, 0].style.italic)
    }

    // MARK: - BackgroundView

    @Test("Background fills empty cells")
    func backgroundFillsEmpty() {
        let view = Text("A").padding(1).background(.blue)
        let size = sizeThatFits(view, proposal: SizeProposal(width: 10, height: 5))
        var buffer = Buffer(width: size.width, height: size.height)
        let region = Region(row: 0, col: 0, width: size.width, height: size.height)
        render(view, into: &buffer, region: region)
        // Padding cells should have blue bg
        #expect(buffer[0, 0].style.bg == .blue)
        // Content cell also gets blue bg (bg was nil)
        #expect(buffer[1, 1].style.bg == .blue)
        #expect(buffer[1, 1].char == "A")
    }

    @Test("Background preserves explicit child bg")
    func backgroundPreservesChildBg() {
        let view = Text("A", style: Style(bg: .green)).background(.blue)
        var buffer = Buffer(width: 1, height: 1)
        let region = Region(row: 0, col: 0, width: 1, height: 1)
        render(view, into: &buffer, region: region)
        #expect(buffer[0, 0].style.bg == .green) // child's bg preserved
    }

    @Test("Background does not affect sizing")
    func backgroundSizeUnchanged() {
        let text = Text("Hello")
        let withBg = text.background(.blue)
        let textSize = sizeThatFits(text, proposal: SizeProposal(width: 20, height: 5))
        let bgSize = sizeThatFits(withBg, proposal: SizeProposal(width: 20, height: 5))
        #expect(textSize == bgSize)
    }

    // MARK: - OverlayView

    @Test("Overlay renders on top of base")
    func overlayRendersOnTop() {
        let view = Text("ABC").overlay {
            Text("X")
        }
        var buffer = Buffer(width: 3, height: 1)
        let region = Region(row: 0, col: 0, width: 3, height: 1)
        render(view, into: &buffer, region: region)
        // Overlay "X" overwrites first char of "ABC"
        #expect(buffer[0, 0].char == "X")
        #expect(buffer[0, 1].char == "B")
        #expect(buffer[0, 2].char == "C")
    }

    @Test("Overlay sizing driven by base")
    func overlaySizing() {
        let view = Text("Hi").overlay {
            Text("LongerText")
        }
        let size = sizeThatFits(view, proposal: SizeProposal(width: 20, height: 5))
        #expect(size.width == 2) // base "Hi" drives size
        #expect(size.height == 1)
    }

    // MARK: - Other attribute modifiers

    @Test("dim() adds dim attribute")
    func dimAddsAttribute() {
        let view = Text("A").dim()
        var buffer = Buffer(width: 1, height: 1)
        render(view, into: &buffer, region: Region(row: 0, col: 0, width: 1, height: 1))
        #expect(buffer[0, 0].style.dim)
    }

    @Test("italic() adds italic attribute")
    func italicAddsAttribute() {
        let view = Text("A").italic()
        var buffer = Buffer(width: 1, height: 1)
        render(view, into: &buffer, region: Region(row: 0, col: 0, width: 1, height: 1))
        #expect(buffer[0, 0].style.italic)
    }

    @Test("underline() adds underline attribute")
    func underlineAddsAttribute() {
        let view = Text("A").underline()
        var buffer = Buffer(width: 1, height: 1)
        render(view, into: &buffer, region: Region(row: 0, col: 0, width: 1, height: 1))
        #expect(buffer[0, 0].style.underline)
    }

    @Test("strikethrough() adds strikethrough attribute")
    func strikethroughAddsAttribute() {
        let view = Text("A").strikethrough()
        var buffer = Buffer(width: 1, height: 1)
        render(view, into: &buffer, region: Region(row: 0, col: 0, width: 1, height: 1))
        #expect(buffer[0, 0].style.strikethrough)
    }

    @Test("inverse() adds inverse attribute")
    func inverseAddsAttribute() {
        let view = Text("A").inverse()
        var buffer = Buffer(width: 1, height: 1)
        render(view, into: &buffer, region: Region(row: 0, col: 0, width: 1, height: 1))
        #expect(buffer[0, 0].style.inverse)
    }
}
