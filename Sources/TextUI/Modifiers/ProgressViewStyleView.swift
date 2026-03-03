/// A modifier view that sets the progress view style in the render context.
///
/// Applied via ``View/progressViewStyle(_:)``. Descendant ``ProgressView``
/// instances read the style from ``RenderContext/progressViewStyle``.
struct ProgressViewStyleView: PrimitiveView {
    /// The wrapped content view.
    let content: any View

    /// The style to apply.
    let style: ProgressViewStyle

    func sizeThatFits(_ proposal: SizeProposal, context: RenderContext) -> Size2D {
        var ctx = context
        ctx.progressViewStyle = style
        return TextUI.sizeThatFits(content, proposal: proposal, context: ctx)
    }

    func render(into buffer: inout Buffer, region: Region, context: RenderContext) {
        var ctx = context
        ctx.progressViewStyle = style
        TextUI.render(content, into: &buffer, region: region, context: ctx)
    }
}
