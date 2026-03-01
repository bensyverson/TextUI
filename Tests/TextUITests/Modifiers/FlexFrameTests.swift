import Testing
@testable import TextUI

@Suite("FlexFrame Modifier")
struct FlexFrameTests {
    @Test("Both min and max clamp size")
    func bothMinMax() {
        let view = Text("Hi").frame(minWidth: 5, maxWidth: 10)
        let size = sizeThatFits(view, proposal: SizeProposal(width: 20, height: 5))
        // "Hi" is 2 wide, min is 5, so response is clamped to 5
        #expect(size.width == 5)
    }

    @Test("Only min enforces minimum")
    func onlyMin() {
        let view = Text("Hi").frame(minWidth: 5)
        let size = sizeThatFits(view, proposal: SizeProposal(width: 20, height: 5))
        #expect(size.width == 5) // "Hi" is 2, min is 5
    }

    @Test("Only min with large content passes through")
    func onlyMinLargeContent() {
        let view = Text("Hello World").frame(minWidth: 5)
        let size = sizeThatFits(view, proposal: SizeProposal(width: 20, height: 5))
        #expect(size.width == 11) // content is 11, larger than min
    }

    @Test("Only max caps proposal")
    func onlyMax() {
        let view = Text("Hello World").frame(maxWidth: 5)
        let size = sizeThatFits(view, proposal: SizeProposal(width: 20, height: 5))
        // Frame takes min(proposed, max) = min(20, 5) = 5
        #expect(size.width == 5)
    }

    @Test("maxWidth .max expands hugging view")
    func maxWidthExpands() {
        let view = Text("Hi").frame(maxWidth: .max)
        // Proposed 20: frame takes min(20, .max) = 20
        let size = sizeThatFits(view, proposal: SizeProposal(width: 20, height: 5))
        #expect(size.width == 20) // expands!
    }

    @Test("maxHeight .max expands hugging view")
    func maxHeightExpands() {
        let view = Text("Hi").frame(maxHeight: .max)
        let size = sizeThatFits(view, proposal: SizeProposal(width: 20, height: 10))
        #expect(size.height == 10)
    }

    @Test("Nil proposal passes through")
    func nilPassthrough() {
        let view = Text("Hi").frame(minWidth: 5, maxWidth: 10)
        let size = sizeThatFits(view, proposal: .unspecified)
        // nil proposal -> child gets nil -> ideal size 2 -> clamped to min 5
        #expect(size.width == 5)
    }

    @Test("Alignment within flex frame")
    func alignmentWithinFrame() {
        let view = Text("AB").frame(maxWidth: .max, alignment: .trailing)
        var buffer = Buffer(width: 10, height: 1)
        let region = Region(row: 0, col: 0, width: 10, height: 1)
        render(view, into: &buffer, region: region)
        // "AB" aligned trailing: col = 10 - 2 = 8
        #expect(buffer[0, 8].char == "A")
        #expect(buffer[0, 9].char == "B")
    }

    @Test("Min and max height work")
    func heightConstraints() {
        let view = Text("A\nB\nC").frame(minHeight: 5, maxHeight: 10)
        let size = sizeThatFits(view, proposal: SizeProposal(width: 10, height: 20))
        #expect(size.height == 5) // 3 lines, clamped up to min 5
    }
}
