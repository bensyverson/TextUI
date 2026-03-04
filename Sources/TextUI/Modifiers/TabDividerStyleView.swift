/// A modifier view that sets the tab divider style in the render context.
///
/// Applied via ``View/tabDividerStyle(_:)``. Descendant ``TabView``
/// instances read the style from ``RenderContext/tabDividerStyle``.
struct TabDividerStyleView: PrimitiveView {
    /// The wrapped content view.
    let content: any View

    /// The divider style to apply.
    let style: TabDividerStyle

    func sizeThatFits(_ proposal: SizeProposal, context: RenderContext) -> Size2D {
        var ctx = context
        ctx.tabDividerStyle = style
        return TextUI.sizeThatFits(content, proposal: proposal, context: ctx)
    }

    func render(into buffer: inout Buffer, region: Region, context: RenderContext) {
        var ctx = context
        ctx.tabDividerStyle = style
        TextUI.render(content, into: &buffer, region: region, context: ctx)
    }
}
