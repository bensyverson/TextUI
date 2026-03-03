/// A property wrapper that provides an animation frame counter.
///
/// Any view — composite or primitive — can declare `@AnimationTick var tick`
/// to receive a counter that increments at approximately 30 fps. Reading the
/// tick value is a pure operation — it does not start the animation timer.
/// To actually drive the timer, the view (or an ancestor) must use the
/// ``View/animating(_:)`` modifier.
///
/// ```swift
/// struct SpinnerView: View {
///     @AnimationTick var tick
///
///     var body: some View {
///         let frames = ["⠋","⠙","⠹","⠸","⠼","⠴","⠦","⠧","⠇","⠏"]
///         Text(frames[tick % frames.count])
///             .animating()
///     }
/// }
/// ```
@MainActor
@propertyWrapper
public struct AnimationTick {
    /// Creates an animation tick property.
    public init() {}

    /// The current tick count from the animation tracker.
    ///
    /// This is a pure read — it does not start the animation timer.
    /// Use ``View/animating(_:)`` to signal that the animation timer
    /// should run. Returns `0` if no animation tracker is available
    /// (e.g., during testing without a run loop).
    public var wrappedValue: Int {
        RenderEnvironment.current.animationTracker?.tickCount ?? 0
    }
}
