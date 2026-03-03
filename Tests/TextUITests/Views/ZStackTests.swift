import Testing
@testable import TextUI

@MainActor
@Suite("ZStack")
struct ZStackTests {
    @Test("Same proposal to all children")
    func sameProposal() {
        let view = ZStack {
            Text("Hi")
            Text("Hello")
        }
        // ZStack size = max of children
        let size = sizeThatFits(view, proposal: SizeProposal(width: 20, height: 5))
        #expect(size.width == 5) // "Hello" is widest
        #expect(size.height == 1)
    }

    @Test("Size is max of children")
    func maxSize() {
        let view = ZStack {
            Text("AB")
            Text("CDEF")
            Text("G")
        }
        let size = sizeThatFits(view, proposal: SizeProposal(width: 20, height: 5))
        #expect(size.width == 4) // "CDEF"
        #expect(size.height == 1)
    }

    @Test("Center alignment is default")
    func centerDefault() {
        let view = ZStack {
            Text("AAAA")
            Text("BB")
        }
        let size = sizeThatFits(view, proposal: SizeProposal(width: 20, height: 5))
        var buffer = Buffer(width: size.width, height: size.height)
        let region = Region(row: 0, col: 0, width: size.width, height: size.height)
        render(view, into: &buffer, region: region)
        // "AAAA" fills 4 cols, then "BB" centered at col 1
        #expect(buffer[0, 0].char == "A")
        #expect(buffer[0, 1].char == "B")
        #expect(buffer[0, 2].char == "B")
        #expect(buffer[0, 3].char == "A")
    }

    @Test("TopLeading alignment")
    func topLeadingAlignment() {
        let view = ZStack(alignment: .topLeading) {
            Text("AAAA")
            Text("BB")
        }
        var buffer = Buffer(width: 4, height: 1)
        let region = Region(row: 0, col: 0, width: 4, height: 1)
        render(view, into: &buffer, region: region)
        #expect(buffer[0, 0].char == "B")
        #expect(buffer[0, 1].char == "B")
        #expect(buffer[0, 2].char == "A")
        #expect(buffer[0, 3].char == "A")
    }

    @Test("Render order is back-to-front")
    func renderOrder() {
        let view = ZStack {
            Text("AAA")
            Text("BBB")
        }
        var buffer = Buffer(width: 3, height: 1)
        let region = Region(row: 0, col: 0, width: 3, height: 1)
        render(view, into: &buffer, region: region)
        // "BBB" renders last, so it overwrites "AAA"
        #expect(buffer[0, 0].char == "B")
        #expect(buffer[0, 1].char == "B")
        #expect(buffer[0, 2].char == "B")
    }

    @Test("Empty ZStack has zero size")
    func emptyZStack() {
        let view = ZStack {}
        let size = sizeThatFits(view, proposal: SizeProposal(width: 20, height: 5))
        #expect(size == .zero)
    }

    @Test("ZStack with multi-line children")
    func multiLine() {
        let view = ZStack {
            Text("A\nB\nC")
            Text("X")
        }
        let size = sizeThatFits(view, proposal: SizeProposal(width: 20, height: 10))
        #expect(size.width == 1)
        #expect(size.height == 3) // 3-line text is tallest
    }
}
