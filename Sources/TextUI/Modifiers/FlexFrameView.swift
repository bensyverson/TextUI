/// A view that clamps its child's size within min/max bounds.
///
/// Created by the ``View/frame(minWidth:maxWidth:minHeight:maxHeight:alignment:)``
/// modifier. Follows SwiftUI's asymmetric clamping rules:
/// - Both min and max set: clamp proposal, propose to child, clamp response
/// - Only min set: propose as-is, clamp response to min
/// - Only max set: cap proposal at max, response as-is
struct FlexFrameView: PrimitiveView {
    let content: any View
    let minWidth: Int?
    let maxWidth: Int?
    let minHeight: Int?
    let maxHeight: Int?
    let alignment: Alignment

    func sizeThatFits(_ proposal: SizeProposal, context: RenderContext) -> Size2D {
        let adjustedW = clampProposal(proposal.width, min: minWidth, max: maxWidth)
        let adjustedH = clampProposal(proposal.height, min: minHeight, max: maxHeight)
        let childProposal = SizeProposal(width: adjustedW, height: adjustedH)
        let childSize = TextUI.sizeThatFits(content, proposal: childProposal, context: context)
        return Size2D(
            width: clampResponse(
                childSize.width,
                proposed: proposal.width,
                min: minWidth,
                max: maxWidth,
            ),
            height: clampResponse(
                childSize.height,
                proposed: proposal.height,
                min: minHeight,
                max: maxHeight,
            ),
        )
    }

    func render(into buffer: inout Buffer, region: Region, context: RenderContext) {
        let childProposal = SizeProposal(width: region.width, height: region.height)
        let childSize = TextUI.sizeThatFits(content, proposal: childProposal, context: context)
        let containerSize = Size2D(width: region.width, height: region.height)
        let offset = alignment.offset(child: childSize, in: containerSize)
        let childRegion = region.subregion(
            row: offset.row, col: offset.col,
            width: childSize.width, height: childSize.height,
        )
        TextUI.render(content, into: &buffer, region: childRegion, context: context)
    }

    // MARK: - Private Clamping Helpers

    private func clampProposal(_ proposal: Int?, min: Int?, max: Int?) -> Int? {
        guard let p = proposal else { return nil }
        switch (min, max) {
        case let (lo?, hi?): return Swift.min(Swift.max(p, lo), hi)
        case (nil, let hi?): return Swift.min(p, hi)
        case (_, nil): return p
        }
    }

    private func clampResponse(
        _ response: Int,
        proposed: Int?,
        min: Int?,
        max: Int?,
    ) -> Int {
        switch (min, max) {
        case let (lo?, hi?):
            return Swift.min(Swift.max(response, lo), hi)
        case let (lo?, nil):
            return Swift.max(response, lo)
        case let (nil, hi?):
            // Only max: frame takes min(proposed, max) as its width
            if let p = proposed {
                return Swift.min(p, hi)
            }
            return response
        case (nil, nil):
            return response
        }
    }
}
