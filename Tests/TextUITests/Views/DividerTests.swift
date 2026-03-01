import Testing
@testable import TextUI

@Suite("Divider")
struct DividerTests {
    // MARK: - Horizontal Sizing

    @Test("Horizontal divider fills width, height is 1")
    func horizontalSizing() {
        let size = Divider.horizontal.sizeThatFits(SizeProposal(width: 20, height: 5))
        #expect(size == Size2D(width: 20, height: 1))
    }

    @Test("Horizontal divider ideal size")
    func horizontalIdeal() {
        let size = Divider.horizontal.sizeThatFits(.unspecified)
        #expect(size == Size2D(width: 1, height: 1))
    }

    @Test("Horizontal divider max proposal")
    func horizontalMax() {
        let size = Divider.horizontal.sizeThatFits(.max)
        #expect(size == Size2D(width: Int.max, height: 1))
    }

    @Test("Horizontal divider always claims height 1 even if proposed 0")
    func horizontalMinHeight() {
        let size = Divider.horizontal.sizeThatFits(.zero)
        #expect(size == Size2D(width: 0, height: 1))
    }

    // MARK: - Vertical Sizing

    @Test("Vertical divider fills height, width is 1")
    func verticalSizing() {
        let size = Divider.vertical.sizeThatFits(SizeProposal(width: 20, height: 5))
        #expect(size == Size2D(width: 1, height: 5))
    }

    @Test("Vertical divider always claims width 1 even if proposed 0")
    func verticalMinWidth() {
        let size = Divider.vertical.sizeThatFits(.zero)
        #expect(size == Size2D(width: 1, height: 0))
    }

    // MARK: - Rendering

    @Test("Horizontal divider renders box-drawing characters")
    func horizontalRender() {
        var buffer = Buffer(width: 5, height: 1)
        Divider.horizontal.render(into: &buffer, region: Region(row: 0, col: 0, width: 5, height: 1))
        #expect(buffer[0, 0].char == "─")
        #expect(buffer[0, 4].char == "─")
    }

    @Test("Vertical divider renders box-drawing characters")
    func verticalRender() {
        var buffer = Buffer(width: 1, height: 3)
        Divider.vertical.render(into: &buffer, region: Region(row: 0, col: 0, width: 1, height: 3))
        #expect(buffer[0, 0].char == "│")
        #expect(buffer[2, 0].char == "│")
    }

    @Test("Divider in empty region renders nothing")
    func emptyRegion() {
        var buffer = Buffer(width: 5, height: 1)
        Divider.horizontal.render(into: &buffer, region: Region(row: 0, col: 0, width: 0, height: 0))
        #expect(buffer[0, 0] == .blank)
    }
}
