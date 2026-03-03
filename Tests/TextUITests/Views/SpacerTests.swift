import Testing
@testable import TextUI

@MainActor
@Suite("Spacer")
struct SpacerTests {
    // MARK: - Default Axis (.both)

    @Test("Default spacer expands on both axes")
    func defaultExpandsBoth() {
        let spacer = Spacer()
        let size = spacer.sizeThatFits(SizeProposal(width: 40, height: 10))
        #expect(size == Size2D(width: 40, height: 10))
    }

    @Test("Default spacer ideal size respects minLength")
    func defaultIdealMinLength() {
        let spacer = Spacer(minLength: 5)
        let size = spacer.sizeThatFits(.unspecified)
        #expect(size == Size2D(width: 5, height: 5))
    }

    // MARK: - Horizontal Axis

    @Test("Horizontal spacer expands on width, zero on height")
    func horizontalExpands() {
        let spacer = Spacer().withAxis(.horizontal)
        let size = spacer.sizeThatFits(SizeProposal(width: 40, height: 10))
        #expect(size == Size2D(width: 40, height: 0))
    }

    @Test("Horizontal spacer with minLength")
    func horizontalMinLength() {
        let spacer = Spacer(minLength: 3).withAxis(.horizontal)
        let size = spacer.sizeThatFits(SizeProposal(width: 1, height: 10))
        #expect(size == Size2D(width: 3, height: 0))
    }

    @Test("Horizontal spacer ideal size is minLength")
    func horizontalIdeal() {
        let spacer = Spacer(minLength: 2).withAxis(.horizontal)
        let size = spacer.sizeThatFits(.unspecified)
        #expect(size == Size2D(width: 2, height: 0))
    }

    @Test("Horizontal spacer with max proposal")
    func horizontalMax() {
        let spacer = Spacer().withAxis(.horizontal)
        let size = spacer.sizeThatFits(.max)
        #expect(size.width == Int.max)
        #expect(size.height == 0)
    }

    // MARK: - Vertical Axis

    @Test("Vertical spacer expands on height, zero on width")
    func verticalExpands() {
        let spacer = Spacer().withAxis(.vertical)
        let size = spacer.sizeThatFits(SizeProposal(width: 40, height: 10))
        #expect(size == Size2D(width: 0, height: 10))
    }

    @Test("Vertical spacer with minLength")
    func verticalMinLength() {
        let spacer = Spacer(minLength: 3).withAxis(.vertical)
        let size = spacer.sizeThatFits(SizeProposal(width: 40, height: 1))
        #expect(size == Size2D(width: 0, height: 3))
    }

    // MARK: - Rendering

    @Test("Spacer renders nothing")
    func rendersNothing() {
        let spacer = Spacer().withAxis(.horizontal)
        var buffer = Buffer(width: 10, height: 1)
        spacer.render(into: &buffer, region: Region(row: 0, col: 0, width: 10, height: 1))
        for c in 0 ..< 10 {
            #expect(buffer[0, c] == .blank)
        }
    }
}
