import Testing
@testable import TextUI

@MainActor
@Suite("AnimationTracker")
struct AnimationTrackerTests {
    @Test("beginFrame resets needsAnimation and animatedRegions")
    func beginFrameResets() {
        let tracker = AnimationTracker()
        tracker.requestAnimation()
        let region = Region(row: 0, col: 0, width: 10, height: 5)
        tracker.registerAnimatedRegion(region)
        #expect(tracker.needsAnimation)
        #expect(tracker.animatedRegions.count == 1)
        tracker.beginFrame()
        #expect(!tracker.needsAnimation)
        #expect(tracker.animatedRegions.isEmpty)
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

    @Test("registerAnimatedRegion appends region and sets needsAnimation")
    func registerAnimatedRegion() {
        let tracker = AnimationTracker()
        #expect(!tracker.needsAnimation)
        #expect(tracker.animatedRegions.isEmpty)

        let region = Region(row: 1, col: 2, width: 10, height: 5)
        tracker.registerAnimatedRegion(region)

        #expect(tracker.needsAnimation)
        #expect(tracker.animatedRegions.count == 1)
        #expect(tracker.animatedRegions[0] == region)
    }
}

@MainActor
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

    @Test("Reading wrappedValue does NOT set needsAnimation")
    func doesNotRequestAnimation() {
        let tracker = AnimationTracker()
        var ctx = RenderContext()
        ctx.animationTracker = tracker

        #expect(!tracker.needsAnimation)

        RenderEnvironment.$current.withValue(ctx) {
            let tick = AnimationTick()
            _ = tick.wrappedValue
        }

        #expect(!tracker.needsAnimation)
    }

    @Test("Returns 0 without tracker")
    func returnsZeroWithoutTracker() {
        let tick = AnimationTick()
        #expect(tick.wrappedValue == 0)
    }
}
