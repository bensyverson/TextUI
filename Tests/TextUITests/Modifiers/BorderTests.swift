import Testing
@testable import TextUI

@MainActor
@Suite("Border Modifier")
struct BorderTests {
    @Test("Rounded border draws correct corners")
    func roundedCorners() {
        let view = Text("AB").border(.rounded)
        let size = sizeThatFits(view, proposal: SizeProposal(width: 20, height: 10))
        #expect(size == Size2D(width: 4, height: 3)) // 2+2, 1+2
        var buffer = Buffer(width: 4, height: 3)
        let region = Region(row: 0, col: 0, width: 4, height: 3)
        render(view, into: &buffer, region: region)
        #expect(buffer[0, 0].char == "╭")
        #expect(buffer[0, 3].char == "╮")
        #expect(buffer[2, 0].char == "╰")
        #expect(buffer[2, 3].char == "╯")
    }

    @Test("Square border draws correct corners")
    func squareCorners() {
        let view = Text("AB").border(.square)
        var buffer = Buffer(width: 4, height: 3)
        let region = Region(row: 0, col: 0, width: 4, height: 3)
        render(view, into: &buffer, region: region)
        #expect(buffer[0, 0].char == "┌")
        #expect(buffer[0, 3].char == "┐")
        #expect(buffer[2, 0].char == "└")
        #expect(buffer[2, 3].char == "┘")
    }

    @Test("Border draws horizontal and vertical edges")
    func edges() {
        let view = Text("ABCD").border(.rounded)
        let size = sizeThatFits(view, proposal: SizeProposal(width: 20, height: 10))
        var buffer = Buffer(width: size.width, height: size.height)
        let region = Region(row: 0, col: 0, width: size.width, height: size.height)
        render(view, into: &buffer, region: region)
        // Top edge
        #expect(buffer[0, 1].char == "─")
        #expect(buffer[0, 2].char == "─")
        // Bottom edge
        #expect(buffer[2, 1].char == "─")
        // Left edge
        #expect(buffer[1, 0].char == "│")
        // Right edge
        #expect(buffer[1, 5].char == "│")
    }

    @Test("Content renders inside border")
    func contentInside() {
        let view = Text("AB").border(.rounded)
        var buffer = Buffer(width: 4, height: 3)
        let region = Region(row: 0, col: 0, width: 4, height: 3)
        render(view, into: &buffer, region: region)
        #expect(buffer[1, 1].char == "A")
        #expect(buffer[1, 2].char == "B")
    }

    @Test("Sizing adds 2 to each axis")
    func sizingAddsTwo() {
        let text = Text("Hello")
        let bordered = text.border(.rounded)
        let size = sizeThatFits(bordered, proposal: SizeProposal(width: 20, height: 10))
        let textSize = sizeThatFits(text, proposal: SizeProposal(width: 20, height: 10))
        #expect(size.width == textSize.width + 2)
        #expect(size.height == textSize.height + 2)
    }

    @Test("Region too small renders nothing")
    func tooSmall() {
        let view = Text("Hi").border(.rounded)
        var buffer = Buffer(width: 1, height: 1)
        let region = Region(row: 0, col: 0, width: 1, height: 1)
        render(view, into: &buffer, region: region)
        // Should not crash; region too small for border
        #expect(buffer[0, 0].char == " ")
    }

    @Test("Default border style is rounded")
    func defaultRounded() {
        let view = Text("A").border()
        var buffer = Buffer(width: 3, height: 3)
        let region = Region(row: 0, col: 0, width: 3, height: 3)
        render(view, into: &buffer, region: region)
        #expect(buffer[0, 0].char == "╭")
    }

    @Test("Border with color applies fg style to corners")
    func coloredCorners() {
        let view = Text("AB").border(.rounded, color: .blue)
        var buffer = Buffer(width: 4, height: 3)
        let region = Region(row: 0, col: 0, width: 4, height: 3)
        render(view, into: &buffer, region: region)
        let blue: Style.Color = .blue
        #expect(buffer[0, 0].style.fg == blue)
        #expect(buffer[0, 3].style.fg == blue)
        #expect(buffer[2, 0].style.fg == blue)
        #expect(buffer[2, 3].style.fg == blue)
    }

    @Test("Border with color applies fg style to edges")
    func coloredEdges() {
        let view = Text("ABCD").border(.rounded, color: .red)
        let size = sizeThatFits(view, proposal: SizeProposal(width: 20, height: 10))
        var buffer = Buffer(width: size.width, height: size.height)
        let region = Region(row: 0, col: 0, width: size.width, height: size.height)
        render(view, into: &buffer, region: region)
        let red: Style.Color = .red
        // Top horizontal edge
        #expect(buffer[0, 1].style.fg == red)
        // Bottom horizontal edge
        #expect(buffer[2, 1].style.fg == red)
        // Left vertical edge
        #expect(buffer[1, 0].style.fg == red)
        // Right vertical edge
        #expect(buffer[1, 5].style.fg == red)
    }

    @Test("Border without color keeps plain style")
    func noColorPlainStyle() {
        let view = Text("AB").border(.rounded)
        var buffer = Buffer(width: 4, height: 3)
        let region = Region(row: 0, col: 0, width: 4, height: 3)
        render(view, into: &buffer, region: region)
        #expect(buffer[0, 0].style.fg == nil)
        #expect(buffer[0, 1].style.fg == nil)
        #expect(buffer[1, 0].style.fg == nil)
    }

    @Test("Border color does not leak into content")
    func colorDoesNotLeakIntoContent() {
        let view = Text("AB").border(.rounded, color: .green)
        var buffer = Buffer(width: 4, height: 3)
        let region = Region(row: 0, col: 0, width: 4, height: 3)
        render(view, into: &buffer, region: region)
        let green: Style.Color = .green
        // Content cells should not have the border color
        #expect(buffer[1, 1].style.fg != green)
        #expect(buffer[1, 2].style.fg != green)
    }

    @Test("Border with padding inside")
    func borderWithPadding() {
        let view = Text("A").padding(1).border(.rounded)
        let size = sizeThatFits(view, proposal: SizeProposal(width: 20, height: 10))
        // "A" = 1x1, +2 padding = 3x3, +2 border = 5x5
        #expect(size == Size2D(width: 5, height: 5))
        var buffer = Buffer(width: 5, height: 5)
        let region = Region(row: 0, col: 0, width: 5, height: 5)
        render(view, into: &buffer, region: region)
        // Content at (2, 2): border adds 1, padding adds 1
        #expect(buffer[2, 2].char == "A")
    }
}
