/// A view that displays nothing and occupies no space.
///
/// `EmptyView` is used as a placeholder when no content is needed,
/// such as when a conditional view evaluates to `nil`.
public struct EmptyView: PrimitiveView {
    /// Creates an empty view.
    public init() {}

    public func sizeThatFits(_: SizeProposal, context _: RenderContext) -> Size2D {
        .zero
    }

    public func render(into _: inout Buffer, region _: Region, context _: RenderContext) {
        // Nothing to render
    }
}
