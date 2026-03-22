/// A modifier that observes selection changes in a descendant ``TabView`` or ``Table``.
///
/// The handler is pushed onto both the ``FocusStore``'s tab and table
/// selection handler stacks before rendering content and popped after.
/// When a ``TabView`` or ``Table`` renders, it reads the top of its
/// respective stack and stores the handler for use during key event
/// handling and mouse click handling.
///
/// ```swift
/// TabView(selection: state.selectedTab) {
///     TabView.Tab("Home") { HomeView() }
///     TabView.Tab("Settings") { SettingsView() }
/// }
/// .onSelectionChange { newIndex in
///     state.selectedTab = newIndex
/// }
/// ```
struct OnTabSelectionChangeView: PrimitiveView {
    let content: any View
    let handler: (Int) -> Void

    func sizeThatFits(_ proposal: SizeProposal, context: RenderContext) -> Size2D {
        let store = context.focusStore
        store?.pushTabSelectionHandler(handler)
        store?.pushTableSelectionHandler(handler)
        let size = TextUI.sizeThatFits(content, proposal: proposal, context: context)
        store?.popTabSelectionHandler()
        store?.popTableSelectionHandler()
        return size
    }

    func render(into buffer: inout Buffer, region: Region, context: RenderContext) {
        let store = context.focusStore
        store?.pushTabSelectionHandler(handler)
        store?.pushTableSelectionHandler(handler)
        TextUI.render(content, into: &buffer, region: region, context: context)
        store?.popTabSelectionHandler()
        store?.popTableSelectionHandler()
    }
}
