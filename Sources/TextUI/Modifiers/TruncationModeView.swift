/// A modifier view that sets the truncation mode in the render context.
///
/// Applied via ``View/truncationMode(_:)``. Descendant ``Text`` views read
/// the mode from ``RenderContext/truncationMode`` to determine where the
/// ellipsis appears when content is truncated.
struct TruncationModeView: PrimitiveView {
    /// The wrapped content view.
    let content: any View

    /// The truncation mode to apply.
    let mode: Text.TruncationMode

    func sizeThatFits(_ proposal: SizeProposal, context: RenderContext) -> Size2D {
        var ctx = context
        ctx.truncationMode = mode
        return TextUI.sizeThatFits(content, proposal: proposal, context: ctx)
    }

    func render(into buffer: inout Buffer, region: Region, context: RenderContext) {
        var ctx = context
        ctx.truncationMode = mode
        TextUI.render(content, into: &buffer, region: region, context: ctx)
    }
}
