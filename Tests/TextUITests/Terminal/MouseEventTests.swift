import Foundation
import Testing
@testable import TextUI

@MainActor
@Suite("MouseEvent")
struct MouseEventTests {
    // MARK: - Button Raw Values

    @Test("button raw values match SGR encoding")
    func buttonRawValues() {
        #expect(MouseEvent.Button.left.rawValue == 0)
        #expect(MouseEvent.Button.middle.rawValue == 1)
        #expect(MouseEvent.Button.right.rawValue == 2)
        #expect(MouseEvent.Button.scrollUp.rawValue == 64)
        #expect(MouseEvent.Button.scrollDown.rawValue == 65)
    }

    // MARK: - Equality

    @Test("equal events are equal")
    func equality() {
        let a = MouseEvent(button: .left, kind: .press, column: 5, row: 10, modifiers: [])
        let b = MouseEvent(button: .left, kind: .press, column: 5, row: 10, modifiers: [])
        #expect(a == b)
    }

    @Test("different button is not equal")
    func inequalityButton() {
        let a = MouseEvent(button: .left, kind: .press, column: 5, row: 10, modifiers: [])
        let b = MouseEvent(button: .right, kind: .press, column: 5, row: 10, modifiers: [])
        #expect(a != b)
    }

    @Test("different kind is not equal")
    func inequalityKind() {
        let a = MouseEvent(button: .left, kind: .press, column: 5, row: 10, modifiers: [])
        let b = MouseEvent(button: .left, kind: .release, column: 5, row: 10, modifiers: [])
        #expect(a != b)
    }

    @Test("different position is not equal")
    func inequalityPosition() {
        let a = MouseEvent(button: .left, kind: .press, column: 5, row: 10, modifiers: [])
        let b = MouseEvent(button: .left, kind: .press, column: 6, row: 10, modifiers: [])
        #expect(a != b)
    }

    @Test("different modifiers is not equal")
    func inequalityModifiers() {
        let a = MouseEvent(button: .left, kind: .press, column: 5, row: 10, modifiers: [])
        let b = MouseEvent(button: .left, kind: .press, column: 5, row: 10, modifiers: .shift)
        #expect(a != b)
    }

    // MARK: - Codable Round-Trip

    @Test("encodes and decodes round-trip")
    func codableRoundTrip() throws {
        let event = MouseEvent(button: .right, kind: .release, column: 42, row: 7, modifiers: [.control, .shift])
        let data = try JSONEncoder().encode(event)
        let decoded = try JSONDecoder().decode(MouseEvent.self, from: data)
        #expect(decoded == event)
    }

    // MARK: - Hashable

    @Test("equal events have equal hash values")
    func hashable() {
        let a = MouseEvent(button: .left, kind: .press, column: 5, row: 10, modifiers: [])
        let b = MouseEvent(button: .left, kind: .press, column: 5, row: 10, modifiers: [])
        #expect(a.hashValue == b.hashValue)
    }
}
