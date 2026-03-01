/// A view that arranges its children in a vertical line.
///
/// ```swift
/// VStack {
///     Text("Title")
///     Divider.horizontal
///     Text("Body")
/// }
/// ```
///
/// The stack uses the two-phase allocation algorithm described in
/// `StackLayout`. Children are sorted by `.layoutPriority()` then
/// flexibility; each child is guaranteed its minimum height before
/// surplus space is distributed equally among remaining children.
public struct VStack: PrimitiveView, Sendable {
    /// Horizontal alignment for children within the stack.
    public let alignment: HorizontalAlignment

    /// The number of rows between adjacent children.
    public let spacing: Int

    /// The flattened, axis-prepared children.
    let children: [any View]

    /// Creates a vertical stack.
    ///
    /// - Parameters:
    ///   - alignment: The horizontal alignment of children. Defaults to `.leading`.
    ///   - spacing: The number of rows between children. Defaults to `0`.
    ///   - content: A ``ViewBuilder`` closure producing the stack's children.
    public init(
        alignment: HorizontalAlignment = .leading,
        spacing: Int = 0,
        @ViewBuilder content: () -> ViewGroup,
    ) {
        self.alignment = alignment
        self.spacing = spacing
        let flat = StackLayout.flattenChildren(content().children)
        children = StackLayout.prepareChildren(flat, axis: .vertical)
    }

    public func sizeThatFits(_ proposal: SizeProposal, context: RenderContext) -> Size2D {
        let result = StackLayout.layout(
            children: children,
            axis: .vertical,
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
            axis: .vertical,
            spacing: spacing,
            proposal: SizeProposal(width: region.width, height: region.height),
            context: context,
        )

        for childLayout in result.children {
            let crossOffset: Int = switch alignment {
            case .leading:
                0
            case .center:
                max(0, (region.width - childLayout.size.width) / 2)
            case .trailing:
                max(0, region.width - childLayout.size.width)
            }

            let childRegion = region.subregion(
                row: childLayout.primaryOffset,
                col: crossOffset,
                width: childLayout.size.width,
                height: childLayout.size.height,
            )
            TextUI.render(childLayout.view, into: &buffer, region: childRegion, context: context)
        }
    }
}
