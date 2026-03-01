/// A view that proposes an exact size to its child and reports
/// that exact size to its parent.
///
/// Created by the ``View/frame(width:height:alignment:)`` modifier.
/// `nil` dimensions pass through to the child unchanged.
struct FrameView: PrimitiveView, Sendable {
    let content: any View
    let width: Int?
    let height: Int?
    let alignment: Alignment

    func sizeThatFits(_ proposal: SizeProposal) -> Size2D {
        let childProposal = SizeProposal(
            width: width ?? proposal.width,
            height: height ?? proposal.height,
        )
        let childSize = TextUI.sizeThatFits(content, proposal: childProposal)
        return Size2D(
            width: width ?? childSize.width,
            height: height ?? childSize.height,
        )
    }

    func render(into buffer: inout Buffer, region: Region) {
        let childProposal = SizeProposal(
            width: width ?? region.width,
            height: height ?? region.height,
        )
        let childSize = TextUI.sizeThatFits(content, proposal: childProposal)
        let containerSize = Size2D(width: region.width, height: region.height)
        let offset = alignment.offset(child: childSize, in: containerSize)
        let childRegion = region.subregion(
            row: offset.row, col: offset.col,
            width: childSize.width, height: childSize.height,
        )
        TextUI.render(content, into: &buffer, region: childRegion)
    }
}
