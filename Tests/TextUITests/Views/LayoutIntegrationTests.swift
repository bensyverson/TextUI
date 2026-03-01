import Testing
@testable import TextUI

@Suite("Layout Integration")
struct LayoutIntegrationTests {
    // MARK: - Status Bar

    @Test("HStack with Spacer renders left and right text at edges")
    func statusBar() {
        let stack = HStack(spacing: 0) {
            Text("left")
            Spacer()
            Text("right")
        }
        var buffer = Buffer(width: 80, height: 1)
        let region = Region(row: 0, col: 0, width: 80, height: 1)
        stack.render(into: &buffer, region: region)

        // "left" at col 0-3
        #expect(buffer[0, 0].char == "l")
        #expect(buffer[0, 3].char == "t")
        // "right" at col 75-79
        #expect(buffer[0, 75].char == "r")
        #expect(buffer[0, 79].char == "t")
        // Middle should be blank
        #expect(buffer[0, 40].char == " ")
    }

    // MARK: - Title-Divider-Body

    @Test("VStack with Title, Divider, Body")
    func titleDividerBody() {
        let stack = VStack {
            Text("Title")
            Divider.horizontal
            Text("Body")
        }
        var buffer = Buffer(width: 10, height: 3)
        let region = Region(row: 0, col: 0, width: 10, height: 3)
        stack.render(into: &buffer, region: region)

        #expect(buffer[0, 0].char == "T")
        #expect(buffer[0, 4].char == "e")
        #expect(buffer[1, 0].char == "─")
        #expect(buffer[1, 9].char == "─")
        #expect(buffer[2, 0].char == "B")
        #expect(buffer[2, 3].char == "y")
    }

    // MARK: - Nested Stacks

    @Test("HStack inside VStack")
    func nestedStacks() {
        let stack = VStack {
            HStack(spacing: 0) {
                Text("A")
                Text("B")
            }
            Text("C")
        }
        var buffer = Buffer(width: 10, height: 3)
        let region = Region(row: 0, col: 0, width: 10, height: 3)
        stack.render(into: &buffer, region: region)

        #expect(buffer[0, 0].char == "A")
        #expect(buffer[0, 1].char == "B")
        #expect(buffer[1, 0].char == "C")
    }

    @Test("VStack inside HStack")
    func vStackInsideHStack() {
        let stack = HStack(spacing: 0) {
            VStack {
                Text("1")
                Text("2")
            }
            Text("X")
        }
        var buffer = Buffer(width: 10, height: 3)
        let region = Region(row: 0, col: 0, width: 10, height: 3)
        stack.render(into: &buffer, region: region)

        #expect(buffer[0, 0].char == "1")
        #expect(buffer[1, 0].char == "2")
        #expect(buffer[0, 1].char == "X")
    }

    // MARK: - Composite View

    @Test("Custom composite view using HStack and Spacer")
    func compositeStatusBar() {
        let view = StatusBar(left: "File", right: "Ln 42")
        var buffer = Buffer(width: 20, height: 1)
        let region = Region(row: 0, col: 0, width: 20, height: 1)
        TextUI.render(view, into: &buffer, region: region)

        #expect(buffer[0, 0].char == "F")
        #expect(buffer[0, 3].char == "e")
        #expect(buffer[0, 15].char == "L")
        #expect(buffer[0, 19].char == "2")
    }

    // MARK: - Four Proposal Modes

    @Test("Stack with Spacer responds to all four proposal modes")
    func fourProposalModes() {
        let stack = HStack(spacing: 0) {
            Text("AB")
            Spacer()
            Text("CD")
        }

        // Ideal (nil): Spacer contributes 0, so width = 4
        let ideal = stack.sizeThatFits(.unspecified)
        #expect(ideal == Size2D(width: 4, height: 1))

        // Min (0): everything shrinks to 0
        let min = stack.sizeThatFits(.zero)
        #expect(min == .zero)

        // Max: Spacer expands to .max
        let max = stack.sizeThatFits(.max)
        #expect(max.width == Int.max)
        #expect(max.height == 1)

        // Concrete: distribute 40 cols
        let concrete = stack.sizeThatFits(SizeProposal(width: 40, height: 1))
        #expect(concrete == Size2D(width: 40, height: 1))
    }

    // MARK: - Multiple Spacers

    @Test("Multiple spacers share remaining space equally")
    func multipleSpacer() {
        let stack = HStack(spacing: 0) {
            Text("A")
            Spacer()
            Text("B")
            Spacer()
            Text("C")
        }
        var buffer = Buffer(width: 21, height: 1)
        let region = Region(row: 0, col: 0, width: 21, height: 1)
        stack.render(into: &buffer, region: region)

        // A at 0, B at 10, C at 20
        #expect(buffer[0, 0].char == "A")
        #expect(buffer[0, 10].char == "B")
        #expect(buffer[0, 20].char == "C")
    }
}

// MARK: - Test Helpers

private struct StatusBar: View {
    let left: String
    let right: String

    var body: HStack {
        HStack(spacing: 0) {
            Text(left)
            Spacer()
            Text(right)
        }
    }
}
