import Testing
@testable import TextUI

@MainActor
@Suite("InputEvent")
struct InputEventTests {
    @Test("key events are equal")
    func keyEquality() {
        let a: InputEvent = .key(.enter)
        let b: InputEvent = .key(.enter)
        #expect(a == b)
    }

    @Test("different key events are not equal")
    func keyInequality() {
        let a: InputEvent = .key(.enter)
        let b: InputEvent = .key(.tab)
        #expect(a != b)
    }

    @Test("mouse events are equal")
    func mouseEquality() {
        let mouse = MouseEvent(button: .left, kind: .press, column: 0, row: 0, modifiers: [])
        let a: InputEvent = .mouse(mouse)
        let b: InputEvent = .mouse(mouse)
        #expect(a == b)
    }

    @Test("key and mouse events are not equal")
    func keyMouseInequality() {
        let a: InputEvent = .key(.enter)
        let b: InputEvent = .mouse(MouseEvent(button: .left, kind: .press, column: 0, row: 0, modifiers: []))
        #expect(a != b)
    }
}
