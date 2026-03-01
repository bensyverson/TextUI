import Testing
@testable import TextUI

/// Thread-safe mutable value for use in `@Sendable` test closures.
private final class Box<T: Sendable>: @unchecked Sendable {
    var value: T
    init(_ value: T) {
        self.value = value
    }
}

/// Thread-safe mutable flag for use in `@Sendable` test closures.
private final class Flag: @unchecked Sendable {
    var value: Bool = false
}

@Suite("Focus Integration")
struct FocusIntegrationTests {
    // MARK: - Multi-Button Tab Navigation

    @Test("VStack of Buttons: Tab cycles focus")
    func buttonTabCycle() {
        let store = FocusStore()
        var ctx = RenderContext()
        ctx.focusStore = store

        let view = VStack {
            Button("Save") {}
            Button("Cancel") {}
            Button("Help") {}
        }

        var buffer = Buffer(width: 20, height: 3)
        let region = Region(row: 0, col: 0, width: 20, height: 3)

        // First render and apply default focus
        render(view, into: &buffer, region: region, context: ctx)
        store.applyDefaultFocus()
        #expect(store.ring.count == 3)
        #expect(store.focusedIndex == 0)

        // Tab to next
        store.focusNext()
        #expect(store.focusedIndex == 1)

        // Tab again
        store.focusNext()
        #expect(store.focusedIndex == 2)

        // Tab wraps
        store.focusNext()
        #expect(store.focusedIndex == 0)
    }

    @Test("VStack of Buttons: Enter fires focused button action")
    func buttonEnterFires() {
        let store = FocusStore()
        var ctx = RenderContext()
        ctx.focusStore = store

        let fired = [Flag(), Flag(), Flag()]
        let view = VStack {
            Button("Save") { fired[0].value = true }
            Button("Cancel") { fired[1].value = true }
            Button("Help") { fired[2].value = true }
        }

        var buffer = Buffer(width: 20, height: 3)
        let region = Region(row: 0, col: 0, width: 20, height: 3)

        render(view, into: &buffer, region: region, context: ctx)
        store.applyDefaultFocus()

        // Re-render focused
        store.beginFrame()
        render(view, into: &buffer, region: region, context: ctx)

        // Enter fires first button
        var result = store.routeKeyEvent(.enter)
        #expect(result == .handled)
        #expect(fired[0].value)
        #expect(!fired[1].value)

        // Tab to second and fire
        store.focusNext()
        store.beginFrame()
        render(view, into: &buffer, region: region, context: ctx)
        result = store.routeKeyEvent(.enter)
        #expect(result == .handled)
        #expect(fired[1].value)
    }

    // MARK: - Form with TextField + Button

    @Test("Form: type text, Tab to button, Enter submits")
    func formFlow() {
        let store = FocusStore()
        var ctx = RenderContext()
        ctx.focusStore = store

        let textReceived = Box("")
        let submitted = Flag()

        let field = TextField("Name", text: "", fileID: "form", line: 1) { newText in
            textReceived.value = newText
        }
        let button = Button("Submit") {
            submitted.value = true
        }

        let view = VStack {
            field
            button
        }

        var buffer = Buffer(width: 30, height: 2)
        let region = Region(row: 0, col: 0, width: 30, height: 2)

        // Initial render + default focus (should focus TextField first)
        render(view, into: &buffer, region: region, context: ctx)
        store.applyDefaultFocus()
        #expect(store.ring.count == 2)
        #expect(store.focusedIndex == 0)
        #expect(store.ring[0].interaction == .edit) // TextField

        // Re-render with focus
        store.beginFrame()
        render(view, into: &buffer, region: region, context: ctx)

        // Type "H"
        store.routeKeyEvent(.character("H"))
        #expect(textReceived.value == "H")

        // Re-render with updated text, then type "i"
        store.beginFrame()
        render(VStack {
            TextField("Name", text: "H", fileID: "form", line: 1) { newText in
                textReceived.value = newText
            }
            button
        }, into: &buffer, region: region, context: ctx)
        store.routeKeyEvent(.character("i"))
        #expect(textReceived.value == "Hi")

        // Tab to button
        store.focusNext()
        store.beginFrame()
        render(VStack {
            TextField("Name", text: "Hi", fileID: "form", line: 1) { _ in }
            button
        }, into: &buffer, region: region, context: ctx)
        #expect(store.focusedIndex == 1)
        #expect(store.ring[1].interaction == .activate) // Button

        // Enter fires button
        let result = store.routeKeyEvent(.enter)
        #expect(result == .handled)
        #expect(submitted.value)
    }

    // MARK: - Focus Sections with Arrow Nav

    @Test("Focus sections constrain arrow navigation")
    func focusSectionArrowNav() {
        let store = FocusStore()
        var ctx = RenderContext()
        ctx.focusStore = store

        let view = VStack {
            VStack {
                Button("A") {}
                Button("B") {}
            }.focusSection()
            VStack {
                Button("C") {}
                Button("D") {}
            }.focusSection()
        }

        var buffer = Buffer(width: 20, height: 4)
        let region = Region(row: 0, col: 0, width: 20, height: 4)

        render(view, into: &buffer, region: region, context: ctx)
        store.applyDefaultFocus()
        #expect(store.ring.count == 4)

        // Focus is on A (index 0, section 0)
        #expect(store.focusedIndex == 0)

        // Down arrow: A → B (within section 0)
        store.focusInDirection(.down)
        #expect(store.focusedIndex == 1)

        // Down arrow: B → A (wraps within section 0, NOT to C)
        store.focusInDirection(.down)
        #expect(store.focusedIndex == 0)

        // Tab crosses section boundaries: A → B → C → D
        store.focusNext()
        #expect(store.focusedIndex == 1) // B
        store.focusNext()
        #expect(store.focusedIndex == 2) // C
        store.focusNext()
        #expect(store.focusedIndex == 3) // D
    }

    // MARK: - onSubmit with TextField

    @Test("onSubmit fires when Enter pressed on focused TextField")
    func onSubmitWithTextField() {
        let store = FocusStore()
        var ctx = RenderContext()
        ctx.focusStore = store

        let submitted = Flag()
        let view = TextField("Search", text: "query", fileID: "search", line: 1) { _ in }
            .onSubmit { submitted.value = true }

        var buffer = Buffer(width: 30, height: 1)
        let region = Region(row: 0, col: 0, width: 30, height: 1)

        render(view, into: &buffer, region: region, context: ctx)
        store.applyDefaultFocus()
        store.beginFrame()
        render(view, into: &buffer, region: region, context: ctx)

        let result = store.routeKeyEvent(.enter)
        #expect(result == .handled)
        #expect(submitted.value)
    }

    // MARK: - Mixed Controls

    @Test("Mixed controls: TextField, Toggle, Button all focusable")
    func mixedControls() {
        let store = FocusStore()
        var ctx = RenderContext()
        ctx.focusStore = store

        let toggled = Flag()
        let submitted = Flag()

        let view = VStack {
            TextField("Name", text: "", fileID: "mixed", line: 1) { _ in }
            Toggle("Agree", isOn: false) { _ in toggled.value = true }
            Button("Submit") { submitted.value = true }
        }

        var buffer = Buffer(width: 30, height: 3)
        let region = Region(row: 0, col: 0, width: 30, height: 3)

        render(view, into: &buffer, region: region, context: ctx)
        store.applyDefaultFocus()
        #expect(store.ring.count == 3)
        #expect(store.ring[0].interaction == .edit) // TextField
        #expect(store.ring[1].interaction == .activate) // Toggle
        #expect(store.ring[2].interaction == .activate) // Button

        // Tab through all controls
        store.focusNext() // → Toggle
        store.focusNext() // → Button
        #expect(store.focusedIndex == 2)

        // Re-render and fire button
        store.beginFrame()
        render(view, into: &buffer, region: region, context: ctx)
        store.routeKeyEvent(.enter)
        #expect(submitted.value)
    }
}
