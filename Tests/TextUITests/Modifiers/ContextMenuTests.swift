import Testing
@testable import TextUI

/// Mutable flag for use in test closures.
private final class Flag {
    var value: Bool = false
}

@MainActor
@Suite("ContextMenu")
struct ContextMenuTests {
    @Test("Context menu passes through sizing to content")
    func sizingPassthrough() {
        let view = Text("Hello")
            .contextMenu {
                Button("Copy") {}
            }

        let size = sizeThatFits(view, proposal: SizeProposal(width: 40, height: 10))
        let contentSize = sizeThatFits(Text("Hello"), proposal: SizeProposal(width: 40, height: 10))
        #expect(size == contentSize)
    }

    @Test("Context menu renders content normally")
    func rendersContent() {
        let view = Text("Hello")
            .contextMenu {
                Button("Copy") {}
            }

        var buffer = Buffer(width: 10, height: 1)
        let region = Region(row: 0, col: 0, width: 10, height: 1)
        render(view, into: &buffer, region: region)

        #expect(buffer[0, 0].char == "H")
        #expect(buffer[0, 4].char == "o")
    }

    @Test("Context menu registers target in FocusStore")
    func registersTarget() {
        let store = FocusStore()
        var ctx = RenderContext()
        ctx.focusStore = store

        let view = Text("Hello")
            .contextMenu {
                Button("Copy") {}
            }

        var buffer = Buffer(width: 10, height: 1)
        let region = Region(row: 0, col: 0, width: 10, height: 1)

        RenderEnvironment.$current.withValue(ctx) {
            render(view, into: &buffer, region: region, context: ctx)
        }

        let target = store.contextMenuTarget(at: 0, column: 5)
        #expect(target != nil)
    }

    @Test("Context menu shows overlay when state is open")
    func showsOverlayWhenOpen() {
        let store = FocusStore()
        let overlayStore = OverlayStore()
        var ctx = RenderContext()
        ctx.focusStore = store
        ctx.overlayStore = overlayStore

        // Pre-set the context menu state to open
        let autoKey = AnyHashable("test-menu")
        store.setControlState(
            FocusStore.ContextMenuState(isOpen: true, anchorRow: 1, anchorCol: 0),
            forKey: autoKey,
        )

        let view = ContextMenuView(
            content: Text("Hello"),
            menuBuilder: { [Button("Copy") {}] },
            autoKey: autoKey,
        )

        var buffer = Buffer(width: 30, height: 10)
        let region = Region(row: 0, col: 0, width: 30, height: 10)

        RenderEnvironment.$current.withValue(ctx) {
            render(view, into: &buffer, region: region, context: ctx)
        }

        // Overlay should have been registered
        #expect(overlayStore.overlays.count == 1)
    }

    @Test("Context menu registers dismiss handler when open")
    func registersDismissHandler() {
        let store = FocusStore()
        let overlayStore = OverlayStore()
        var ctx = RenderContext()
        ctx.focusStore = store
        ctx.overlayStore = overlayStore

        let autoKey = AnyHashable("test-menu")
        store.setControlState(
            FocusStore.ContextMenuState(isOpen: true, anchorRow: 1, anchorCol: 0),
            forKey: autoKey,
        )

        let view = ContextMenuView(
            content: Text("Hello"),
            menuBuilder: { [Button("Copy") {}] },
            autoKey: autoKey,
        )

        var buffer = Buffer(width: 30, height: 10)
        let region = Region(row: 0, col: 0, width: 30, height: 10)

        RenderEnvironment.$current.withValue(ctx) {
            render(view, into: &buffer, region: region, context: ctx)
        }

        // Dismiss handler should close the menu
        store.fireDismissHandlers()
        let state = store.controlState(forKey: autoKey, as: FocusStore.ContextMenuState.self)
        #expect(state?.isOpen == false)
    }
}
