/// A view that renders overlay content on top of its base content.
///
/// The overlay receives the same region as the base content.
/// Sizing is driven entirely by the base content.
struct OverlayView: PrimitiveView {
    let content: any View
    let overlay: any View

    func sizeThatFits(_ proposal: SizeProposal, context: RenderContext) -> Size2D {
        TextUI.sizeThatFits(content, proposal: proposal, context: context)
    }

    func render(into buffer: inout Buffer, region: Region, context: RenderContext) {
        TextUI.render(content, into: &buffer, region: region, context: context)
        TextUI.render(overlay, into: &buffer, region: region, context: context)
    }
}
