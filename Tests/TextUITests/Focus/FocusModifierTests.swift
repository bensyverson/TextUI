import Testing
@testable import TextUI

/// Thread-safe mutable flag for use in `@Sendable` test closures.
private final class Flag: @unchecked Sendable {
    var value: Bool = false
}

@Suite("Focus Modifiers")
struct FocusModifierTests {
    // MARK: - FocusedView

    @Test(".focused() registers in ring during render")
    func focusedRegisters() {
        let store = FocusStore()
        var ctx = RenderContext()
        ctx.focusStore = store

        let view = FocusedView(
            content: Text("Name"),
            bindingKey: AnyHashable("name"),
            interaction: .activate,
        )
        var buffer = Buffer(width: 20, height: 1)
        let region = Region(row: 0, col: 0, width: 20, height: 1)

        render(view, into: &buffer, region: region, context: ctx)
        #expect(store.ring.count == 1)
        #expect(store.ring[0].bindingKey == AnyHashable("name"))
        #expect(store.ring[0].interaction == .activate)
    }

    @Test(".focused() passes isFocused to child context")
    func focusedPassesContext() {
        let store = FocusStore()
        var ctx = RenderContext()
        ctx.focusStore = store

        // Use a Button inside .focused() — the Button reads focusEnvironment
        let button = Button("OK") {}
        let view = FocusedView(
            content: button,
            bindingKey: AnyHashable("btn"),
        )
        var buffer = Buffer(width: 20, height: 1)
        let region = Region(row: 0, col: 0, width: 20, height: 1)

        render(view, into: &buffer, region: region, context: ctx)
        store.applyDefaultFocus()

        store.beginFrame()
        buffer = Buffer(width: 20, height: 1)
        render(view, into: &buffer, region: region, context: ctx)

        // FocusedView should have registered and passed isFocused=true
        // Button should render with inverse
        #expect(buffer[0, 0].style.inverse)
    }

    // MARK: - OnKeyPressView

    @Test(".onKeyPress() chain propagation")
    func onKeyPressChainPropagation() {
        let store = FocusStore()
        var ctx = RenderContext()
        ctx.focusStore = store

        let handled = Flag()
        let inner = Button("Test") {}
        let view = OnKeyPressView(content: inner) { key in
            if key == .escape {
                handled.value = true
                return .handled
            }
            return .ignored
        }

        var buffer = Buffer(width: 20, height: 1)
        let region = Region(row: 0, col: 0, width: 20, height: 1)

        render(view, into: &buffer, region: region, context: ctx)
        store.applyDefaultFocus()
        store.beginFrame()
        render(view, into: &buffer, region: region, context: ctx)

        // The Button's inline handler won't handle Escape → falls to onKeyPress
        let result = store.routeKeyEvent(.escape)
        #expect(result == .handled)
        #expect(handled.value)
    }

    // MARK: - OnSubmitView

    @Test(".onSubmit() fires on Enter for .edit controls")
    func onSubmitFiresOnEnter() {
        let store = FocusStore()
        var ctx = RenderContext()
        ctx.focusStore = store

        let submitted = Flag()
        let field = TextField("", text: "test", fileID: "test", line: 1) { _ in }
        let view = OnSubmitView(content: field) {
            submitted.value = true
        }

        var buffer = Buffer(width: 20, height: 1)
        let region = Region(row: 0, col: 0, width: 20, height: 1)

        render(view, into: &buffer, region: region, context: ctx)
        store.applyDefaultFocus()
        store.beginFrame()
        render(view, into: &buffer, region: region, context: ctx)

        let result = store.routeKeyEvent(.enter)
        #expect(result == .handled)
        #expect(submitted.value)
    }

    // MARK: - FocusSectionView

    @Test(".focusSection() groups entries with same section ID")
    func focusSectionGroups() {
        let store = FocusStore()
        var ctx = RenderContext()
        ctx.focusStore = store

        let section = FocusSectionView(content: VStack {
            Button("A") {}
            Button("B") {}
        })

        var buffer = Buffer(width: 20, height: 2)
        let region = Region(row: 0, col: 0, width: 20, height: 2)

        render(section, into: &buffer, region: region, context: ctx)

        // Both buttons should share the same section ID
        #expect(store.ring.count == 2)
        #expect(store.ring[0].sectionID != nil)
        #expect(store.ring[0].sectionID == store.ring[1].sectionID)
    }

    // MARK: - DefaultFocusView

    @Test(".defaultFocus() sets the default focus target")
    func defaultFocusSetsTarget() {
        let store = FocusStore()
        var ctx = RenderContext()
        ctx.focusStore = store

        let view = DefaultFocusView(
            content: VStack {
                FocusedView(content: Text("A"), bindingKey: AnyHashable("a"))
                FocusedView(content: Text("B"), bindingKey: AnyHashable("b"))
            },
            targetKey: AnyHashable("b"),
        )

        var buffer = Buffer(width: 20, height: 2)
        let region = Region(row: 0, col: 0, width: 20, height: 2)

        render(view, into: &buffer, region: region, context: ctx)
        store.applyDefaultFocus()

        // Should focus entry "b" (index 1), not "a" (index 0)
        #expect(store.focusedIndex == 1)
        #expect(store.focusedBindingKey == AnyHashable("b"))
    }
}
