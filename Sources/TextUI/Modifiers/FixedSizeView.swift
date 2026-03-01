/// A view that prevents its child from being compressed.
///
/// `FixedSizeView` replaces the parent's proposal with `nil` on the
/// specified axes, causing the child to report its ideal size instead
/// of truncating to fit the proposal.
struct FixedSizeView: PrimitiveView, Sendable {
    let content: any View
    let horizontal: Bool
    let vertical: Bool

    func sizeThatFits(_ proposal: SizeProposal) -> Size2D {
        let adjusted = SizeProposal(
            width: horizontal ? nil : proposal.width,
            height: vertical ? nil : proposal.height,
        )
        return TextUI.sizeThatFits(content, proposal: adjusted)
    }

    func render(into buffer: inout Buffer, region: Region) {
        TextUI.render(content, into: &buffer, region: region)
    }
}
