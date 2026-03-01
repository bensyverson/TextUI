/// A layout-transparent container for grouping views.
///
/// `Group` does not affect layout — its children are flattened
/// into the parent container. Use it to group views when you need
/// a single expression in a conditional or to apply modifiers to
/// multiple views at once.
///
/// ```swift
/// VStack {
///     Group {
///         Text("One")
///         Text("Two")
///     }
///     Text("Three")
/// }
/// ```
public struct Group: PrimitiveView, LayoutTransparent, Sendable {
    let children: [any View]

    /// Creates a group containing the given views.
    public init(@ViewBuilder content: () -> ViewGroup) {
        children = content().children
    }

    // MARK: - LayoutTransparent

    var layoutChildren: [any View] {
        children
    }

    // MARK: - PrimitiveView (bare usage outside a stack)

    public func sizeThatFits(_ proposal: SizeProposal) -> Size2D {
        guard let first = children.first else { return .zero }
        return TextUI.sizeThatFits(first, proposal: proposal)
    }

    public func render(into buffer: inout Buffer, region: Region) {
        guard let first = children.first else { return }
        TextUI.render(first, into: &buffer, region: region)
    }
}
