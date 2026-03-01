/// A primitive view that injects an environment object into the render context.
///
/// Created by the ``View/environmentObject(_:)`` modifier. When the render
/// engine encounters this view, it inserts the object into the context
/// before recursing into the child.
struct EnvironmentObjectView<T: AnyObject & Sendable>: PrimitiveView, Sendable {
    let content: any View
    let object: T

    func sizeThatFits(_ proposal: SizeProposal, context: RenderContext) -> Size2D {
        let childContext = context.inserting(object)
        return TextUI.sizeThatFits(content, proposal: proposal, context: childContext)
    }

    func render(into buffer: inout Buffer, region: Region, context: RenderContext) {
        let childContext = context.inserting(object)
        TextUI.render(content, into: &buffer, region: region, context: childContext)
    }
}
