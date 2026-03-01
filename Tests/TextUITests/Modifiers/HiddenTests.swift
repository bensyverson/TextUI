import Testing
@testable import TextUI

@Suite("Hidden Modifier")
struct HiddenTests {
    @Test("Hidden view has same size as content")
    func sameSize() {
        let text = Text("Hello")
        let hidden = text.hidden()
        let textSize = sizeThatFits(text, proposal: SizeProposal(width: 20, height: 5))
        let hiddenSize = sizeThatFits(hidden, proposal: SizeProposal(width: 20, height: 5))
        #expect(textSize == hiddenSize)
    }

    @Test("Hidden view renders nothing")
    func rendersNothing() {
        let view = Text("Hello").hidden()
        let size = sizeThatFits(view, proposal: SizeProposal(width: 20, height: 5))
        var buffer = Buffer(width: size.width, height: size.height)
        let region = Region(row: 0, col: 0, width: size.width, height: size.height)
        render(view, into: &buffer, region: region)
        // All cells should be blank
        for r in 0 ..< buffer.height {
            for c in 0 ..< buffer.width {
                #expect(buffer[r, c].char == " ")
            }
        }
    }

    @Test("Hidden view ideal size matches content ideal size")
    func idealSize() {
        let text = Text("Test")
        let hidden = text.hidden()
        let textSize = sizeThatFits(text, proposal: .unspecified)
        let hiddenSize = sizeThatFits(hidden, proposal: .unspecified)
        #expect(textSize == hiddenSize)
    }
}
