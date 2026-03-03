import Testing
@testable import TextUI

@MainActor
@Suite("Padding Modifier")
struct PaddingTests {
    @Test("Uniform padding adds to all sides")
    func uniformPadding() {
        let view = Text("Hi").padding(2)
        let size = sizeThatFits(view, proposal: SizeProposal(width: 20, height: 10))
        // "Hi" is 2 wide, 1 tall; +4 horizontal, +4 vertical
        #expect(size.width == 6)
        #expect(size.height == 5)
    }

    @Test("Per-side padding applies independently")
    func perSidePadding() {
        let view = Text("Hi").padding(top: 1, leading: 2, bottom: 3, trailing: 4)
        let size = sizeThatFits(view, proposal: SizeProposal(width: 20, height: 10))
        #expect(size.width == 8) // 2 + 2 + 4
        #expect(size.height == 5) // 1 + 1 + 3
    }

    @Test("Horizontal/vertical padding shorthand")
    func hvPadding() {
        let view = Text("Hi").padding(horizontal: 3, vertical: 2)
        let size = sizeThatFits(view, proposal: SizeProposal(width: 20, height: 10))
        #expect(size.width == 8) // 2 + 3 + 3
        #expect(size.height == 5) // 1 + 2 + 2
    }

    @Test("Nil proposal is preserved through padding")
    func nilPreservation() {
        // With nil proposal (ideal size), padding should still add its amounts
        let view = Text("Hi").padding(1)
        let size = sizeThatFits(view, proposal: .unspecified)
        #expect(size.width == 4) // 2 + 1 + 1
        #expect(size.height == 3) // 1 + 1 + 1
    }

    @Test("Padding renders content at offset")
    func renderOffset() {
        let view = Text("AB").padding(1)
        let size = sizeThatFits(view, proposal: SizeProposal(width: 10, height: 5))
        var buffer = Buffer(width: size.width, height: size.height)
        let region = Region(row: 0, col: 0, width: size.width, height: size.height)
        render(view, into: &buffer, region: region)
        // "AB" should be at row 1, col 1 (offset by padding)
        #expect(buffer[1, 1].char == "A")
        #expect(buffer[1, 2].char == "B")
        // Padding cells should be blank
        #expect(buffer[0, 0].char == " ")
    }

    @Test("Zero padding is a no-op")
    func zeroPadding() {
        let view = Text("Hi").padding(0)
        let size = sizeThatFits(view, proposal: SizeProposal(width: 10, height: 5))
        #expect(size.width == 2)
        #expect(size.height == 1)
    }

    @Test("Padding with tight proposal wraps content")
    func tightProposal() {
        let view = Text("Hello").padding(1)
        // Propose width 4: inner gets 2, "Hello" (5 wide) wraps to 3 lines at width 2
        let size = sizeThatFits(view, proposal: SizeProposal(width: 4, height: 10))
        #expect(size.width == 4) // 2 + 1 + 1
        #expect(size.height == 5) // 3 (wrapped) + 1 + 1
    }
}
