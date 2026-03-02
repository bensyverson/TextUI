import Testing
@testable import TextUI

/// Thread-safe mutable flag for use in `@Sendable` test closures.
private final class Flag: @unchecked Sendable {
    var value: Bool = false
}

@Suite("DisabledView")
struct DisabledViewTests {
    @Test("Disabled button does not register in focus ring")
    func disabledButtonSkipsFocus() {
        let store = FocusStore()
        var ctx = RenderContext()
        ctx.focusStore = store

        let fired = Flag()
        let view = Button("OK") { fired.value = true }.disabled(true)
        var buffer = Buffer(width: 10, height: 1)
        let region = Region(row: 0, col: 0, width: 10, height: 1)

        render(view, into: &buffer, region: region, context: ctx)
        store.applyDefaultFocus()
        store.beginFrame()
        buffer = Buffer(width: 10, height: 1)
        render(view, into: &buffer, region: region, context: ctx)

        // Label should render
        #expect(buffer[0, 0].char == "O")
        #expect(buffer[0, 1].char == "K")

        // Should NOT have inverse styling (not focused)
        #expect(!buffer[0, 0].style.inverse)

        // Should have dim styling from DisabledView
        #expect(buffer[0, 0].style.dim)

        // Key events should not fire the action
        let result = store.routeKeyEvent(.enter)
        #expect(result == .ignored)
        #expect(!fired.value)
    }

    @Test("Disabled(false) does not affect controls")
    func disabledFalseIsNoop() {
        let store = FocusStore()
        var ctx = RenderContext()
        ctx.focusStore = store

        let fired = Flag()
        let view = Button("OK") { fired.value = true }.disabled(false)
        var buffer = Buffer(width: 10, height: 1)
        let region = Region(row: 0, col: 0, width: 10, height: 1)

        render(view, into: &buffer, region: region, context: ctx)
        store.applyDefaultFocus()
        store.beginFrame()
        buffer = Buffer(width: 10, height: 1)
        render(view, into: &buffer, region: region, context: ctx)

        // Should be focused and inverse-styled
        #expect(buffer[0, 0].style.inverse)

        // Enter should fire
        let result = store.routeKeyEvent(.enter)
        #expect(result == .handled)
        #expect(fired.value)
    }

    @Test("Disabled TextField renders text without cursor")
    func disabledTextFieldNoCursor() {
        let store = FocusStore()
        var ctx = RenderContext()
        ctx.focusStore = store

        let view = TextField("Search", text: "hello") { _ in }.disabled(true)
        var buffer = Buffer(width: 20, height: 1)
        let region = Region(row: 0, col: 0, width: 20, height: 1)

        render(view, into: &buffer, region: region, context: ctx)
        store.applyDefaultFocus()
        store.beginFrame()
        buffer = Buffer(width: 20, height: 1)
        render(view, into: &buffer, region: region, context: ctx)

        // Text should render
        #expect(buffer[0, 0].char == "h")
        #expect(buffer[0, 4].char == "o")

        // Should be dim
        #expect(buffer[0, 0].style.dim)

        // Should NOT have inverse styling (no cursor)
        #expect(!buffer[0, 0].style.inverse)
    }

    @Test("Disabled TextField shows placeholder when empty")
    func disabledTextFieldPlaceholder() {
        let view = TextField("Search", text: "") { _ in }.disabled(true)
        var buffer = Buffer(width: 20, height: 1)
        let region = Region(row: 0, col: 0, width: 20, height: 1)

        render(view, into: &buffer, region: region)

        // Placeholder should render with dim
        #expect(buffer[0, 0].char == "S")
        #expect(buffer[0, 0].style.dim)
    }

    @Test("Disabled Toggle renders but does not register focus")
    func disabledToggle() {
        let store = FocusStore()
        var ctx = RenderContext()
        ctx.focusStore = store

        let toggled = Flag()
        let view = Toggle("Option", isOn: true) { _ in toggled.value = true }.disabled(true)
        var buffer = Buffer(width: 20, height: 1)
        let region = Region(row: 0, col: 0, width: 20, height: 1)

        render(view, into: &buffer, region: region, context: ctx)
        store.applyDefaultFocus()
        store.beginFrame()
        buffer = Buffer(width: 20, height: 1)
        render(view, into: &buffer, region: region, context: ctx)

        // Checkbox should render
        #expect(buffer[0, 0].char == "[")
        #expect(buffer[0, 1].char == "x")

        // Should be dim
        #expect(buffer[0, 0].style.dim)

        // Should NOT toggle on key press
        let result = store.routeKeyEvent(.character(" "))
        #expect(result == .ignored)
        #expect(!toggled.value)
    }

    @Test("Disabled Picker renders but does not register focus")
    func disabledPicker() {
        let store = FocusStore()
        var ctx = RenderContext()
        ctx.focusStore = store

        let changed = Flag()
        let view = Picker("Color", selection: 0, options: ["Red", "Green"]) { _ in
            changed.value = true
        }.disabled(true)
        var buffer = Buffer(width: 30, height: 1)
        let region = Region(row: 0, col: 0, width: 30, height: 1)

        render(view, into: &buffer, region: region, context: ctx)
        store.applyDefaultFocus()
        store.beginFrame()
        buffer = Buffer(width: 30, height: 1)
        render(view, into: &buffer, region: region, context: ctx)

        // Label and option should render
        #expect(buffer[0, 0].char == "C")

        // Should be dim
        #expect(buffer[0, 0].style.dim)

        // Should NOT change on key press
        let result = store.routeKeyEvent(.right)
        #expect(result == .ignored)
        #expect(!changed.value)
    }

    @Test("Sizing is preserved when disabled")
    func disabledPreservesSize() {
        let button = Button("Submit") {}
        let enabledSize = sizeThatFits(button, proposal: SizeProposal(width: 40, height: 10))

        let disabledButton = Button("Submit") {}.disabled(true)
        let disabledSize = sizeThatFits(disabledButton, proposal: SizeProposal(width: 40, height: 10))

        #expect(enabledSize == disabledSize)
    }
}
