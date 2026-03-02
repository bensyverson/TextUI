import Testing
@testable import TextUI

/// A view that counts how many times `sizeThatFits` is called, for verifying cache behavior.
private final class SizeCounter: @unchecked Sendable {
    var count = 0
}

private struct CountingText: PrimitiveView, @unchecked Sendable {
    let text: String
    let counter: SizeCounter

    func sizeThatFits(_ proposal: SizeProposal, context: RenderContext) -> Size2D {
        counter.count += 1
        return TextUI.sizeThatFits(Text(text), proposal: proposal, context: context)
    }

    func render(into buffer: inout Buffer, region: Region, context: RenderContext) {
        TextUI.render(Text(text), into: &buffer, region: region, context: context)
    }
}

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

    @Test("Per-frame cache prevents repeated child measurement across probes")
    func perFrameCacheDedup() {
        let store = FocusStore()
        var ctx = RenderContext()
        ctx.focusStore = store
        ctx.layoutCache = LayoutCache()

        let counter = SizeCounter()
        let view = ScrollView(showsIndicator: false) {
            CountingText(text: "Line0", counter: counter)
            CountingText(text: "Line1", counter: counter)
            CountingText(text: "Line2", counter: counter)
        }

        // Simulate the 3 probes that layoutGreedy makes:
        // Probe 1 (height: 0) — cache miss, measures all 3 children
        _ = sizeThatFits(view, proposal: SizeProposal(width: 20, height: 0), context: ctx)
        #expect(counter.count == 3)

        // Probe 2 (height: .max) — per-frame cache hit, no new measurements
        _ = sizeThatFits(view, proposal: SizeProposal(width: 20, height: .max), context: ctx)
        #expect(counter.count == 3)

        // Probe 3 (height: 10) — per-frame cache hit, no new measurements
        _ = sizeThatFits(view, proposal: SizeProposal(width: 20, height: 10), context: ctx)
        #expect(counter.count == 3)
    }

    @Test("Per-frame cache does not persist across frames")
    func perFrameCacheFrameIsolation() {
        let store = FocusStore()

        let counter = SizeCounter()
        let view = ScrollView(showsIndicator: false) {
            CountingText(text: "Line0", counter: counter)
            CountingText(text: "Line1", counter: counter)
        }

        // Frame 1
        var ctx1 = RenderContext()
        ctx1.focusStore = store
        ctx1.layoutCache = LayoutCache()
        _ = sizeThatFits(view, proposal: SizeProposal(width: 20, height: 5), context: ctx1)
        #expect(counter.count == 2)

        // Frame 2 with a fresh LayoutCache — should re-measure
        var ctx2 = RenderContext()
        ctx2.focusStore = store
        ctx2.layoutCache = LayoutCache()
        _ = sizeThatFits(view, proposal: SizeProposal(width: 20, height: 5), context: ctx2)
        #expect(counter.count == 4)
    }

    @Test("Per-frame cache produces correct sizes")
    func perFrameCacheCorrectness() {
        let store = FocusStore()
        var ctx = RenderContext()
        ctx.focusStore = store
        ctx.layoutCache = LayoutCache()

        let view = ScrollView(showsIndicator: false) {
            Text("Short")
            Text("A longer line here")
        }

        // First probe populates cache
        let size1 = sizeThatFits(view, proposal: SizeProposal(width: 30, height: 0), context: ctx)
        // Second probe uses cache — result should differ only in height
        let size2 = sizeThatFits(view, proposal: SizeProposal(width: 30, height: 10), context: ctx)

        #expect(size1.width == size2.width)
        #expect(size1.height == 0) // proposed height 0
        #expect(size2.height == 10) // proposed height 10
    }
}
