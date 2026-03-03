import Testing
@testable import TextUI

@MainActor
@Suite("VStack")
struct VStackTests {
    // MARK: - Basic Sizing

    @Test("Ideal size sums child heights, max width")
    func idealSize() {
        let stack = VStack {
            Text("Hello")
            Text("Hi")
        }
        let size = stack.sizeThatFits(.unspecified)
        #expect(size == Size2D(width: 5, height: 2))
    }

    @Test("Ideal size with spacing")
    func idealSizeWithSpacing() {
        let stack = VStack(spacing: 1) {
            Text("A")
            Text("B")
            Text("C")
        }
        let size = stack.sizeThatFits(.unspecified)
        // 1 + 1 + 1 + 1 + 1 = 5 height, 1 width
        #expect(size == Size2D(width: 1, height: 5))
    }

    @Test("Minimum size is zero")
    func minimumSize() {
        let stack = VStack {
            Text("Hello")
        }
        let size = stack.sizeThatFits(.zero)
        #expect(size == .zero)
    }

    // MARK: - Spacer

    @Test("Spacer absorbs remaining height")
    func spacerAbsorbs() {
        let stack = VStack {
            Text("Top")
            Spacer()
            Text("Bottom")
        }
        let size = stack.sizeThatFits(SizeProposal(width: 10, height: 20))
        #expect(size == Size2D(width: 6, height: 20))
    }

    // MARK: - Rendering

    @Test("Renders children stacked vertically")
    func renderBasic() {
        let stack = VStack {
            Text("AB")
            Text("CD")
        }
        var buffer = Buffer(width: 10, height: 5)
        let region = Region(row: 0, col: 0, width: 10, height: 5)
        stack.render(into: &buffer, region: region)
        #expect(buffer.text == "AB\nCD")
    }

    @Test("Renders with spacing")
    func renderWithSpacing() {
        let stack = VStack(spacing: 1) {
            Text("A")
            Text("B")
        }
        var buffer = Buffer(width: 10, height: 5)
        let region = Region(row: 0, col: 0, width: 10, height: 5)
        stack.render(into: &buffer, region: region)
        #expect(buffer[0, 0].char == "A")
        #expect(buffer[1, 0].char == " ") // spacing row
        #expect(buffer[2, 0].char == "B")
    }

    // MARK: - Cross-Axis Alignment

    @Test("Leading alignment (default)")
    func leadingAlignment() {
        let stack = VStack(alignment: .leading) {
            Text("Long")
            Text("Hi")
        }
        var buffer = Buffer(width: 10, height: 5)
        let region = Region(row: 0, col: 0, width: 10, height: 5)
        stack.render(into: &buffer, region: region)
        #expect(buffer[0, 0].char == "L")
        #expect(buffer[1, 0].char == "H")
    }

    @Test("Center alignment")
    func centerAlignment() {
        let stack = VStack(alignment: .center) {
            Text("ABCDE")
            Text("X")
        }
        var buffer = Buffer(width: 10, height: 5)
        let region = Region(row: 0, col: 0, width: 10, height: 5)
        stack.render(into: &buffer, region: region)
        // "X" (1 wide) centered in 10-wide region → offset 4
        #expect(buffer[1, 4].char == "X")
    }

    @Test("Trailing alignment")
    func trailingAlignment() {
        let stack = VStack(alignment: .trailing) {
            Text("AB")
            Text("X")
        }
        var buffer = Buffer(width: 10, height: 5)
        let region = Region(row: 0, col: 0, width: 10, height: 5)
        stack.render(into: &buffer, region: region)
        // "AB" (2 wide) trailing in 10-wide region → offset 8
        #expect(buffer[0, 8].char == "A")
        #expect(buffer[0, 9].char == "B")
        // "X" (1 wide) trailing → offset 9
        #expect(buffer[1, 9].char == "X")
    }

    // MARK: - Horizontal Divider

    @Test("Horizontal divider in VStack fills width")
    func horizontalDivider() {
        let stack = VStack {
            Text("Title")
            Divider.horizontal
            Text("Body")
        }
        var buffer = Buffer(width: 10, height: 5)
        let region = Region(row: 0, col: 0, width: 10, height: 5)
        stack.render(into: &buffer, region: region)
        #expect(buffer[0, 0].char == "T")
        #expect(buffer[1, 0].char == "─")
        #expect(buffer[1, 9].char == "─")
        #expect(buffer[2, 0].char == "B")
    }

    // MARK: - Empty

    @Test("Empty VStack sizes to zero")
    func emptyStack() {
        let stack = VStack {}
        #expect(stack.sizeThatFits(.unspecified) == .zero)
    }

    // MARK: - Greedy Allocation with Equal Flexibility

    @Test("Bordered child gets enough height for content when siblings are equal flexibility")
    func borderedChildGetsFullHeight() {
        // Regression: when all children have the same flexibility, the
        // old equal-share division could under-allocate bordered views
        // (min height 2) leaving no room for their inner content.
        let stack = VStack {
            Text("Top")
            Text("Middle")
                .padding(horizontal: 1)
                .border(.square)
            Text("Bottom")
        }
        // Ideal: Top(1) + Middle(3) + Bottom(1) = 5
        // Propose exactly 5 height — should allocate perfectly
        let size = stack.sizeThatFits(SizeProposal(width: 20, height: 5))
        #expect(size.height == 5)

        var buffer = Buffer(width: 20, height: 5)
        let region = Region(row: 0, col: 0, width: 20, height: 5)
        render(stack, into: &buffer, region: region)

        // Top text at row 0
        #expect(buffer[0, 0].char == "T")
        // Border at row 1
        #expect(buffer[1, 0].char == "┌")
        // Content inside border at row 2
        #expect(buffer[2, 2].char == "M")
        // Border bottom at row 3
        #expect(buffer[3, 0].char == "└")
        // Bottom text at row 4
        #expect(buffer[4, 0].char == "B")
    }
}
