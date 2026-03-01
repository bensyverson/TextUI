/// A view that displays nothing and occupies no space.
///
/// `EmptyView` is used as a placeholder when no content is needed,
/// such as when a conditional view evaluates to `nil`.
public struct EmptyView: PrimitiveView, Sendable {
    /// Creates an empty view.
    public init() {}

    public func sizeThatFits(_: SizeProposal) -> Size2D {
        .zero
    }

    public func render(into _: inout Buffer, region _: Region) {
        // Nothing to render
    }
}
