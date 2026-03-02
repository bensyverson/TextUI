import Testing
@testable import TextUI

@Suite("ButtonStyle")
struct ButtonStyleTests {
    // MARK: - Sizing

    @Test("Plain style sizing matches label")
    func plainSizing() {
        let button = Button("Submit") {}
        var ctx = RenderContext()
        ctx.buttonStyle = .plain
        let size = sizeThatFits(button, proposal: SizeProposal(width: 40, height: 10), context: ctx)
        #expect(size == Size2D(width: 6, height: 1))
    }

    @Test("Default style is plain when no style set")
    func defaultIsPlain() {
        let button = Button("Submit") {}
        let sizeDefault = sizeThatFits(button, proposal: SizeProposal(width: 40, height: 10))
        var ctx = RenderContext()
        ctx.buttonStyle = .plain
        let sizePlain = sizeThatFits(button, proposal: SizeProposal(width: 40, height: 10), context: ctx)
        #expect(sizeDefault == sizePlain)
    }

    @Test("Bordered sizing adds +4 width, +2 height")
    func borderedSizing() {
        let button = Button("Submit") {}
        var ctx = RenderContext()
        ctx.buttonStyle = .bordered
        let size = sizeThatFits(button, proposal: SizeProposal(width: 40, height: 10), context: ctx)
        // "Submit" = 6 wide, 1 tall; bordered adds +4 width, +2 height
        #expect(size == Size2D(width: 10, height: 3))
    }

    @Test("BorderedProminent sizing matches bordered")
    func borderedProminentSizing() {
        let button = Button("OK") {}
        var ctx = RenderContext()
        ctx.buttonStyle = .bordered
        let borderedSize = sizeThatFits(button, proposal: SizeProposal(width: 40, height: 10), context: ctx)
        ctx.buttonStyle = .borderedProminent
        let prominentSize = sizeThatFits(button, proposal: SizeProposal(width: 40, height: 10), context: ctx)
        #expect(borderedSize == prominentSize)
    }

    // MARK: - Rendering

    @Test("Bordered renders border characters")
    func borderedRendersBorder() {
        let button = Button("OK") {}
        var ctx = RenderContext()
        ctx.buttonStyle = .bordered
        let size = sizeThatFits(button, proposal: SizeProposal(width: 40, height: 10), context: ctx)
        var buffer = Buffer(width: size.width, height: size.height)
        let region = Region(row: 0, col: 0, width: size.width, height: size.height)
        render(button, into: &buffer, region: region, context: ctx)

        // Corners
        #expect(buffer[0, 0].char == "╭")
        #expect(buffer[0, size.width - 1].char == "╮")
        #expect(buffer[size.height - 1, 0].char == "╰")
        #expect(buffer[size.height - 1, size.width - 1].char == "╯")

        // Horizontal edges
        #expect(buffer[0, 1].char == "─")
        #expect(buffer[size.height - 1, 1].char == "─")

        // Vertical edges
        #expect(buffer[1, 0].char == "│")
        #expect(buffer[1, size.width - 1].char == "│")

        // Label inside with padding
        #expect(buffer[1, 2].char == "O")
        #expect(buffer[1, 3].char == "K")
    }

    @Test("BorderedProminent applies bold to label")
    func borderedProminentAppliesBold() {
        let button = Button("OK") {}
        var ctx = RenderContext()
        ctx.buttonStyle = .borderedProminent
        let size = sizeThatFits(button, proposal: SizeProposal(width: 40, height: 10), context: ctx)
        var buffer = Buffer(width: size.width, height: size.height)
        let region = Region(row: 0, col: 0, width: size.width, height: size.height)
        render(button, into: &buffer, region: region, context: ctx)

        // Label cells should be bold
        #expect(buffer[1, 2].style.bold)
        #expect(buffer[1, 3].style.bold)

        // Border cells should not be bold
        #expect(!buffer[0, 0].style.bold)
    }

    @Test("Bordered button not bold")
    func borderedNotBold() {
        let button = Button("OK") {}
        var ctx = RenderContext()
        ctx.buttonStyle = .bordered
        let size = sizeThatFits(button, proposal: SizeProposal(width: 40, height: 10), context: ctx)
        var buffer = Buffer(width: size.width, height: size.height)
        let region = Region(row: 0, col: 0, width: size.width, height: size.height)
        render(button, into: &buffer, region: region, context: ctx)

        // Label cells should not be bold
        #expect(!buffer[1, 2].style.bold)
    }

    @Test("Focused bordered applies inverse to border and label")
    func focusedBorderedInverse() {
        let store = FocusStore()
        var ctx = RenderContext()
        ctx.focusStore = store
        ctx.buttonStyle = .bordered

        let button = Button("OK") {}
        let size = sizeThatFits(button, proposal: SizeProposal(width: 40, height: 10), context: ctx)
        var buffer = Buffer(width: size.width, height: size.height)
        let region = Region(row: 0, col: 0, width: size.width, height: size.height)

        // First render to register, then apply focus and re-render
        render(button, into: &buffer, region: region, context: ctx)
        store.applyDefaultFocus()
        store.beginFrame()
        buffer = Buffer(width: size.width, height: size.height)
        render(button, into: &buffer, region: region, context: ctx)

        // Border corner should be inverse
        #expect(buffer[0, 0].style.inverse)
        // Label should be inverse
        #expect(buffer[1, 2].style.inverse)
    }

    // MARK: - Context propagation

    @Test("Style propagates through context via modifier")
    func stylePropagatesThroughContext() {
        let button = Button("OK") {}
        let styled = button.buttonStyle(.bordered)
        let size = sizeThatFits(styled, proposal: SizeProposal(width: 40, height: 10))
        // Should include border sizing: "OK" (2) + 4 = 6 wide, 1 + 2 = 3 tall
        #expect(size == Size2D(width: 6, height: 3))
    }
}
