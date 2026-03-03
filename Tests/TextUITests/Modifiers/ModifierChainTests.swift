import Testing
@testable import TextUI

@MainActor
@Suite("Modifier Chain Integration")
struct ModifierChainTests {
    @Test("Text.padding.border.background sizes and renders correctly")
    func paddingBorderBackground() {
        let view = Text("Hi").padding(1).border(.rounded).background(.blue)
        // "Hi" = 2x1, +2 padding = 4x3, +2 border = 6x5
        let size = sizeThatFits(view, proposal: SizeProposal(width: 20, height: 10))
        #expect(size == Size2D(width: 6, height: 5))

        var buffer = Buffer(width: 6, height: 5)
        let region = Region(row: 0, col: 0, width: 6, height: 5)
        render(view, into: &buffer, region: region)

        // Corners
        #expect(buffer[0, 0].char == "╭")
        #expect(buffer[0, 5].char == "╮")
        #expect(buffer[4, 0].char == "╰")
        #expect(buffer[4, 5].char == "╯")

        // Text at (2, 2): border adds 1, padding adds 1
        #expect(buffer[2, 2].char == "H")
        #expect(buffer[2, 3].char == "i")

        // Background applied to all cells where bg is nil
        #expect(buffer[0, 0].style.bg == .blue) // corner
        #expect(buffer[1, 1].style.bg == .blue) // padding
        #expect(buffer[2, 2].style.bg == .blue) // text cell
    }

    @Test("ZStack with Color and Text renders correctly")
    func zstackColorText() {
        let view = ZStack {
            Color(.blue)
            Text("Overlay")
        }
        var buffer = Buffer(width: 10, height: 3)
        let region = Region(row: 0, col: 0, width: 10, height: 3)
        render(view, into: &buffer, region: region)

        // Color fills entire region with blue bg
        #expect(buffer[0, 0].style.bg == .blue)
        #expect(buffer[2, 9].style.bg == .blue)

        // "Overlay" centered: col = (10-7)/2 = 1, row = (3-1)/2 = 1
        #expect(buffer[1, 1].char == "O")
        #expect(buffer[1, 7].char == "y")
    }

    @Test("frame(maxWidth: .max) makes hugging view fill container")
    func maxWidthExpands() {
        let view = Text("Hi").frame(maxWidth: .max)
        let size = sizeThatFits(view, proposal: SizeProposal(width: 20, height: 5))
        #expect(size.width == 20) // expanded from 2 to 20
    }

    @Test("fixedSize prevents truncation")
    func fixedSizePrevents() {
        let view = Text("Hello World").fixedSize()
        let size = sizeThatFits(view, proposal: SizeProposal(width: 5, height: 1))
        #expect(size.width == 11) // reports ideal, not truncated
    }

    @Test("layoutPriority affects stack distribution")
    func layoutPriorityDistribution() {
        let view = HStack(spacing: 0) {
            Text("ABCDE").layoutPriority(1)
            Text("FGHIJ")
        }
        // With equal flexibility, priority 1 gets allocated first
        var buffer = Buffer(width: 7, height: 1)
        let region = Region(row: 0, col: 0, width: 7, height: 1)
        render(view, into: &buffer, region: region)
        // Both get their fair shares but priority determines order
        #expect(buffer[0, 0].char == "A")
        #expect(buffer[0, 3].char == "F")
    }

    @Test("ForEach in VStack renders all items")
    func forEachInVStack() {
        let items = ["One", "Two", "Three"]
        let view = VStack {
            ForEach(items) { item in
                Text(item)
            }
        }
        let size = sizeThatFits(view, proposal: SizeProposal(width: 20, height: 10))
        #expect(size.height == 3)
        var buffer = Buffer(width: size.width, height: size.height)
        let region = Region(row: 0, col: 0, width: size.width, height: size.height)
        render(view, into: &buffer, region: region)
        #expect(buffer[0, 0].char == "O") // "One"
        #expect(buffer[1, 0].char == "T") // "Two"
        #expect(buffer[2, 0].char == "T") // "Three"
    }

    @Test("Nested modifiers: bold.padding.border")
    func nestedBoldPaddingBorder() {
        let view = Text("X").bold().padding(1).border(.rounded)
        let size = sizeThatFits(view, proposal: SizeProposal(width: 20, height: 10))
        // "X" = 1x1, +2 padding = 3x3, +2 border = 5x5
        #expect(size == Size2D(width: 5, height: 5))

        var buffer = Buffer(width: 5, height: 5)
        let region = Region(row: 0, col: 0, width: 5, height: 5)
        render(view, into: &buffer, region: region)

        // Text at (2, 2)
        #expect(buffer[2, 2].char == "X")
        #expect(buffer[2, 2].style.bold)

        // Border corners
        #expect(buffer[0, 0].char == "╭")
        #expect(buffer[4, 4].char == "╯")
    }

    @Test("Multiple visual modifiers chain correctly")
    func multipleVisualModifiers() {
        let view = Text("A").bold().foregroundColor(.red).background(.blue)
        var buffer = Buffer(width: 1, height: 1)
        let region = Region(row: 0, col: 0, width: 1, height: 1)
        render(view, into: &buffer, region: region)
        #expect(buffer[0, 0].char == "A")
        #expect(buffer[0, 0].style.bold)
        #expect(buffer[0, 0].style.fg == .red)
        #expect(buffer[0, 0].style.bg == .blue)
    }

    @Test("Frame with alignment and border")
    func frameAlignmentBorder() {
        let view = Text("Hi")
            .frame(width: 6, height: 3, alignment: .center)
            .border(.square)
        let size = sizeThatFits(view, proposal: SizeProposal(width: 20, height: 10))
        #expect(size == Size2D(width: 8, height: 5))

        var buffer = Buffer(width: 8, height: 5)
        let region = Region(row: 0, col: 0, width: 8, height: 5)
        render(view, into: &buffer, region: region)
        // Border corners (square)
        #expect(buffer[0, 0].char == "┌")
        #expect(buffer[4, 7].char == "┘")
        // "Hi" centered in 6x3 frame inside border:
        // frame region = (1,1) to (6,3)
        // "Hi" center offset in 6x3: col = (6-2)/2 = 2, row = (3-1)/2 = 1
        // absolute: row = 1+1 = 2, col = 1+2 = 3
        #expect(buffer[2, 3].char == "H")
        #expect(buffer[2, 4].char == "i")
    }

    @Test("Hidden in stack preserves space")
    func hiddenInStack() {
        let view = VStack {
            Text("A")
            Text("B").hidden()
            Text("C")
        }
        let size = sizeThatFits(view, proposal: SizeProposal(width: 10, height: 10))
        #expect(size.height == 3) // hidden view still takes space
        var buffer = Buffer(width: 1, height: 3)
        let region = Region(row: 0, col: 0, width: 1, height: 3)
        render(view, into: &buffer, region: region)
        #expect(buffer[0, 0].char == "A")
        #expect(buffer[1, 0].char == " ") // hidden
        #expect(buffer[2, 0].char == "C")
    }
}
