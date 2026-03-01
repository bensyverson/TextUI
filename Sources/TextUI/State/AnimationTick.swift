/// A property wrapper that provides an animation frame counter.
///
/// Any view — composite or primitive — can declare `@AnimationTick var tick`
/// to receive a counter that increments at approximately 30 fps. The animation
/// timer starts automatically when any view reads this value during rendering
/// and stops when no views read it.
///
/// ```swift
/// struct SpinnerView: View {
///     @AnimationTick var tick
///
///     var body: some View {
///         let frames = ["⠋","⠙","⠹","⠸","⠼","⠴","⠦","⠧","⠇","⠏"]
///         Text(frames[tick % frames.count])
///     }
/// }
/// ```
@propertyWrapper
public struct AnimationTick: Sendable {
    /// Creates an animation tick property.
    public init() {}

    /// The current tick count from the animation tracker.
    ///
    /// Accessing this value signals the run loop to keep the animation
    /// timer running. Returns `0` if no animation tracker is available
    /// (e.g., during testing without a run loop).
    public var wrappedValue: Int {
        let ctx = RenderEnvironment.current
        ctx.animationTracker?.requestAnimation()
        return ctx.animationTracker?.tickCount ?? 0
    }
}
