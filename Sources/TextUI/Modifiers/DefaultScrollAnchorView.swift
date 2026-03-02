/// A modifier view that sets the default scroll anchor in the render context.
///
/// Applied via ``View/defaultScrollAnchor(_:)``. Descendant ``ScrollView``
/// instances read the anchor from ``RenderContext/defaultScrollAnchor``
/// to determine initial and auto-scroll behavior.
///
/// When set to ``VerticalAlignment/bottom``, a ScrollView will start at the
/// bottom and automatically follow new content — unless the user has scrolled
/// away from the bottom.
struct DefaultScrollAnchorView: PrimitiveView, Sendable {
    /// The wrapped content view.
    let content: any View

    /// The scroll anchor to apply.
    let anchor: VerticalAlignment

    func sizeThatFits(_ proposal: SizeProposal, context: RenderContext) -> Size2D {
        var ctx = context
        ctx.defaultScrollAnchor = anchor
        return TextUI.sizeThatFits(content, proposal: proposal, context: ctx)
    }

    func render(into buffer: inout Buffer, region: Region, context: RenderContext) {
        var ctx = context
        ctx.defaultScrollAnchor = anchor
        TextUI.render(content, into: &buffer, region: region, context: ctx)
    }
}
