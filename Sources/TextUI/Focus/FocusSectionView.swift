/// A modifier that groups child focusable controls into a focus section.
///
/// Arrow key navigation is constrained to controls within the same
/// section. Created by the `.focusSection()` modifier.
///
/// ```swift
/// VStack {
///     // Section 1: arrow keys cycle within these buttons
///     VStack {
///         Button("Option A") { ... }
///         Button("Option B") { ... }
///     }
///     .focusSection()
///
///     // Section 2: separate arrow navigation
///     VStack {
///         Button("Save") { ... }
///         Button("Cancel") { ... }
///     }
///     .focusSection()
/// }
/// ```
struct FocusSectionView: PrimitiveView {
    let content: any View

    func sizeThatFits(_ proposal: SizeProposal, context: RenderContext) -> Size2D {
        TextUI.sizeThatFits(content, proposal: proposal, context: context)
    }

    func render(into buffer: inout Buffer, region: Region, context: RenderContext) {
        var ctx = context
        if let store = ctx.focusStore {
            ctx.currentFocusSectionID = store.nextSection()
        }
        TextUI.render(content, into: &buffer, region: region, context: ctx)
    }
}
