/// A view that overlays its children back-to-front.
///
/// All children receive the same size proposal. The ZStack's size
/// is the maximum width and height of its children. Children are
/// positioned according to the stack's alignment.
///
/// ```swift
/// ZStack {
///     Color(.blue)
///     Text("Overlay")
/// }
/// ```
public struct ZStack: PrimitiveView, Sendable {
    /// The alignment used to position children within the stack.
    public let alignment: Alignment

    /// The flattened children to overlay.
    let children: [any View]

    /// Creates a ZStack with the given alignment and content.
    public init(
        alignment: Alignment = .center,
        @ViewBuilder content: () -> ViewGroup,
    ) {
        self.alignment = alignment
        children = StackLayout.flattenChildren(content().children)
    }

    public func sizeThatFits(_ proposal: SizeProposal, context: RenderContext) -> Size2D {
        var maxW = 0
        var maxH = 0
        for child in children {
            let size = TextUI.sizeThatFits(child, proposal: proposal, context: context)
            maxW = max(maxW, size.width)
            maxH = max(maxH, size.height)
        }
        return Size2D(width: maxW, height: maxH)
    }

    public func render(into buffer: inout Buffer, region: Region, context: RenderContext) {
        guard !region.isEmpty else { return }
        let stackSize = Size2D(width: region.width, height: region.height)
        for child in children {
            let childSize = TextUI.sizeThatFits(
                child,
                proposal: SizeProposal(width: region.width, height: region.height),
                context: context,
            )
            let offset = alignment.offset(child: childSize, in: stackSize)
            let childRegion = region.subregion(
                row: offset.row, col: offset.col,
                width: childSize.width, height: childSize.height,
            )
            TextUI.render(child, into: &buffer, region: childRegion, context: context)
        }
    }
}
