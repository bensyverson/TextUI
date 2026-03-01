import Foundation
import Testing
@testable import TextUI

@Suite("KeyEquivalent")
struct KeyEquivalentTests {
    @Test("Character init stores character")
    func characterInit() {
        let key = KeyEquivalent("s")
        #expect(key.character == "s")
        #expect(key.named == nil)
    }

    @Test("Named init stores named key")
    func namedInit() {
        let key = KeyEquivalent(.return)
        #expect(key.named == .return)
        #expect(key.character == nil)
    }

    @Test("Equality works for character keys")
    func characterEquality() {
        #expect(KeyEquivalent("a") == KeyEquivalent("a"))
        #expect(KeyEquivalent("a") != KeyEquivalent("b"))
    }

    @Test("Codable round-trip for character key")
    func characterCodable() throws {
        let key = KeyEquivalent("x")
        let data = try JSONEncoder().encode(key)
        let decoded = try JSONDecoder().decode(KeyEquivalent.self, from: data)
        #expect(decoded == key)
    }

    @Test("Codable round-trip for named key")
    func namedCodable() throws {
        let key = KeyEquivalent(.escape)
        let data = try JSONEncoder().encode(key)
        let decoded = try JSONDecoder().decode(KeyEquivalent.self, from: data)
        #expect(decoded == key)
    }
}

@Suite("KeyboardShortcut")
struct KeyboardShortcutTests {
    @Test("Ctrl+S matches .ctrl(s)")
    func ctrlSMatches() {
        let shortcut = KeyboardShortcut("s", modifiers: .control)
        #expect(shortcut.matches(.ctrl("s")))
    }

    @Test("Ctrl matching is case-insensitive")
    func ctrlCaseInsensitive() {
        let shortcut = KeyboardShortcut("S", modifiers: .control)
        #expect(shortcut.matches(.ctrl("s")))
    }

    @Test("Enter matches .enter")
    func enterMatches() {
        let shortcut = KeyboardShortcut(KeyEquivalent(.return))
        #expect(shortcut.matches(.enter))
    }

    @Test("Shift+Tab matches .shiftTab")
    func shiftTabMatches() {
        let shortcut = KeyboardShortcut(KeyEquivalent(.tab), modifiers: .shift)
        #expect(shortcut.matches(.shiftTab))
    }

    @Test("Bare character matches .character")
    func bareCharMatches() {
        let shortcut = KeyboardShortcut("q")
        #expect(shortcut.matches(.character("q")))
    }

    @Test("Bare character matches case-insensitively")
    func bareCharCaseInsensitive() {
        let shortcut = KeyboardShortcut("q")
        #expect(shortcut.matches(.character("Q")))
    }

    @Test("Unmatched shortcut returns false")
    func noMatch() {
        let shortcut = KeyboardShortcut("s", modifiers: .control)
        #expect(!shortcut.matches(.character("s")))
        #expect(!shortcut.matches(.ctrl("x")))
    }

    @Test("displayString for Ctrl+S is ^S")
    func displayCtrlS() {
        let shortcut = KeyboardShortcut("s", modifiers: .control)
        #expect(shortcut.displayString == "^S")
    }

    @Test("displayString for Tab")
    func displayTab() {
        let shortcut = KeyboardShortcut(KeyEquivalent(.tab))
        #expect(shortcut.displayString == "Tab")
    }

    @Test("displayString for Enter")
    func displayEnter() {
        let shortcut = KeyboardShortcut(KeyEquivalent(.return))
        #expect(shortcut.displayString == "Enter")
    }

    @Test("displayString for Shift+Tab is S-Tab")
    func displayShiftTab() {
        let shortcut = KeyboardShortcut(KeyEquivalent(.tab), modifiers: .shift)
        #expect(shortcut.displayString == "S-Tab")
    }

    @Test("defaultAction is Enter")
    func defaultAction() {
        #expect(KeyboardShortcut.defaultAction.matches(.enter))
    }

    @Test("cancelAction is Escape")
    func cancelAction() {
        #expect(KeyboardShortcut.cancelAction.matches(.escape))
    }
}
