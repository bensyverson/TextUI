/// Tracks whether any view requested animation during the current render frame.
///
/// Created by ``RunLoop`` and threaded through ``RenderContext``.
/// Views that use ``AnimationTick`` call ``requestAnimation()`` when
/// their tick value is read, signaling that the run loop should start
/// or continue the animation timer.
final class AnimationTracker: @unchecked Sendable {
    /// Whether any view requested animation this frame.
    private(set) var needsAnimation: Bool = false

    /// The current tick count, incremented by the run loop's animation timer.
    private(set) var tickCount: Int = 0

    /// Called by ``AnimationTick`` when a view reads its tick value.
    func requestAnimation() {
        needsAnimation = true
    }

    /// Resets the animation request flag at the start of each render frame.
    func beginFrame() {
        needsAnimation = false
    }

    /// Advances the tick counter by one. Called by the run loop's timer.
    func tick() {
        tickCount += 1
    }
}
