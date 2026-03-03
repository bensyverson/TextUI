/// A view that adds padding around its content.
///
/// Created by the ``View/padding(_:)`` and related modifier methods.
/// Padding reduces the size proposal passed to the child and adds
/// space around the child's rendered output.
struct PaddedView: PrimitiveView {
    let content: any View
    let top: Int
    let leading: Int
    let bottom: Int
    let trailing: Int

    func sizeThatFits(_ proposal: SizeProposal, context: RenderContext) -> Size2D {
        let inner = proposal.inset(
            horizontal: leading + trailing,
            vertical: top + bottom,
        )
        let childSize = TextUI.sizeThatFits(content, proposal: inner, context: context)
        return Size2D(
            width: childSize.width + leading + trailing,
            height: childSize.height + top + bottom,
        )
    }

    func render(into buffer: inout Buffer, region: Region, context: RenderContext) {
        let innerRegion = region.inset(
            top: top, left: leading, bottom: bottom, right: trailing,
        )
        guard !innerRegion.isEmpty else { return }
        TextUI.render(content, into: &buffer, region: innerRegion, context: context)
    }
}
