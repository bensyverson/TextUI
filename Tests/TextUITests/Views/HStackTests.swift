import Testing
@testable import TextUI

@Suite("HStack")
struct HStackTests {
    // MARK: - Basic Sizing

    @Test("Ideal size sums child widths, max height")
    func idealSize() {
        let stack = HStack(spacing: 0) {
            Text("AB")
            Text("CD")
        }
        let size = stack.sizeThatFits(.unspecified)
        #expect(size == Size2D(width: 4, height: 1))
    }

    @Test("Default spacing is 1")
    func defaultSpacing() {
        let stack = HStack {
            Text("A")
            Text("B")
        }
        let size = stack.sizeThatFits(.unspecified)
        // 1 + 1 + 1 = 3 (A + spacing + B)
        #expect(size == Size2D(width: 3, height: 1))
    }

    @Test("Ideal size with spacing")
    func idealSizeWithSpacing() {
        let stack = HStack(spacing: 2) {
            Text("A")
            Text("B")
            Text("C")
        }
        let size = stack.sizeThatFits(.unspecified)
        // 1 + 2 + 1 + 2 + 1 = 7
        #expect(size == Size2D(width: 7, height: 1))
    }

    @Test("Minimum size is zero")
    func minimumSize() {
        let stack = HStack(spacing: 0) {
            Text("Hello")
            Text("World")
        }
        let size = stack.sizeThatFits(.zero)
        #expect(size == .zero)
    }

    // MARK: - Spacer

    @Test("Spacer absorbs remaining width")
    func spacerAbsorbs() {
        let stack = HStack(spacing: 0) {
            Text("L")
            Spacer()
            Text("R")
        }
        let size = stack.sizeThatFits(SizeProposal(width: 20, height: 1))
        #expect(size == Size2D(width: 20, height: 1))
    }

    // MARK: - Rendering

    @Test("Renders children side by side")
    func renderBasic() {
        let stack = HStack(spacing: 0) {
            Text("AB")
            Text("CD")
        }
        var buffer = Buffer(width: 10, height: 1)
        let region = Region(row: 0, col: 0, width: 10, height: 1)
        stack.render(into: &buffer, region: region)
        #expect(buffer.text == "ABCD")
    }

    @Test("Renders with spacing")
    func renderWithSpacing() {
        let stack = HStack(spacing: 1) {
            Text("A")
            Text("B")
        }
        var buffer = Buffer(width: 10, height: 1)
        let region = Region(row: 0, col: 0, width: 10, height: 1)
        stack.render(into: &buffer, region: region)
        #expect(buffer[0, 0].char == "A")
        #expect(buffer[0, 1].char == " ") // spacing
        #expect(buffer[0, 2].char == "B")
    }

    @Test("Spacer pushes text to right edge")
    func spacerPushesRight() {
        let stack = HStack(spacing: 0) {
            Text("left")
            Spacer()
            Text("right")
        }
        var buffer = Buffer(width: 80, height: 1)
        let region = Region(row: 0, col: 0, width: 80, height: 1)
        stack.render(into: &buffer, region: region)
        #expect(buffer[0, 0].char == "l")
        #expect(buffer[0, 3].char == "t")
        #expect(buffer[0, 75].char == "r")
        #expect(buffer[0, 79].char == "t")
    }

    // MARK: - Cross-Axis Alignment

    @Test("Top alignment (default)")
    func topAlignment() {
        let stack = HStack(alignment: .top, spacing: 0) {
            Text("A\nB")
            Text("X")
        }
        var buffer = Buffer(width: 10, height: 3)
        let region = Region(row: 0, col: 0, width: 10, height: 3)
        stack.render(into: &buffer, region: region)
        #expect(buffer[0, 0].char == "A")
        #expect(buffer[1, 0].char == "B")
        #expect(buffer[0, 1].char == "X")
    }

    @Test("Bottom alignment")
    func bottomAlignment() {
        let stack = HStack(alignment: .bottom, spacing: 0) {
            Text("A\nB")
            Text("X")
        }
        var buffer = Buffer(width: 10, height: 3)
        let region = Region(row: 0, col: 0, width: 10, height: 3)
        stack.render(into: &buffer, region: region)
        // "A\nB" (2 rows) bottom-aligned in 3-row region → starts at row 1
        #expect(buffer[1, 0].char == "A")
        #expect(buffer[2, 0].char == "B")
        // "X" (1 row) bottom-aligned in 3-row region → starts at row 2
        #expect(buffer[2, 1].char == "X")
    }

    @Test("Center alignment")
    func centerAlignment() {
        let stack = HStack(alignment: .center, spacing: 0) {
            Text("A\nB\nC")
            Text("X")
        }
        var buffer = Buffer(width: 10, height: 3)
        let region = Region(row: 0, col: 0, width: 10, height: 3)
        stack.render(into: &buffer, region: region)
        // "X" (1 row) centered in 3-row region → offset 1
        #expect(buffer[1, 1].char == "X")
    }

    // MARK: - Flexibility

    @Test("Inflexible children get their ideal size")
    func inflexibleFirst() {
        let stack = HStack(spacing: 0) {
            Text("ABCDE") // 5 wide, inflexible
            Spacer() // fully flexible
        }
        let size = stack.sizeThatFits(SizeProposal(width: 20, height: 1))
        // Text gets 5, Spacer gets 15
        #expect(size == Size2D(width: 20, height: 1))
    }

    @Test("Vertical divider in HStack")
    func verticalDividerInHStack() {
        let stack = HStack(spacing: 0) {
            Text("A")
            Divider.vertical
            Text("B")
        }
        var buffer = Buffer(width: 10, height: 3)
        let region = Region(row: 0, col: 0, width: 10, height: 3)
        stack.render(into: &buffer, region: region)
        #expect(buffer[0, 1].char == "│")
        #expect(buffer[1, 1].char == "│")
        #expect(buffer[2, 1].char == "│")
    }

    // MARK: - Empty

    @Test("Empty HStack sizes to zero")
    func emptyStack() {
        let stack = HStack {}
        #expect(stack.sizeThatFits(.unspecified) == .zero)
    }
}
