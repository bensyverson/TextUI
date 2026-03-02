/// A modifier view that marks its content as animating.
///
/// Applied via ``View/animating(_:)``. When `isActive` is `true`, the view
/// registers its render region with the ``AnimationTracker``, signaling the
/// run loop to keep the animation timer running. The content's size is
/// unchanged — this modifier only affects animation lifecycle.
///
/// Views using ``AnimationTick`` should apply `.animating()` to ensure the
/// timer runs while they are visible.
struct AnimatingView: PrimitiveView, Sendable {
    /// The wrapped content view.
    let content: any View

    /// Whether animation is active for this content.
    let isActive: Bool

    func sizeThatFits(_ proposal: SizeProposal, context: RenderContext) -> Size2D {
        TextUI.sizeThatFits(content, proposal: proposal, context: context)
    }

    func render(into buffer: inout Buffer, region: Region, context: RenderContext) {
        if isActive {
            context.animationTracker?.registerAnimatedRegion(region)
        }
        TextUI.render(content, into: &buffer, region: region, context: context)
    }
}
