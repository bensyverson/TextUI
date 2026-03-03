import Testing
@testable import TextUI

/// Mutable value for use in test closures.
private final class Box<T: Sendable> {
    var value: T
    init(_ value: T) {
        self.value = value
    }
}

/// Creates a TextField with a fixed identity for testing cursor state persistence.
@MainActor
private func testField(
    _ placeholder: String = "",
    text: String,
    onChange: @escaping (String) -> Void,
) -> TextField {
    TextField(placeholder, text: text, fileID: "test", line: 1, onChange: onChange)
}

@MainActor
@Suite("TextField")
struct TextFieldTests {
    @Test("Greedy width sizing")
    func greedyWidth() {
        let field = TextField("Search", text: "") { _ in }
        let size = sizeThatFits(field, proposal: SizeProposal(width: 40, height: 10))
        #expect(size == Size2D(width: 40, height: 1))
    }

    @Test("Defaults to width 20 with nil proposal")
    func defaultWidth() {
        let field = TextField("Search", text: "") { _ in }
        let size = sizeThatFits(field, proposal: SizeProposal(width: nil, height: nil))
        #expect(size == Size2D(width: 20, height: 1))
    }

    @Test("Placeholder shown when empty and unfocused")
    func placeholderWhenEmpty() {
        let field = TextField("Search", text: "") { _ in }
        var buffer = Buffer(width: 20, height: 1)
        let region = Region(row: 0, col: 0, width: 20, height: 1)
        render(field, into: &buffer, region: region)
        #expect(buffer[0, 0].char == "S")
        #expect(buffer[0, 0].style.dim)
    }

    @Test("Text renders when not empty")
    func textRendering() {
        let field = TextField("Search", text: "hello") { _ in }
        var buffer = Buffer(width: 20, height: 1)
        let region = Region(row: 0, col: 0, width: 20, height: 1)
        render(field, into: &buffer, region: region)
        #expect(buffer[0, 0].char == "h")
        #expect(buffer[0, 1].char == "e")
        #expect(buffer[0, 2].char == "l")
        #expect(buffer[0, 3].char == "l")
        #expect(buffer[0, 4].char == "o")
    }

    @Test("Character insert at cursor position")
    func characterInsert() {
        let store = FocusStore()
        var ctx = RenderContext()
        ctx.focusStore = store

        let received = Box("")
        let field = testField(text: "ab") { received.value = $0 }

        var buffer = Buffer(width: 20, height: 1)
        let region = Region(row: 0, col: 0, width: 20, height: 1)

        render(field, into: &buffer, region: region, context: ctx)
        store.applyDefaultFocus()
        store.beginFrame()
        render(field, into: &buffer, region: region, context: ctx)

        let result = store.routeKeyEvent(.character("c"))
        #expect(result == .handled)
        #expect(received.value == "abc")
    }

    @Test("Backspace removes character before cursor")
    func backspace() {
        let store = FocusStore()
        var ctx = RenderContext()
        ctx.focusStore = store

        let received = Box("")
        let field = testField(text: "abc") { received.value = $0 }

        var buffer = Buffer(width: 20, height: 1)
        let region = Region(row: 0, col: 0, width: 20, height: 1)

        render(field, into: &buffer, region: region, context: ctx)
        store.applyDefaultFocus()
        store.beginFrame()
        render(field, into: &buffer, region: region, context: ctx)

        let result = store.routeKeyEvent(.backspace)
        #expect(result == .handled)
        #expect(received.value == "ab")
    }

    @Test("Left/Right moves cursor")
    func cursorMovement() {
        let store = FocusStore()
        var ctx = RenderContext()
        ctx.focusStore = store

        let received = Box("")

        var buffer = Buffer(width: 20, height: 1)
        let region = Region(row: 0, col: 0, width: 20, height: 1)

        // First render
        let field1 = testField(text: "abc") { received.value = $0 }
        render(field1, into: &buffer, region: region, context: ctx)
        store.applyDefaultFocus()

        // Second render (focused)
        store.beginFrame()
        let field2 = testField(text: "abc") { received.value = $0 }
        render(field2, into: &buffer, region: region, context: ctx)

        // Move left from end (pos 3) to pos 1
        store.routeKeyEvent(.left)
        store.routeKeyEvent(.left)

        // Re-render with updated cursor
        store.beginFrame()
        let field3 = testField(text: "abc") { received.value = $0 }
        render(field3, into: &buffer, region: region, context: ctx)

        // Type 'x' at position 1
        store.routeKeyEvent(.character("x"))
        #expect(received.value == "axbc")
    }

    @Test("Home moves cursor to beginning")
    func homeCursor() {
        let store = FocusStore()
        var ctx = RenderContext()
        ctx.focusStore = store

        let received = Box("")

        var buffer = Buffer(width: 20, height: 1)
        let region = Region(row: 0, col: 0, width: 20, height: 1)

        let field1 = testField(text: "abc") { received.value = $0 }
        render(field1, into: &buffer, region: region, context: ctx)
        store.applyDefaultFocus()

        store.beginFrame()
        let field2 = testField(text: "abc") { received.value = $0 }
        render(field2, into: &buffer, region: region, context: ctx)

        store.routeKeyEvent(.home)

        store.beginFrame()
        let field3 = testField(text: "abc") { received.value = $0 }
        render(field3, into: &buffer, region: region, context: ctx)

        store.routeKeyEvent(.character("x"))
        #expect(received.value == "xabc")
    }

    @Test("End moves cursor to end")
    func endCursor() {
        let store = FocusStore()
        var ctx = RenderContext()
        ctx.focusStore = store

        let received = Box("")

        var buffer = Buffer(width: 20, height: 1)
        let region = Region(row: 0, col: 0, width: 20, height: 1)

        let field1 = testField(text: "abc") { received.value = $0 }
        render(field1, into: &buffer, region: region, context: ctx)
        store.applyDefaultFocus()

        store.beginFrame()
        let field2 = testField(text: "abc") { received.value = $0 }
        render(field2, into: &buffer, region: region, context: ctx)

        // Home then End
        store.routeKeyEvent(.home)
        store.routeKeyEvent(.end)

        store.beginFrame()
        let field3 = testField(text: "abc") { received.value = $0 }
        render(field3, into: &buffer, region: region, context: ctx)

        store.routeKeyEvent(.character("x"))
        #expect(received.value == "abcx")
    }

    @Test("Multiple characters in one frame do not crash")
    func multipleCharsOneFrame() {
        let store = FocusStore()
        var ctx = RenderContext()
        ctx.focusStore = store

        let received = Box("")

        var buffer = Buffer(width: 20, height: 1)
        let region = Region(row: 0, col: 0, width: 20, height: 1)

        // Render with "hi" (len 2), cursor at 2
        let field1 = testField(text: "hi") { received.value = $0 }
        render(field1, into: &buffer, region: region, context: ctx)
        store.applyDefaultFocus()

        store.beginFrame()
        let field2 = testField(text: "hi") { received.value = $0 }
        render(field2, into: &buffer, region: region, context: ctx)

        // Type two characters without re-rendering in between.
        // The first updates cursor to 3 (past captured text length 2).
        // The second must not crash when reading cursor=3 against "hi".
        store.routeKeyEvent(.character("a"))
        #expect(received.value == "hia")
        store.routeKeyEvent(.character("b"))
        #expect(received.value == "hiab")
    }

    @Test("Cursor-only movement does not fire onChange")
    func cursorMovementNoOnChange() {
        let store = FocusStore()
        var ctx = RenderContext()
        ctx.focusStore = store

        let callCount = Box(0)

        var buffer = Buffer(width: 20, height: 1)
        let region = Region(row: 0, col: 0, width: 20, height: 1)

        let field1 = testField(text: "abc") { _ in callCount.value += 1 }
        render(field1, into: &buffer, region: region, context: ctx)
        store.applyDefaultFocus()

        store.beginFrame()
        let field2 = testField(text: "abc") { _ in callCount.value += 1 }
        render(field2, into: &buffer, region: region, context: ctx)

        // Cursor movements should NOT trigger onChange
        store.routeKeyEvent(.left)
        store.routeKeyEvent(.right)
        store.routeKeyEvent(.home)
        store.routeKeyEvent(.end)
        #expect(callCount.value == 0)
    }

    @Test("External text reset clears stored state")
    func externalTextReset() {
        let store = FocusStore()
        var ctx = RenderContext()
        ctx.focusStore = store

        let received = Box("")

        var buffer = Buffer(width: 20, height: 1)
        let region = Region(row: 0, col: 0, width: 20, height: 1)

        // Render with "hello", type to build up cursor
        let field1 = testField(text: "hello") { received.value = $0 }
        render(field1, into: &buffer, region: region, context: ctx)
        store.applyDefaultFocus()

        store.beginFrame()
        let field2 = testField(text: "hello") { received.value = $0 }
        render(field2, into: &buffer, region: region, context: ctx)

        // Type a char (cursor now 6, text "hellox")
        store.routeKeyEvent(.character("x"))
        #expect(received.value == "hellox")

        // External reset: re-render with empty text (simulates submit clearing)
        store.beginFrame()
        let field3 = testField(text: "") { received.value = $0 }
        render(field3, into: &buffer, region: region, context: ctx)

        // Type 'a' — should start from "" not "hellox"
        store.routeKeyEvent(.character("a"))
        #expect(received.value == "a")
    }

    @Test("Cursor position renders with inverse style when focused")
    func cursorRendering() {
        let store = FocusStore()
        var ctx = RenderContext()
        ctx.focusStore = store

        let field = testField(text: "ab") { _ in }
        var buffer = Buffer(width: 20, height: 1)
        let region = Region(row: 0, col: 0, width: 20, height: 1)

        render(field, into: &buffer, region: region, context: ctx)
        store.applyDefaultFocus()
        store.beginFrame()
        buffer = Buffer(width: 20, height: 1)
        render(field, into: &buffer, region: region, context: ctx)

        // Cursor at end (pos 2) = inverse on col 2
        #expect(buffer[0, 2].style.inverse)
        #expect(!buffer[0, 0].style.inverse)
        #expect(!buffer[0, 1].style.inverse)
    }
}
