/// Returns the size a view needs given the parent's proposal.
///
/// Dispatches to the appropriate sizing logic:
/// 1. **Primitive views** — calls ``PrimitiveView/sizeThatFits(_:context:)`` directly
/// 2. **View groups** — sizes to the first child (bare group outside a stack)
/// 3. **Composite views** — recurses into the view's `body`
@MainActor
public func sizeThatFits(
    _ view: any View,
    proposal: SizeProposal,
    context: RenderContext = RenderContext(),
) -> Size2D {
    if let primitive = view as? any PrimitiveView {
        return primitive.sizeThatFits(proposal, context: context)
    }
    return sizeThatFitsBody(view, proposal: proposal, context: context)
}

/// Renders a view into a buffer within the given region.
///
/// Dispatches to the appropriate rendering logic:
/// 1. **Primitive views** — calls ``PrimitiveView/render(into:region:context:)`` directly
/// 2. **View groups** — renders the first child (bare group outside a stack)
/// 3. **Composite views** — recurses into the view's `body`
@MainActor
public func render(
    _ view: any View,
    into buffer: inout Buffer,
    region: Region,
    context: RenderContext = RenderContext(),
) {
    guard !region.isEmpty else { return }
    if let primitive = view as? any PrimitiveView {
        primitive.render(into: &buffer, region: region, context: context)
        return
    }
    renderBody(view, into: &buffer, region: region, context: context)
}

/// Helper that opens the existential to access `body` on a composite view.
///
/// Wraps the body evaluation in `RenderEnvironment.$current.withValue(context)`
/// so that `@EnvironmentObject` property wrappers can read from it.
@MainActor
private func sizeThatFitsBody(
    _ view: some View,
    proposal: SizeProposal,
    context: RenderContext,
) -> Size2D {
    RenderEnvironment.$current.withValue(context) {
        sizeThatFits(view.body, proposal: proposal, context: context)
    }
}

/// Helper that opens the existential to access `body` on a composite view.
///
/// Wraps the body evaluation in `RenderEnvironment.$current.withValue(context)`
/// so that `@EnvironmentObject` property wrappers can read from it.
@MainActor
private func renderBody(
    _ view: some View,
    into buffer: inout Buffer,
    region: Region,
    context: RenderContext,
) {
    RenderEnvironment.$current.withValue(context) {
        render(view.body, into: &buffer, region: region, context: context)
    }
}
