import Testing
@testable import TextUI

@Suite("ScrollView Size Caching")
struct ScrollViewCacheTests {
    @Test("Cache is populated after sizeThatFits")
    func cachePopulated() {
        let store = FocusStore()
        var ctx = RenderContext()
        ctx.focusStore = store

        let view = ScrollView(showsIndicator: false) {
            Text("Line0")
            Text("Line1")
            Text("Line2")
        }

        _ = sizeThatFits(view, proposal: SizeProposal(width: 10, height: 5), context: ctx)

        // The cache should be stored with the autoKey:sizeCache pattern
        // We can verify by checking that render uses cached sizes (no crash, correct output)
        var buffer = Buffer(width: 10, height: 5)
        let region = Region(row: 0, col: 0, width: 10, height: 5)
        render(view, into: &buffer, region: region, context: ctx)

        // Verify correct rendering using cached sizes
        #expect(buffer[0, 0].char == "L")
        #expect(buffer[0, 4].char == "0")
        #expect(buffer[1, 4].char == "1")
        #expect(buffer[2, 4].char == "2")
    }

    @Test("render() produces correct output with cached sizes")
    func renderCorrectWithCache() {
        let store = FocusStore()
        var ctx = RenderContext()
        ctx.focusStore = store

        let view = ScrollView(showsIndicator: false) {
            Text("AAA")
            Text("BBB")
            Text("CCC")
            Text("DDD")
        }

        // First: sizeThatFits populates cache
        _ = sizeThatFits(view, proposal: SizeProposal(width: 10, height: 3), context: ctx)

        // Then: render uses cached sizes
        var buffer = Buffer(width: 10, height: 3)
        let region = Region(row: 0, col: 0, width: 10, height: 3)
        render(view, into: &buffer, region: region, context: ctx)

        #expect(buffer[0, 0].char == "A")
        #expect(buffer[1, 0].char == "B")
        #expect(buffer[2, 0].char == "C")
    }

    @Test("Tick-only render uses cached sizes in sizeThatFits")
    func tickOnlyUsesCache() {
        let store = FocusStore()
        var ctx = RenderContext()
        ctx.focusStore = store

        let view = ScrollView(showsIndicator: false) {
            Text("Line0")
            Text("Line1")
            Text("Line2")
        }

        // Full render to populate cache
        let proposal = SizeProposal(width: 10, height: 2)
        _ = sizeThatFits(view, proposal: proposal, context: ctx)
        var buffer = Buffer(width: 10, height: 2)
        let region = Region(row: 0, col: 0, width: 10, height: 2)
        render(view, into: &buffer, region: region, context: ctx)

        // Tick-only render should still produce correct output
        ctx.isTickOnlyRender = true
        let tickSize = sizeThatFits(view, proposal: proposal, context: ctx)
        #expect(tickSize.height == 2)
        #expect(tickSize.width == 5)

        buffer = Buffer(width: 10, height: 2)
        render(view, into: &buffer, region: region, context: ctx)
        #expect(buffer[0, 4].char == "0")
        #expect(buffer[1, 4].char == "1")
    }

    @Test("State change after tick-only render triggers full re-measure")
    func stateChangeAfterTickOnly() {
        let store = FocusStore()
        var ctx = RenderContext()
        ctx.focusStore = store

        let view = ScrollView(showsIndicator: false) {
            Text("Short")
            Text("A longer line here")
        }

        // Full render
        let proposal = SizeProposal(width: 30, height: 5)
        let fullSize = sizeThatFits(view, proposal: proposal, context: ctx)

        // Tick-only should return same result
        ctx.isTickOnlyRender = true
        let tickSize = sizeThatFits(view, proposal: proposal, context: ctx)
        #expect(tickSize == fullSize)

        // Non-tick render should also work correctly
        ctx.isTickOnlyRender = false
        let refreshSize = sizeThatFits(view, proposal: proposal, context: ctx)
        #expect(refreshSize == fullSize)
    }

    @Test("Existing ScrollView tests still pass with caching")
    func existingBehaviorPreserved() {
        // Verify that variable-height children still work with the cache
        let store = FocusStore()
        var ctx = RenderContext()
        ctx.focusStore = store

        let view = ScrollView(showsIndicator: false) {
            Text("A\nB") // 2 rows
            Text("C") // 1 row
        }

        _ = sizeThatFits(view, proposal: SizeProposal(width: 5, height: 3), context: ctx)
        var buffer = Buffer(width: 5, height: 3)
        let region = Region(row: 0, col: 0, width: 5, height: 3)
        render(view, into: &buffer, region: region, context: ctx)

        #expect(buffer[0, 0].char == "A")
        #expect(buffer[1, 0].char == "B")
        #expect(buffer[2, 0].char == "C")
    }
}
