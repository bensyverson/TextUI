/// A modifier view that attaches a keyboard shortcut to its content.
///
/// This is used internally by ``CommandGroup`` to extract shortcut
/// information from `Button(...).keyboardShortcut(...)` declarations.
/// It delegates all sizing and rendering to its wrapped content.
struct KeyboardShortcutView: PrimitiveView {
    /// The wrapped content view.
    let content: any View

    /// The keyboard shortcut attached to this view.
    let shortcut: KeyboardShortcut

    func sizeThatFits(_ proposal: SizeProposal, context: RenderContext) -> Size2D {
        TextUI.sizeThatFits(content, proposal: proposal, context: context)
    }

    func render(into buffer: inout Buffer, region: Region, context: RenderContext) {
        TextUI.render(content, into: &buffer, region: region, context: context)
    }
}
