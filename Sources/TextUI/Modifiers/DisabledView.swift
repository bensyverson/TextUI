/// A modifier view that disables interactive controls in its subtree.
///
/// Applied via ``View/disabled(_:)``. When `isDisabled` is `true`, descendant
/// controls (``Button``, ``TextField``, ``Toggle``, ``Picker``) skip focus
/// registration and become non-interactive. Disabled content is rendered
/// with dim styling to visually indicate the inactive state.
struct DisabledView: PrimitiveView {
    /// The wrapped content view.
    let content: any View

    /// Whether the content should be disabled.
    let isDisabled: Bool

    func sizeThatFits(_ proposal: SizeProposal, context: RenderContext) -> Size2D {
        var ctx = context
        if isDisabled {
            ctx.isDisabled = true
        }
        return TextUI.sizeThatFits(content, proposal: proposal, context: ctx)
    }

    func render(into buffer: inout Buffer, region: Region, context: RenderContext) {
        var ctx = context
        if isDisabled {
            ctx.isDisabled = true
        }
        TextUI.render(content, into: &buffer, region: region, context: ctx)

        // Apply dim styling to all cells when disabled
        if isDisabled {
            let dimStyle = Style(dim: true)
            for r in region.row ..< min(region.row + region.height, buffer.height) {
                for c in region.col ..< min(region.col + region.width, buffer.width) {
                    guard r >= 0, c >= 0 else { continue }
                    guard !buffer[r, c].isContinuation else { continue }
                    buffer[r, c].style = buffer[r, c].style.merging(dimStyle)
                }
            }
        }
    }
}
