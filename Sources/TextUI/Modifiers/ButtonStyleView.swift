/// A modifier view that sets the button style in the render context.
///
/// Applied via ``View/buttonStyle(_:)``. Descendant ``Button``
/// instances read the style from ``RenderContext/buttonStyle``.
struct ButtonStyleView: PrimitiveView, Sendable {
    /// The wrapped content view.
    let content: any View

    /// The style to apply.
    let style: ButtonStyle

    func sizeThatFits(_ proposal: SizeProposal, context: RenderContext) -> Size2D {
        var ctx = context
        ctx.buttonStyle = style
        return TextUI.sizeThatFits(content, proposal: proposal, context: ctx)
    }

    func render(into buffer: inout Buffer, region: Region, context: RenderContext) {
        var ctx = context
        ctx.buttonStyle = style
        TextUI.render(content, into: &buffer, region: region, context: ctx)
    }
}
