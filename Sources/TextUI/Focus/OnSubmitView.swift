/// A modifier that handles submit (Enter) events from `.edit` controls.
///
/// The handler is pushed onto the ``FocusStore``'s submit handler stack
/// before rendering content and popped after. When a focused `.edit`
/// control (e.g. ``TextField``) receives Enter and no inline handler
/// consumes it, the submit handler fires.
///
/// ```swift
/// TextField("Search", text: $query)
///     .onSubmit {
///         performSearch(query)
///     }
/// ```
struct OnSubmitView: PrimitiveView, Sendable {
    let content: any View
    let handler: @Sendable () -> Void

    func sizeThatFits(_ proposal: SizeProposal, context: RenderContext) -> Size2D {
        TextUI.sizeThatFits(content, proposal: proposal, context: context)
    }

    func render(into buffer: inout Buffer, region: Region, context: RenderContext) {
        let store = context.focusStore
        store?.pushSubmitHandler(FocusStore.SubmitHandler(handler: handler))
        TextUI.render(content, into: &buffer, region: region, context: context)
        store?.popSubmitHandler()
    }
}
