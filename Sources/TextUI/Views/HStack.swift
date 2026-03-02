/// A view that arranges its children in a horizontal line.
///
/// ```swift
/// HStack {
///     Text("left")
///     Spacer()
///     Text("right")
/// }
/// ```
///
/// The stack uses the two-phase allocation algorithm described in
/// `StackLayout`. Children are sorted by `.layoutPriority()` then
/// flexibility; each child is guaranteed its minimum width before
/// surplus space is distributed equally among remaining children.
public struct HStack: PrimitiveView, Sendable {
    /// Vertical alignment for children within the stack.
    public let alignment: VerticalAlignment

    /// The number of columns between adjacent children.
    public let spacing: Int

    /// The flattened, axis-prepared children.
    let children: [any View]

    /// Auto-generated key for stable identity and layout caching.
    let autoKey: String

    /// Creates a horizontal stack.
    ///
    /// - Parameters:
    ///   - alignment: The vertical alignment of children. Defaults to `.top`.
    ///   - spacing: The number of columns between children. Defaults to `1`.
    ///   - fileID: Auto-captured file ID for stable identity.
    ///   - line: Auto-captured line number for stable identity.
    ///   - content: A ``ViewBuilder`` closure producing the stack's children.
    public init(
        alignment: VerticalAlignment = .top,
        spacing: Int = 1,
        fileID: String = #fileID,
        line: Int = #line,
        @ViewBuilder content: () -> ViewGroup,
    ) {
        self.alignment = alignment
        self.spacing = spacing
        autoKey = "\(fileID):\(line)"
        let flat = StackLayout.flattenChildren(content().children)
        children = StackLayout.prepareChildren(flat, axis: .horizontal)
    }

    public func sizeThatFits(_ proposal: SizeProposal, context: RenderContext) -> Size2D {
        let result = StackLayout.layout(
            children: children,
            axis: .horizontal,
            spacing: spacing,
            proposal: proposal,
            context: context,
        )
        return result.totalSize
    }

    public func render(into buffer: inout Buffer, region: Region, context: RenderContext) {
        guard !region.isEmpty else { return }

        let result = StackLayout.layout(
            children: children,
            axis: .horizontal,
            spacing: spacing,
            proposal: SizeProposal(width: region.width, height: region.height),
            context: context,
        )

        for childLayout in result.children {
            let crossOffset: Int = switch alignment {
            case .top:
                0
            case .center:
                max(0, (region.height - childLayout.size.height) / 2)
            case .bottom:
                max(0, region.height - childLayout.size.height)
            }

            let childRegion = region.subregion(
                row: crossOffset,
                col: childLayout.primaryOffset,
                width: childLayout.size.width,
                height: childLayout.size.height,
            )
            TextUI.render(childLayout.view, into: &buffer, region: childRegion, context: context)
        }
    }
}
