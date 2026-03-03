import Testing
@testable import TextUI

@MainActor
@Suite("Color View")
struct ColorTests {
    @Test("Greedy sizing fills proposal")
    func greedySizing() {
        let view = Color(.blue)
        let size = sizeThatFits(view, proposal: SizeProposal(width: 10, height: 5))
        #expect(size.width == 10)
        #expect(size.height == 5)
    }

    @Test("Ideal size is zero")
    func idealSizeZero() {
        let view = Color(.blue)
        let size = sizeThatFits(view, proposal: .unspecified)
        #expect(size == .zero)
    }

    @Test("Renders solid background")
    func rendersSolidBg() {
        let view = Color(.green)
        var buffer = Buffer(width: 3, height: 2)
        let region = Region(row: 0, col: 0, width: 3, height: 2)
        render(view, into: &buffer, region: region)
        for r in 0 ..< 2 {
            for c in 0 ..< 3 {
                #expect(buffer[r, c].style.bg == .green)
            }
        }
    }

    @Test("Color in ZStack with Text overlay")
    func colorWithTextOverlay() {
        let view = ZStack {
            Color(.blue)
            Text("Hi")
        }
        var buffer = Buffer(width: 5, height: 3)
        let region = Region(row: 0, col: 0, width: 5, height: 3)
        render(view, into: &buffer, region: region)
        // Color fills entire region with blue bg
        #expect(buffer[0, 0].style.bg == .blue)
        // Text "Hi" centered: col = (5-2)/2 = 1, row = (3-1)/2 = 1
        #expect(buffer[1, 1].char == "H")
        #expect(buffer[1, 2].char == "i")
        // Text cells have no bg (plain style), but blue bg from Color remains
        // because Color renders first, then Text overwrites chars but sets bg=nil
        // Actually Text uses .plain style which has bg=nil, overwriting the blue
        // This is expected — Text overwrites the cell completely
    }

    @Test("Color minimum size is zero")
    func minimumSizeZero() {
        let view = Color(.red)
        let size = sizeThatFits(view, proposal: .zero)
        #expect(size == .zero)
    }
}
