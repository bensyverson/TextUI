import Testing
@testable import TextUI

@Suite("ForEach")
struct ForEachTests {
    @Test("ForEach in VStack renders all items")
    func inVStack() {
        let items = ["A", "B", "C"]
        let view = VStack {
            ForEach(items) { item in
                Text(item)
            }
        }
        let size = sizeThatFits(view, proposal: SizeProposal(width: 10, height: 10))
        #expect(size.height == 3)
        var buffer = Buffer(width: size.width, height: size.height)
        let region = Region(row: 0, col: 0, width: size.width, height: size.height)
        render(view, into: &buffer, region: region)
        #expect(buffer[0, 0].char == "A")
        #expect(buffer[1, 0].char == "B")
        #expect(buffer[2, 0].char == "C")
    }

    @Test("ForEach with empty collection")
    func emptyCollection() {
        let items: [String] = []
        let view = VStack {
            ForEach(items) { item in
                Text(item)
            }
        }
        let size = sizeThatFits(view, proposal: SizeProposal(width: 10, height: 10))
        #expect(size == .zero)
    }

    @Test("ForEach is layout-transparent in stack")
    func layoutTransparent() {
        let view = VStack {
            Text("Before")
            ForEach(["X", "Y"]) { item in
                Text(item)
            }
            Text("After")
        }
        let size = sizeThatFits(view, proposal: SizeProposal(width: 10, height: 10))
        // 4 children after flattening: Before, X, Y, After
        #expect(size.height == 4)
    }

    @Test("ForEach with multi-view closures")
    func multiViewClosure() {
        let items = ["A"]
        let view = VStack {
            ForEach(items) { item in
                Text(item)
                Text("\(item)!")
            }
        }
        let size = sizeThatFits(view, proposal: SizeProposal(width: 10, height: 10))
        // Each item produces 2 views, 1 item = 2 children
        #expect(size.height == 2)
    }

    @Test("ForEach in HStack")
    func inHStack() {
        let items = ["A", "B", "C"]
        let view = HStack {
            ForEach(items) { item in
                Text(item)
            }
        }
        let size = sizeThatFits(view, proposal: SizeProposal(width: 10, height: 5))
        #expect(size.width == 3)
        var buffer = Buffer(width: 3, height: 1)
        let region = Region(row: 0, col: 0, width: 3, height: 1)
        render(view, into: &buffer, region: region)
        #expect(buffer[0, 0].char == "A")
        #expect(buffer[0, 1].char == "B")
        #expect(buffer[0, 2].char == "C")
    }
}
