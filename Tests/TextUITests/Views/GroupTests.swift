import Testing
@testable import TextUI

@Suite("Group")
struct GroupTests {
    @Test("Group is layout-transparent in VStack")
    func layoutTransparentInVStack() {
        let view = VStack {
            Group {
                Text("A")
                Text("B")
            }
            Text("C")
        }
        let size = sizeThatFits(view, proposal: SizeProposal(width: 10, height: 10))
        // 3 children after flattening: A, B, C
        #expect(size.height == 3)
        var buffer = Buffer(width: size.width, height: size.height)
        let region = Region(row: 0, col: 0, width: size.width, height: size.height)
        render(view, into: &buffer, region: region)
        #expect(buffer[0, 0].char == "A")
        #expect(buffer[1, 0].char == "B")
        #expect(buffer[2, 0].char == "C")
    }

    @Test("Empty Group")
    func emptyGroup() {
        let view = VStack {
            Group {}
            Text("A")
        }
        let size = sizeThatFits(view, proposal: SizeProposal(width: 10, height: 10))
        #expect(size.height == 1)
    }

    @Test("Group bare usage shows first child")
    func bareUsage() {
        let view = Group {
            Text("First")
            Text("Second")
        }
        let size = sizeThatFits(view, proposal: SizeProposal(width: 20, height: 5))
        #expect(size.width == 5) // "First"
    }
}
