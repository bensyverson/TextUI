/// A modifier view that sets the line limit in the render context.
///
/// Applied via ``View/lineLimit(_:)``. Descendant ``Text`` views read
/// the limit from ``RenderContext/lineLimit`` to cap visible lines.
struct LineLimitView: PrimitiveView, Sendable {
    /// The wrapped content view.
    let content: any View

    /// The maximum number of lines, or `nil` for unlimited.
    let limit: Int?

    func sizeThatFits(_ proposal: SizeProposal, context: RenderContext) -> Size2D {
        var ctx = context
        ctx.lineLimit = limit
        return TextUI.sizeThatFits(content, proposal: proposal, context: ctx)
    }

    func render(into buffer: inout Buffer, region: Region, context: RenderContext) {
        var ctx = context
        ctx.lineLimit = limit
        TextUI.render(content, into: &buffer, region: region, context: ctx)
    }
}
