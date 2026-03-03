import Testing
@testable import TextUI

@MainActor
@Suite("ScrollView — defaultScrollAnchor")
struct ScrollViewAnchorTests {
    /// Builds a ScrollView with the given number of lines, all sharing
    /// the same `#fileID:#line` identity so state persists across calls.
    private static func makeView(lineCount: Int) -> ScrollView {
        ScrollView(showsIndicator: false) {
            ForEach(Array(0 ..< lineCount)) { i in
                Text("Line\(i)")
            }
        }
    }

    // MARK: - Bottom Anchor

    @Test("Bottom anchor: initial render snaps to bottom")
    func bottomAnchorInitialRender() {
        let store = FocusStore()
        var ctx = RenderContext()
        ctx.focusStore = store
        ctx.defaultScrollAnchor = .bottom

        let view = Self.makeView(lineCount: 5)

        var buffer = Buffer(width: 10, height: 3)
        let region = Region(row: 0, col: 0, width: 10, height: 3)
        render(view, into: &buffer, region: region, context: ctx)

        // Should show last 3 lines (snapped to bottom)
        #expect(buffer[0, 4].char == "2")
        #expect(buffer[1, 4].char == "3")
        #expect(buffer[2, 4].char == "4")
    }

    @Test("Bottom anchor: content growth while at bottom keeps offset at bottom")
    func bottomAnchorFollowsGrowth() {
        let store = FocusStore()
        var ctx = RenderContext()
        ctx.focusStore = store
        ctx.defaultScrollAnchor = .bottom

        let region = Region(row: 0, col: 0, width: 10, height: 3)

        // First render with 4 items in viewport of 3
        var buffer = Buffer(width: 10, height: 3)
        render(Self.makeView(lineCount: 4), into: &buffer, region: region, context: ctx)

        // Should be at bottom: Line1, Line2, Line3
        #expect(buffer[2, 4].char == "3")

        // Now render with 6 items (content grew)
        store.beginFrame()
        buffer = Buffer(width: 10, height: 3)
        render(Self.makeView(lineCount: 6), into: &buffer, region: region, context: ctx)

        // Should follow to new bottom: Line3, Line4, Line5
        #expect(buffer[0, 4].char == "3")
        #expect(buffer[1, 4].char == "4")
        #expect(buffer[2, 4].char == "5")
    }

    @Test("Bottom anchor: user scrolls up, offset stays despite content growth")
    func bottomAnchorUserScrollsUp() {
        let store = FocusStore()
        var ctx = RenderContext()
        ctx.focusStore = store
        ctx.defaultScrollAnchor = .bottom

        let region = Region(row: 0, col: 0, width: 10, height: 3)

        // Initial render — snaps to bottom
        var buffer = Buffer(width: 10, height: 3)
        render(Self.makeView(lineCount: 5), into: &buffer, region: region, context: ctx)
        store.applyDefaultFocus()

        // Re-render to register focus handler, then scroll up
        store.beginFrame()
        buffer = Buffer(width: 10, height: 3)
        render(Self.makeView(lineCount: 5), into: &buffer, region: region, context: ctx)
        _ = store.routeKeyEvent(.up)

        // Render with more content — user scrolled away, should NOT follow
        store.beginFrame()
        buffer = Buffer(width: 10, height: 3)
        render(Self.makeView(lineCount: 6), into: &buffer, region: region, context: ctx)

        // Should NOT be at the new bottom (Line3/4/5)
        // User was at offset 1 (scrolled up once from maxOffset=2), so showing Line1/2/3
        #expect(buffer[0, 4].char == "1")
        #expect(buffer[1, 4].char == "2")
        #expect(buffer[2, 4].char == "3")
    }

    @Test("Bottom anchor: scrolling back to bottom resumes auto-scroll")
    func bottomAnchorResumeAutoScroll() {
        let store = FocusStore()
        var ctx = RenderContext()
        ctx.focusStore = store
        ctx.defaultScrollAnchor = .bottom

        let region = Region(row: 0, col: 0, width: 10, height: 3)

        // Initial render — snaps to bottom
        var buffer = Buffer(width: 10, height: 3)
        render(Self.makeView(lineCount: 5), into: &buffer, region: region, context: ctx)
        store.applyDefaultFocus()

        // Re-render, scroll up, then scroll back to bottom with End
        store.beginFrame()
        buffer = Buffer(width: 10, height: 3)
        render(Self.makeView(lineCount: 5), into: &buffer, region: region, context: ctx)
        _ = store.routeKeyEvent(.up)
        _ = store.routeKeyEvent(.end)

        // Now render with more content — should follow again
        store.beginFrame()
        buffer = Buffer(width: 10, height: 3)
        render(Self.makeView(lineCount: 6), into: &buffer, region: region, context: ctx)

        // Should be at new bottom: Line3, Line4, Line5
        #expect(buffer[0, 4].char == "3")
        #expect(buffer[1, 4].char == "4")
        #expect(buffer[2, 4].char == "5")
    }

    // MARK: - Default behavior (no anchor)

    @Test("No anchor: offset stays at 0")
    func noAnchorDefaultBehavior() {
        let store = FocusStore()
        var ctx = RenderContext()
        ctx.focusStore = store

        var buffer = Buffer(width: 10, height: 3)
        let region = Region(row: 0, col: 0, width: 10, height: 3)
        render(Self.makeView(lineCount: 5), into: &buffer, region: region, context: ctx)

        // Default: starts at top
        #expect(buffer[0, 4].char == "0")
        #expect(buffer[1, 4].char == "1")
        #expect(buffer[2, 4].char == "2")
    }

    @Test("Top anchor: same as default, offset 0")
    func topAnchorSameAsDefault() {
        let store = FocusStore()
        var ctx = RenderContext()
        ctx.focusStore = store
        ctx.defaultScrollAnchor = .top

        var buffer = Buffer(width: 10, height: 3)
        let region = Region(row: 0, col: 0, width: 10, height: 3)
        render(Self.makeView(lineCount: 5), into: &buffer, region: region, context: ctx)

        // Top anchor: starts at top, same as default
        #expect(buffer[0, 4].char == "0")
        #expect(buffer[1, 4].char == "1")
        #expect(buffer[2, 4].char == "2")
    }
}
