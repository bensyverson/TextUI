import Testing
@testable import TextUI

@MainActor
@Suite("Canvas")
struct CanvasTests {
    @Test("Greedy sizing fills proposal")
    func greedySizing() {
        let view = Canvas { _, _ in }
        let size = sizeThatFits(view, proposal: SizeProposal(width: 10, height: 5))
        #expect(size.width == 10)
        #expect(size.height == 5)
    }

    @Test("Ideal size is zero")
    func idealSizeZero() {
        let view = Canvas { _, _ in }
        let size = sizeThatFits(view, proposal: .unspecified)
        #expect(size == .zero)
    }

    @Test("Draw closure executes")
    func drawExecutes() {
        let view = Canvas { buffer, region in
            buffer.write("X", row: region.row, col: region.col)
        }
        var buffer = Buffer(width: 3, height: 1)
        let region = Region(row: 0, col: 0, width: 3, height: 1)
        render(view, into: &buffer, region: region)
        #expect(buffer[0, 0].char == "X")
    }

    @Test("Region passed correctly")
    func regionCorrect() {
        // Verify by drawing a marker at the region's origin
        let view = Canvas { buffer, region in
            buffer.write("@", row: region.row, col: region.col)
        }
        var buffer = Buffer(width: 10, height: 5)
        let region = Region(row: 2, col: 3, width: 4, height: 2)
        render(view, into: &buffer, region: region)
        #expect(buffer[2, 3].char == "@")
        #expect(buffer[0, 0].char == " ") // not at origin
    }

    @Test("Canvas in frame")
    func canvasInFrame() {
        let view = Canvas { buffer, region in
            buffer.fill(region, char: "#")
        }.frame(width: 3, height: 2)
        var buffer = Buffer(width: 5, height: 4)
        let region = Region(row: 0, col: 0, width: 5, height: 4)
        render(view, into: &buffer, region: region)
        // Canvas centered in 5x4 frame: at (1,1) size 3x2
        #expect(buffer[1, 1].char == "#")
        #expect(buffer[2, 3].char == "#")
        // Outside canvas area should be blank
        #expect(buffer[0, 0].char == " ")
    }
}
