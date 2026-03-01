/// A structural view that holds multiple child views.
///
/// `ViewGroup` is the return type of ``ViewBuilder/buildBlock(_:)``
/// and similar result-builder methods. It is layout-transparent:
/// stacks and the render engine flatten its children rather than
/// treating it as a single view.
///
/// You never create a `ViewGroup` directly — it is produced
/// automatically by the `@ViewBuilder` result builder.
public struct ViewGroup: PrimitiveView, Sendable {
    /// The child views contained in this group.
    public let children: [any View]

    /// Creates a view group with the given children.
    public init(_ children: [any View]) {
        self.children = children
    }

    public func sizeThatFits(_ proposal: SizeProposal) -> Size2D {
        // Bare ViewGroup outside a stack: size to first child
        guard let first = children.first else { return .zero }
        return TextUI.sizeThatFits(first, proposal: proposal)
    }

    public func render(into buffer: inout Buffer, region: Region) {
        // Bare ViewGroup outside a stack: render first child only
        guard let first = children.first else { return }
        TextUI.render(first, into: &buffer, region: region)
    }
}
