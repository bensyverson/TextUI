/// A view that renders overlay content on top of its base content.
///
/// The overlay receives the same region as the base content.
/// Sizing is driven entirely by the base content.
struct OverlayView: PrimitiveView, Sendable {
    let content: any View
    let overlay: any View

    func sizeThatFits(_ proposal: SizeProposal) -> Size2D {
        TextUI.sizeThatFits(content, proposal: proposal)
    }

    func render(into buffer: inout Buffer, region: Region) {
        TextUI.render(content, into: &buffer, region: region)
        TextUI.render(overlay, into: &buffer, region: region)
    }
}
