import Testing
@testable import TextUI

@Suite("AnimationTracker")
struct AnimationTrackerTests {
    @Test("beginFrame resets needsAnimation")
    func beginFrameResets() {
        let tracker = AnimationTracker()
        tracker.requestAnimation()
        #expect(tracker.needsAnimation)
        tracker.beginFrame()
        #expect(!tracker.needsAnimation)
    }

    @Test("requestAnimation sets flag")
    func requestSetsFlag() {
        let tracker = AnimationTracker()
        #expect(!tracker.needsAnimation)
        tracker.requestAnimation()
        #expect(tracker.needsAnimation)
    }

    @Test("tick increments count")
    func tickIncrements() {
        let tracker = AnimationTracker()
        #expect(tracker.tickCount == 0)
        tracker.tick()
        #expect(tracker.tickCount == 1)
        tracker.tick()
        #expect(tracker.tickCount == 2)
    }
}

@Suite("AnimationTick")
struct AnimationTickTests {
    @Test("Reads tickCount from context")
    func readsTickCount() {
        let tracker = AnimationTracker()
        tracker.tick()
        tracker.tick()
        tracker.tick()

        var ctx = RenderContext()
        ctx.animationTracker = tracker

        RenderEnvironment.$current.withValue(ctx) {
            let tick = AnimationTick()
            #expect(tick.wrappedValue == 3)
        }
    }

    @Test("Calls requestAnimation on access")
    func requestsAnimation() {
        let tracker = AnimationTracker()
        var ctx = RenderContext()
        ctx.animationTracker = tracker

        #expect(!tracker.needsAnimation)

        RenderEnvironment.$current.withValue(ctx) {
            let tick = AnimationTick()
            _ = tick.wrappedValue
        }

        #expect(tracker.needsAnimation)
    }

    @Test("Returns 0 without tracker")
    func returnsZeroWithoutTracker() {
        let tick = AnimationTick()
        #expect(tick.wrappedValue == 0)
    }
}
