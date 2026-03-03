import Testing
@testable import TextUI

@MainActor
@Suite("AnimatingView")
struct AnimatingViewTests {
    @Test(".animating(true) sets needsAnimation after render")
    func activeAnimationSetsFlag() {
        let tracker = AnimationTracker()
        var ctx = RenderContext()
        ctx.animationTracker = tracker

        let view = Text("Hi").animating(true)

        var buffer = Buffer(width: 10, height: 1)
        let region = Region(row: 0, col: 0, width: 10, height: 1)
        render(view, into: &buffer, region: region, context: ctx)

        #expect(tracker.needsAnimation)
    }

    @Test(".animating(false) does not set needsAnimation")
    func inactiveAnimationDoesNotSetFlag() {
        let tracker = AnimationTracker()
        var ctx = RenderContext()
        ctx.animationTracker = tracker

        let view = Text("Hi").animating(false)

        var buffer = Buffer(width: 10, height: 1)
        let region = Region(row: 0, col: 0, width: 10, height: 1)
        render(view, into: &buffer, region: region, context: ctx)

        #expect(!tracker.needsAnimation)
    }

    @Test(".animating() registers region with tracker")
    func registersRegion() {
        let tracker = AnimationTracker()
        var ctx = RenderContext()
        ctx.animationTracker = tracker

        let view = Text("Hi").animating()

        let region = Region(row: 2, col: 3, width: 10, height: 1)
        var buffer = Buffer(width: 20, height: 5)
        render(view, into: &buffer, region: region, context: ctx)

        #expect(tracker.animatedRegions.count == 1)
        #expect(tracker.animatedRegions[0] == region)
    }

    @Test("Tick count is still readable as pure read with .animating()")
    func tickCountReadable() {
        let tracker = AnimationTracker()
        tracker.tick()
        tracker.tick()

        var ctx = RenderContext()
        ctx.animationTracker = tracker

        RenderEnvironment.$current.withValue(ctx) {
            let tick = AnimationTick()
            #expect(tick.wrappedValue == 2)
        }

        // Reading alone should NOT set needsAnimation
        #expect(!tracker.needsAnimation)
    }

    @Test(".animating() does not change content size")
    func sizeUnchanged() {
        let plain = Text("Hello")
        let animated = Text("Hello").animating()

        let proposal = SizeProposal(width: 20, height: 5)
        let plainSize = sizeThatFits(plain, proposal: proposal)
        let animatedSize = sizeThatFits(animated, proposal: proposal)

        #expect(plainSize == animatedSize)
    }

    @Test(".animating() renders content unchanged")
    func contentUnchanged() {
        let tracker = AnimationTracker()
        var ctx = RenderContext()
        ctx.animationTracker = tracker

        var plainBuffer = Buffer(width: 10, height: 1)
        var animatedBuffer = Buffer(width: 10, height: 1)
        let region = Region(row: 0, col: 0, width: 10, height: 1)

        render(Text("Hello"), into: &plainBuffer, region: region, context: ctx)
        render(Text("Hello").animating(), into: &animatedBuffer, region: region, context: ctx)

        for c in 0 ..< 10 {
            #expect(plainBuffer[0, c].char == animatedBuffer[0, c].char)
        }
    }
}
