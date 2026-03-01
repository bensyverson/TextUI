import Testing
@testable import TextUI

@Suite("FixedSize Modifier")
struct FixedSizeTests {
    @Test("fixedSize replaces proposal with nil on both axes")
    func bothAxes() {
        let text = Text("Hello World")
        // Without fixedSize, proposed width 5 truncates
        let truncated = sizeThatFits(text, proposal: SizeProposal(width: 5, height: 1))
        #expect(truncated.width == 5)

        // With fixedSize, reports ideal width
        let fixed = text.fixedSize()
        let size = sizeThatFits(fixed, proposal: SizeProposal(width: 5, height: 1))
        #expect(size.width == 11) // "Hello World" ideal width
        #expect(size.height == 1)
    }

    @Test("fixedSize horizontal only")
    func horizontalOnly() {
        let text = Text("Hello")
        let fixed = text.fixedSize(horizontal: true, vertical: false)
        let size = sizeThatFits(fixed, proposal: SizeProposal(width: 2, height: 1))
        #expect(size.width == 5) // ideal width
        #expect(size.height == 1) // proposal height preserved
    }

    @Test("fixedSize vertical only")
    func verticalOnly() {
        let text = Text("A\nB\nC")
        let fixed = text.fixedSize(horizontal: false, vertical: true)
        let size = sizeThatFits(fixed, proposal: SizeProposal(width: 2, height: 1))
        #expect(size.width == 1) // proposal width respected (clamped to content)
        #expect(size.height == 3) // ideal height
    }

    @Test("fixedSize with both false is a no-op")
    func neitherAxis() {
        let text = Text("Hello")
        let fixed = text.fixedSize(horizontal: false, vertical: false)
        let size = sizeThatFits(fixed, proposal: SizeProposal(width: 3, height: 1))
        #expect(size.width == 3)
    }

    @Test("fixedSize renders content")
    func renders() {
        let view = Text("AB").fixedSize()
        var buffer = Buffer(width: 5, height: 1)
        let region = Region(row: 0, col: 0, width: 5, height: 1)
        render(view, into: &buffer, region: region)
        #expect(buffer[0, 0].char == "A")
        #expect(buffer[0, 1].char == "B")
    }
}
