/// A modifier that intercepts key events for focusable descendants.
///
/// The handler is pushed onto the ``FocusStore``'s handler chain stack
/// before rendering content and popped after. When a focused descendant
/// receives a key event, the handler chain is invoked from innermost
/// (deepest) to outermost.
///
/// ```swift
/// VStack {
///     TextField("Search", text: $query)
///     ResultsList(results: results)
/// }
/// .onKeyPress { key in
///     if key == .escape {
///         dismiss()
///         return .handled
///     }
///     return .ignored
/// }
/// ```
struct OnKeyPressView: PrimitiveView {
    let content: any View
    let handler: (KeyEvent) -> KeyEventResult

    func sizeThatFits(_ proposal: SizeProposal, context: RenderContext) -> Size2D {
        TextUI.sizeThatFits(content, proposal: proposal, context: context)
    }

    func render(into buffer: inout Buffer, region: Region, context: RenderContext) {
        let store = context.focusStore
        store?.pushKeyHandler(FocusStore.KeyHandler(handler: handler))
        TextUI.render(content, into: &buffer, region: region, context: context)
        store?.popKeyHandler()
    }
}
