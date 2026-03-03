import Testing
@testable import TextUI

@MainActor
@Suite("Line Limit, Truncation Mode, and Multiline Text Alignment Modifiers")
struct LineLimitTests {
    @Test("lineLimit flows through RenderContext")
    func lineLimitContext() {
        var ctx = RenderContext()
        #expect(ctx.lineLimit == nil)
        ctx.lineLimit = 3
        #expect(ctx.lineLimit == 3)
    }

    @Test("truncationMode flows through RenderContext")
    func truncationModeContext() {
        var ctx = RenderContext()
        #expect(ctx.truncationMode == nil)
        ctx.truncationMode = .head
        #expect(ctx.truncationMode == .head)
    }

    @Test("multilineTextAlignment flows through RenderContext")
    func multilineTextAlignmentContext() {
        var ctx = RenderContext()
        #expect(ctx.multilineTextAlignment == nil)
        ctx.multilineTextAlignment = .center
        #expect(ctx.multilineTextAlignment == .center)
    }

    @Test("LineLimitView passes context to child for sizeThatFits")
    func lineLimitViewSizing() {
        let text = Text("one two three four five six")
        let limited = LineLimitView(content: text, limit: 2)
        let size = limited.sizeThatFits(SizeProposal(width: 5, height: 10))
        #expect(size.height == 2)
    }

    @Test("TruncationModeView passes context to child for render")
    func truncationModeViewRender() {
        var buffer = Buffer(width: 10, height: 1)
        let region = Region(row: 0, col: 0, width: 10, height: 1)
        let text = Text("Hello World and more")
        let view = LineLimitView(
            content: TruncationModeView(content: text, mode: .head),
            limit: 1,
        )
        view.render(into: &buffer, region: region)
        // lineLimit=1 + head truncation: "… and more"
        #expect(buffer.text.hasPrefix("\u{2026}"))
    }

    @Test("MultilineTextAlignmentView passes context to child for render")
    func multilineAlignmentViewRender() {
        var buffer = Buffer(width: 10, height: 2)
        let region = Region(row: 0, col: 0, width: 10, height: 2)
        let view = MultilineTextAlignmentView(
            content: Text("Hi\nWorld"),
            alignment: .trailing,
        )
        view.render(into: &buffer, region: region)
        // "Hi" trailing in 10 → col 8
        #expect(buffer[0, 8].char == "H")
    }
}
