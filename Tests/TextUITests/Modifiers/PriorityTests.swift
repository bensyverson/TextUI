import Testing
@testable import TextUI

@Suite("Layout Priority Modifier")
struct PriorityTests {
    @Test("Higher priority gets space first")
    func higherPriorityFirst() {
        // "Hello" (priority 1) and a Spacer and "World" (default priority)
        // Priority 1 gets allocated first with full share, then remainder to others
        // Use equal-flexibility children where priority changes allocation order
        let view2 = HStack(spacing: 0) {
            Text("ABCDE").layoutPriority(1)
            Text("FGHIJ")
        }
        // 7 cols: ABCDE (prio 1) allocated first: share=7/2=3, takes 3 "ABC"
        // FGHIJ gets 4, takes 4 "FGHI"
        // Without priority: both have flex=5, sorted by index, first gets 3, second gets 4
        // With priority: ABCDE goes first regardless of original order
        var buffer = Buffer(width: 7, height: 1)
        let region = Region(row: 0, col: 0, width: 7, height: 1)
        render(view2, into: &buffer, region: region)
        // ABCDE rendered at col 0 (3 chars), FGHIJ at col 3 (4 chars)
        #expect(buffer[0, 0].char == "A")
        #expect(buffer[0, 2].char == "C")
        #expect(buffer[0, 3].char == "F")
    }

    @Test("Default priority is 0")
    func defaultPriority() {
        // Without layoutPriority, both get equal shares
        let view = HStack(spacing: 0) {
            Text("Hello")
            Text("World")
        }
        let size = sizeThatFits(view, proposal: SizeProposal(width: 8, height: 1))
        // Each gets 4
        #expect(size.width == 8)
    }

    @Test("Priority does not affect sizing")
    func sizeUnchanged() {
        let text = Text("Hello")
        let prioritized = text.layoutPriority(1)
        let textSize = sizeThatFits(text, proposal: SizeProposal(width: 20, height: 5))
        let prioSize = sizeThatFits(prioritized, proposal: SizeProposal(width: 20, height: 5))
        #expect(textSize == prioSize)
    }

    @Test("Priority with Spacer interaction")
    func priorityWithSpacer() {
        // Text with priority should get its full size before Spacer
        let view = HStack(spacing: 0) {
            Text("Hello").layoutPriority(1)
            Spacer()
        }
        let size = sizeThatFits(view, proposal: SizeProposal(width: 20, height: 1))
        #expect(size.width == 20)
        var buffer = Buffer(width: 20, height: 1)
        let region = Region(row: 0, col: 0, width: 20, height: 1)
        render(view, into: &buffer, region: region)
        #expect(buffer[0, 0].char == "H")
        #expect(buffer[0, 4].char == "o")
    }

    @Test("Multiple priority levels")
    func multiplePriorities() {
        // Three texts: A(prio 2), B(prio 1), C(prio 0)
        // In 6 columns: A gets 1 first, then B gets min(1, remaining), then C
        let view = HStack(spacing: 0) {
            Text("AA").layoutPriority(2)
            Text("BBB").layoutPriority(1)
            Text("CCCC")
        }
        let size = sizeThatFits(view, proposal: SizeProposal(width: 6, height: 1))
        var buffer = Buffer(width: size.width, height: size.height)
        let region = Region(row: 0, col: 0, width: size.width, height: size.height)
        render(view, into: &buffer, region: region)
        // AA (prio 2) gets allocated first: share = 6/3 = 2, takes 2
        // BBB (prio 1) gets allocated next: share = 4/2 = 2, takes 2 (truncated)
        // CCCC (prio 0) gets allocated last: share = 2/1 = 2, takes 2
        #expect(buffer[0, 0].char == "A")
        #expect(buffer[0, 1].char == "A")
        #expect(buffer[0, 2].char == "B")
        #expect(buffer[0, 3].char == "B")
    }
}
