/// Returns the size a view needs given the parent's proposal.
///
/// Dispatches to the appropriate sizing logic:
/// 1. **Primitive views** — calls ``PrimitiveView/sizeThatFits(_:)`` directly
/// 2. **View groups** — sizes to the first child (bare group outside a stack)
/// 3. **Composite views** — recurses into the view's `body`
public func sizeThatFits(_ view: any View, proposal: SizeProposal) -> Size2D {
    if let primitive = view as? any PrimitiveView {
        return primitive.sizeThatFits(proposal)
    }
    return sizeThatFitsBody(view, proposal: proposal)
}

/// Renders a view into a buffer within the given region.
///
/// Dispatches to the appropriate rendering logic:
/// 1. **Primitive views** — calls ``PrimitiveView/render(into:region:)`` directly
/// 2. **View groups** — renders the first child (bare group outside a stack)
/// 3. **Composite views** — recurses into the view's `body`
public func render(_ view: any View, into buffer: inout Buffer, region: Region) {
    guard !region.isEmpty else { return }
    if let primitive = view as? any PrimitiveView {
        primitive.render(into: &buffer, region: region)
        return
    }
    renderBody(view, into: &buffer, region: region)
}

/// Helper that opens the existential to access `body` on a composite view.
private func sizeThatFitsBody(_ view: some View, proposal: SizeProposal) -> Size2D {
    sizeThatFits(view.body, proposal: proposal)
}

/// Helper that opens the existential to access `body` on a composite view.
private func renderBody(_ view: some View, into buffer: inout Buffer, region: Region) {
    render(view.body, into: &buffer, region: region)
}
