/// A modifier that registers a view as focusable and binds it to a focus value.
///
/// Created by the `.focused(_:equals:)` modifier, this view registers the
/// content in the ``FocusStore``'s focus ring during `render()` and injects
/// a ``FocusEnvironment`` so the child can determine if it is focused.
///
/// ```swift
/// @FocusState var focus: Field?
///
/// TextField("Name", text: $name)
///     .focused($focus, equals: .name)
/// ```
struct FocusedView: PrimitiveView {
    let content: any View
    let bindingKey: AnyHashable
    let interaction: FocusInteraction
    let autoKey: AnyHashable?

    init(
        content: any View,
        bindingKey: AnyHashable,
        interaction: FocusInteraction = .activate,
        autoKey: AnyHashable? = nil,
    ) {
        self.content = content
        self.bindingKey = bindingKey
        self.interaction = interaction
        self.autoKey = autoKey
    }

    func sizeThatFits(_ proposal: SizeProposal, context: RenderContext) -> Size2D {
        TextUI.sizeThatFits(content, proposal: proposal, context: context)
    }

    func render(into buffer: inout Buffer, region: Region, context: RenderContext) {
        var ctx = context

        if let store = ctx.focusStore {
            let focusID = store.register(
                interaction: interaction,
                region: region,
                sectionID: ctx.currentFocusSectionID,
                bindingKey: bindingKey,
                autoKey: autoKey,
            )
            let isFocused = store.isFocused(focusID)
            ctx.focusEnvironment = FocusEnvironment(isFocused: isFocused, focusID: focusID)
        }

        TextUI.render(content, into: &buffer, region: region, context: ctx)
    }
}
