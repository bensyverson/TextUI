import Testing
@testable import TextUI

@Suite("EmptyView")
struct EmptyViewTests {
    @Test("Always returns zero size")
    func alwaysZero() {
        let view = EmptyView()
        #expect(view.sizeThatFits(.unspecified) == .zero)
        #expect(view.sizeThatFits(.zero) == .zero)
        #expect(view.sizeThatFits(.max) == .zero)
        #expect(view.sizeThatFits(SizeProposal(width: 80, height: 24)) == .zero)
    }

    @Test("Renders nothing into buffer")
    func rendersNothing() {
        let view = EmptyView()
        var buffer = Buffer(width: 5, height: 3)
        let region = Region(row: 0, col: 0, width: 5, height: 3)
        view.render(into: &buffer, region: region)
        // All cells should remain blank
        for r in 0 ..< 3 {
            for c in 0 ..< 5 {
                #expect(buffer[r, c] == .blank)
            }
        }
    }
}
