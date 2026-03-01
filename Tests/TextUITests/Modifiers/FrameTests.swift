import Testing
@testable import TextUI

@Suite("Frame Modifier")
struct FrameTests {
    @Test("Exact width overrides child")
    func exactWidth() {
        let view = Text("Hi").frame(width: 10)
        let size = sizeThatFits(view, proposal: SizeProposal(width: 20, height: 5))
        #expect(size.width == 10)
        #expect(size.height == 1)
    }

    @Test("Exact height overrides child")
    func exactHeight() {
        let view = Text("Hi").frame(height: 5)
        let size = sizeThatFits(view, proposal: SizeProposal(width: 20, height: 10))
        #expect(size.width == 2) // child's width
        #expect(size.height == 5)
    }

    @Test("Both width and height")
    func bothDimensions() {
        let view = Text("Hi").frame(width: 10, height: 5)
        let size = sizeThatFits(view, proposal: SizeProposal(width: 20, height: 20))
        #expect(size.width == 10)
        #expect(size.height == 5)
    }

    @Test("Nil dimensions pass through to child")
    func nilPassthrough() {
        let view = Text("Hello").frame()
        let size = sizeThatFits(view, proposal: SizeProposal(width: 20, height: 5))
        #expect(size.width == 5) // "Hello" hugs
        #expect(size.height == 1)
    }

    @Test("Child aligned center within larger frame")
    func centerAlignment() {
        let view = Text("AB").frame(width: 6, height: 3, alignment: .center)
        var buffer = Buffer(width: 6, height: 3)
        let region = Region(row: 0, col: 0, width: 6, height: 3)
        render(view, into: &buffer, region: region)
        // "AB" centered: col = (6-2)/2 = 2, row = (3-1)/2 = 1
        #expect(buffer[1, 2].char == "A")
        #expect(buffer[1, 3].char == "B")
    }

    @Test("Child aligned topLeading within larger frame")
    func topLeadingAlignment() {
        let view = Text("AB").frame(width: 6, height: 3, alignment: .topLeading)
        var buffer = Buffer(width: 6, height: 3)
        let region = Region(row: 0, col: 0, width: 6, height: 3)
        render(view, into: &buffer, region: region)
        #expect(buffer[0, 0].char == "A")
        #expect(buffer[0, 1].char == "B")
    }

    @Test("Child aligned bottomTrailing within larger frame")
    func bottomTrailingAlignment() {
        let view = Text("AB").frame(width: 6, height: 3, alignment: .bottomTrailing)
        var buffer = Buffer(width: 6, height: 3)
        let region = Region(row: 0, col: 0, width: 6, height: 3)
        render(view, into: &buffer, region: region)
        #expect(buffer[2, 4].char == "A")
        #expect(buffer[2, 5].char == "B")
    }

    @Test("Frame smaller than child clips")
    func frameClips() {
        let view = Text("Hello").frame(width: 3, height: 1)
        let size = sizeThatFits(view, proposal: SizeProposal(width: 20, height: 5))
        #expect(size.width == 3)
        var buffer = Buffer(width: 3, height: 1)
        let region = Region(row: 0, col: 0, width: 3, height: 1)
        render(view, into: &buffer, region: region)
        #expect(buffer[0, 0].char == "H")
        #expect(buffer[0, 1].char == "e")
        #expect(buffer[0, 2].char == "l")
    }
}
