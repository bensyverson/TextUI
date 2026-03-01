/// A view that handles its own sizing and rendering.
///
/// Primitive views are the leaf nodes of the view tree. They respond
/// to size proposals and render directly into a ``Buffer``. Most built-in
/// views (``Text``, ``Spacer``, ``Divider``, ``HStack``, ``VStack``)
/// are primitive views.
///
/// Composite views (those with a `body`) are recursively decomposed
/// until the render engine reaches a primitive view.
public protocol PrimitiveView: View where Body == Never {
    /// Returns the size this view needs given the parent's proposal.
    ///
    /// The child always chooses its own size — the proposal is advisory.
    /// See ``SizeProposal`` for the meaning of `nil`, `0`, `.max`,
    /// and concrete values.
    func sizeThatFits(_ proposal: SizeProposal, context: RenderContext) -> Size2D

    /// Renders this view into the buffer within the given region.
    func render(into buffer: inout Buffer, region: Region, context: RenderContext)
}

public extension PrimitiveView {
    /// Primitive views do not have a body — accessing it is a programming error.
    var body: Never {
        fatalError("Primitive views do not have a body")
    }

    /// Convenience overload that uses an empty render context.
    func sizeThatFits(_ proposal: SizeProposal) -> Size2D {
        sizeThatFits(proposal, context: RenderContext())
    }

    /// Convenience overload that uses an empty render context.
    func render(into buffer: inout Buffer, region: Region) {
        render(into: &buffer, region: region, context: RenderContext())
    }
}
