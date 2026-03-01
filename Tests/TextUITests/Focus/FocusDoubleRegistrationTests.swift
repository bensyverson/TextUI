import Testing
@testable import TextUI

/// Thread-safe mutable value for use in `@Sendable` test closures.
private final class Box<T: Sendable>: @unchecked Sendable {
    var value: T
    init(_ value: T) {
        self.value = value
    }
}

@Suite("Focus Double-Registration Prevention")
struct FocusDoubleRegistrationTests {
    @Test("TextField wrapped in .focused() creates only one ring entry")
    func singleRingEntry() {
        let store = FocusStore()
        var ctx = RenderContext()
        ctx.focusStore = store

        let field = TextField("Name", text: "", fileID: "test", line: 1) { _ in }
        let wrapped = FocusedView(content: field, bindingKey: AnyHashable("name"))

        var buffer = Buffer(width: 30, height: 1)
        let region = Region(row: 0, col: 0, width: 30, height: 1)

        render(wrapped, into: &buffer, region: region, context: ctx)

        #expect(store.ring.count == 1, "Expected 1 ring entry, got \(store.ring.count)")
    }

    @Test("TextField wrapped in .focused() routes character input correctly")
    func routesCharacterInput() {
        let store = FocusStore()
        var ctx = RenderContext()
        ctx.focusStore = store

        let received = Box("")
        let field = TextField("Name", text: "hello", fileID: "test", line: 1) { received.value = $0 }
        let wrapped = FocusedView(content: field, bindingKey: AnyHashable("name"))

        var buffer = Buffer(width: 30, height: 1)
        let region = Region(row: 0, col: 0, width: 30, height: 1)

        // First render to register
        render(wrapped, into: &buffer, region: region, context: ctx)
        store.applyDefaultFocus()

        // Second render while focused
        store.beginFrame()
        render(wrapped, into: &buffer, region: region, context: ctx)

        let result = store.routeKeyEvent(.character("A"))
        #expect(result == .handled)
        #expect(received.value == "helloA")
    }

    @Test("Toggle wrapped in .focused() creates only one ring entry")
    func toggleSingleEntry() {
        let store = FocusStore()
        var ctx = RenderContext()
        ctx.focusStore = store

        let toggle = Toggle("Dark mode", isOn: false, fileID: "test", line: 1) { _ in }
        let wrapped = FocusedView(content: toggle, bindingKey: AnyHashable("dark"))

        var buffer = Buffer(width: 30, height: 1)
        let region = Region(row: 0, col: 0, width: 30, height: 1)

        render(wrapped, into: &buffer, region: region, context: ctx)

        #expect(store.ring.count == 1)
    }

    @Test("Button wrapped in .focused() creates only one ring entry")
    func buttonSingleEntry() {
        let store = FocusStore()
        var ctx = RenderContext()
        ctx.focusStore = store

        let button = Button("Submit", action: {}, fileID: "test", line: 1)
        let wrapped = FocusedView(content: button, bindingKey: AnyHashable("submit"))

        var buffer = Buffer(width: 30, height: 1)
        let region = Region(row: 0, col: 0, width: 30, height: 1)

        render(wrapped, into: &buffer, region: region, context: ctx)

        #expect(store.ring.count == 1)
    }

    @Test("Picker wrapped in .focused() creates only one ring entry")
    func pickerSingleEntry() {
        let store = FocusStore()
        var ctx = RenderContext()
        ctx.focusStore = store

        let picker = Picker("Color", selection: 0, options: ["Red", "Green", "Blue"],
                            fileID: "test", line: 1) { _ in }
        let wrapped = FocusedView(content: picker, bindingKey: AnyHashable("color"))

        var buffer = Buffer(width: 40, height: 1)
        let region = Region(row: 0, col: 0, width: 40, height: 1)

        render(wrapped, into: &buffer, region: region, context: ctx)

        #expect(store.ring.count == 1)
    }
}
