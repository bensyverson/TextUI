/// A modifier view that sets the multiline text alignment in the render context.
///
/// Applied via ``View/multilineTextAlignment(_:)``. Descendant ``Text``
/// views read the alignment from ``RenderContext/multilineTextAlignment``
/// to position wrapped lines within the available width.
struct MultilineTextAlignmentView: PrimitiveView, Sendable {
    /// The wrapped content view.
    let content: any View

    /// The horizontal alignment to apply.
    let alignment: HorizontalAlignment

    func sizeThatFits(_ proposal: SizeProposal, context: RenderContext) -> Size2D {
        var ctx = context
        ctx.multilineTextAlignment = alignment
        return TextUI.sizeThatFits(content, proposal: proposal, context: ctx)
    }

    func render(into buffer: inout Buffer, region: Region, context: RenderContext) {
        var ctx = context
        ctx.multilineTextAlignment = alignment
        TextUI.render(content, into: &buffer, region: region, context: ctx)
    }
}
