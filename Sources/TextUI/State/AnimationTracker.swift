/// Tracks whether any view requested animation during the current render frame.
///
/// Created by ``RunLoop`` and threaded through ``RenderContext``.
/// Views that use the ``View/animating(_:)`` modifier call
/// ``registerAnimatedRegion(_:)`` during rendering, signaling that the
/// run loop should start or continue the animation timer.
final class AnimationTracker: @unchecked Sendable {
    /// Whether any view requested animation this frame.
    private(set) var needsAnimation: Bool = false

    /// The current tick count, incremented by the run loop's animation timer.
    private(set) var tickCount: Int = 0

    /// The regions that are animating this frame, registered by ``AnimatingView``.
    private(set) var animatedRegions: [Region] = []

    /// Called by ``AnimatingView`` to register a region that is animating.
    ///
    /// This also sets ``needsAnimation`` so the run loop keeps the timer alive.
    func registerAnimatedRegion(_ region: Region) {
        animatedRegions.append(region)
        needsAnimation = true
    }

    /// Called by ``AnimationTick`` when a view reads its tick value.
    func requestAnimation() {
        needsAnimation = true
    }

    /// Resets the animation request flag and regions at the start of each render frame.
    func beginFrame() {
        needsAnimation = false
        animatedRegions = []
    }

    /// Advances the tick counter by one. Called by the run loop's timer.
    func tick() {
        tickCount += 1
    }
}
