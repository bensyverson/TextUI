/// A modifier view that sets the tab content border style in the render context.
///
/// Applied via ``View/tabBorderStyle(_:)``. When set, ``TabView``
/// draws a box-drawing border around the content area, merging it
/// with the divider row.
///
/// This modifier is ignored when ``TabDividerStyle/none`` is active —
/// the content border only makes sense when there is a divider to
/// merge into. Use ``View/border(_:)`` for a plain border around
/// the entire TabView.
struct TabBorderStyleView: PrimitiveView {
    /// The wrapped content view.
    let content: any View

    /// The border style to apply.
    let borderStyle: BorderedView.BorderStyle

    func sizeThatFits(_ proposal: SizeProposal, context: RenderContext) -> Size2D {
        var ctx = context
        ctx.tabBorderStyle = borderStyle
        return TextUI.sizeThatFits(content, proposal: proposal, context: ctx)
    }

    func render(into buffer: inout Buffer, region: Region, context: RenderContext) {
        var ctx = context
        ctx.tabBorderStyle = borderStyle
        TextUI.render(content, into: &buffer, region: region, context: ctx)
    }
}
