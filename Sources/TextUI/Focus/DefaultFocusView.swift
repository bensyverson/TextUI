/// A modifier that sets the default focus target for the first frame.
///
/// On the first render pass, the ``FocusStore`` will focus the entry
/// matching this binding value instead of the first entry in the ring.
///
/// ```swift
/// @FocusState var focus: Field?
///
/// VStack {
///     TextField("Name", text: $name)
///         .focused($focus, equals: .name)
///     TextField("Email", text: $email)
///         .focused($focus, equals: .email)
/// }
/// .defaultFocus($focus, .email)  // Email field focused on launch
/// ```
struct DefaultFocusView: PrimitiveView {
    let content: any View
    let targetKey: AnyHashable

    func sizeThatFits(_ proposal: SizeProposal, context: RenderContext) -> Size2D {
        TextUI.sizeThatFits(content, proposal: proposal, context: context)
    }

    func render(into buffer: inout Buffer, region: Region, context: RenderContext) {
        context.focusStore?.defaultFocusTarget = targetKey
        TextUI.render(content, into: &buffer, region: region, context: context)
    }
}
