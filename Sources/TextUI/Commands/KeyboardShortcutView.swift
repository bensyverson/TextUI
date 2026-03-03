/// A modifier view that attaches a keyboard shortcut to its content.
///
/// When the content is a ``Button``, the shortcut is automatically
/// registered with the ``CommandRegistry`` during each render frame.
/// This means `.keyboardShortcut()` works on any Button in the view
/// tree, not just inside ``CommandGroup`` declarations.
///
/// Shortcuts registered this way are cleared and re-accumulated each
/// frame, so they stay in sync with the rendered view tree. Static
/// ``CommandGroup`` shortcuts take priority over discovered ones.
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

        // Auto-register shortcut when wrapping a Button (skip if disabled)
        if let button = content as? Button, context.isDisabled != true {
            let name = (button.label as? Text)?.content ?? "Command"
            context.commandRegistry?.registerDiscoveredShortcut(
                name: name,
                group: "Shortcuts",
                shortcut: shortcut,
                action: button.action,
            )
        }
    }
}
