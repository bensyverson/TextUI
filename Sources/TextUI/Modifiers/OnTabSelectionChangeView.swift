/// A modifier that observes tab selection changes in a descendant ``TabView``.
///
/// The handler is pushed onto the ``FocusStore``'s tab selection handler
/// stack before rendering content and popped after. When a ``TabView``
/// renders, it reads the top of the stack and stores it for use during
/// key event handling (both focused arrow keys and global tab switching).
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
        let size = TextUI.sizeThatFits(content, proposal: proposal, context: context)
        store?.popTabSelectionHandler()
        return size
    }

    func render(into buffer: inout Buffer, region: Region, context: RenderContext) {
        let store = context.focusStore
        store?.pushTabSelectionHandler(handler)
        TextUI.render(content, into: &buffer, region: region, context: context)
        store?.popTabSelectionHandler()
    }
}
