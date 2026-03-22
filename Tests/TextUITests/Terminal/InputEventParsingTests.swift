import Testing
@testable import TextUI

@MainActor
@Suite("InputEvent Parsing")
struct InputEventParsingTests {
    // MARK: - Helpers

    /// Builds an SGR mouse sequence: ESC [ < button ; col ; row M/m
    /// Coordinates are 1-based (wire format).
    private func sgr(button: Int, col: Int, row: Int, press: Bool = true) -> [UInt8] {
        let terminator: UInt8 = press ? 0x4D : 0x6D // M or m
        let params = "\(button);\(col);\(row)"
        return [0x1B, 0x5B, 0x3C] + Array(params.utf8) + [terminator]
    }

    // MARK: - Left Button

    @Test("parses left button press")
    func leftPress() throws {
        let bytes = sgr(button: 0, col: 1, row: 1)
        let result = try #require(InputEvent.parse(bytes))
        let expected: InputEvent = .mouse(MouseEvent(button: .left, kind: .press, column: 0, row: 0, modifiers: []))
        #expect(result.event == expected)
        #expect(result.consumed == bytes.count)
    }

    @Test("parses left button release")
    func leftRelease() throws {
        let bytes = sgr(button: 0, col: 1, row: 1, press: false)
        let result = try #require(InputEvent.parse(bytes))
        let expected: InputEvent = .mouse(MouseEvent(button: .left, kind: .release, column: 0, row: 0, modifiers: []))
        #expect(result.event == expected)
    }

    // MARK: - Right Button

    @Test("parses right button press")
    func rightPress() throws {
        let bytes = sgr(button: 2, col: 5, row: 10)
        let result = try #require(InputEvent.parse(bytes))
        let expected: InputEvent = .mouse(MouseEvent(button: .right, kind: .press, column: 4, row: 9, modifiers: []))
        #expect(result.event == expected)
    }

    // MARK: - Middle Button

    @Test("parses middle button press")
    func middlePress() throws {
        let bytes = sgr(button: 1, col: 1, row: 1)
        let result = try #require(InputEvent.parse(bytes))
        let expected: InputEvent = .mouse(MouseEvent(button: .middle, kind: .press, column: 0, row: 0, modifiers: []))
        #expect(result.event == expected)
    }

    // MARK: - Scroll Wheel

    @Test("parses scroll up")
    func scrollUp() throws {
        let bytes = sgr(button: 64, col: 1, row: 1)
        let result = try #require(InputEvent.parse(bytes))
        let expected: InputEvent = .mouse(MouseEvent(button: .scrollUp, kind: .press, column: 0, row: 0, modifiers: []))
        #expect(result.event == expected)
    }

    @Test("parses scroll down")
    func scrollDown() throws {
        let bytes = sgr(button: 65, col: 1, row: 1)
        let result = try #require(InputEvent.parse(bytes))
        let expected: InputEvent = .mouse(MouseEvent(button: .scrollDown, kind: .press, column: 0, row: 0, modifiers: []))
        #expect(result.event == expected)
    }

    // MARK: - Modifiers

    @Test("parses shift + left click")
    func shiftClick() throws {
        let bytes = sgr(button: 4, col: 1, row: 1) // 0 + 4 (shift bit)
        let result = try #require(InputEvent.parse(bytes))
        let expected: InputEvent = .mouse(MouseEvent(button: .left, kind: .press, column: 0, row: 0, modifiers: .shift))
        #expect(result.event == expected)
    }

    @Test("parses alt + left click")
    func altClick() throws {
        let bytes = sgr(button: 8, col: 1, row: 1) // 0 + 8 (alt bit)
        let result = try #require(InputEvent.parse(bytes))
        let expected: InputEvent = .mouse(MouseEvent(button: .left, kind: .press, column: 0, row: 0, modifiers: .option))
        #expect(result.event == expected)
    }

    @Test("parses ctrl + left click")
    func ctrlClick() throws {
        let bytes = sgr(button: 16, col: 1, row: 1) // 0 + 16 (ctrl bit)
        let result = try #require(InputEvent.parse(bytes))
        let expected: InputEvent = .mouse(MouseEvent(button: .left, kind: .press, column: 0, row: 0, modifiers: .control))
        #expect(result.event == expected)
    }

    @Test("parses ctrl + shift + right click")
    func ctrlShiftRightClick() throws {
        let bytes = sgr(button: 22, col: 1, row: 1) // 2 + 4 (shift) + 16 (ctrl)
        let result = try #require(InputEvent.parse(bytes))
        let expected: InputEvent = .mouse(MouseEvent(button: .right, kind: .press, column: 0, row: 0, modifiers: [.control, .shift]))
        #expect(result.event == expected)
    }

    // MARK: - Large Coordinates

    @Test("parses large coordinates")
    func largeCoordinates() throws {
        let bytes = sgr(button: 0, col: 200, row: 50)
        let result = try #require(InputEvent.parse(bytes))
        let expected: InputEvent = .mouse(MouseEvent(button: .left, kind: .press, column: 199, row: 49, modifiers: []))
        #expect(result.event == expected)
    }

    // MARK: - Incomplete Sequences

    @Test("incomplete SGR sequence returns unknown key event")
    func incompleteSGR() throws {
        // ESC [ < 0 ; 1 ; 1  (no M/m terminator)
        let bytes: [UInt8] = [0x1B, 0x5B, 0x3C, 0x30, 0x3B, 0x31, 0x3B, 0x31]
        let result = try #require(InputEvent.parse(bytes))
        // Should consume all bytes and return unknown to prevent corruption
        if case .key(.unknown) = result.event {
            #expect(result.consumed == bytes.count)
        } else {
            Issue.record("Expected .key(.unknown) for incomplete SGR sequence, got \(result.event)")
        }
    }

    // MARK: - Fallback to KeyEvent

    @Test("regular character falls through to key parsing")
    func characterFallthrough() throws {
        let result = try #require(InputEvent.parse([0x41])) // 'A'
        #expect(result.event == .key(.character("A")))
        #expect(result.consumed == 1)
    }

    @Test("arrow key falls through to key parsing")
    func arrowFallthrough() throws {
        let bytes: [UInt8] = [0x1B, 0x5B, 0x41] // ESC [ A = up arrow
        let result = try #require(InputEvent.parse(bytes))
        #expect(result.event == .key(.up))
        #expect(result.consumed == 3)
    }

    @Test("enter key falls through to key parsing")
    func enterFallthrough() throws {
        let result = try #require(InputEvent.parse([0x0D])) // CR
        #expect(result.event == .key(.enter))
        #expect(result.consumed == 1)
    }

    // MARK: - Consumed Bytes

    @Test("consumed count matches full SGR sequence length")
    func consumedCount() throws {
        // ESC [ < 65 ; 100 ; 25 M  (multi-digit params)
        let bytes = sgr(button: 65, col: 100, row: 25)
        let result = try #require(InputEvent.parse(bytes))
        #expect(result.consumed == bytes.count)
    }

    @Test("extra bytes after SGR sequence are not consumed")
    func extraBytesNotConsumed() throws {
        let bytes = sgr(button: 0, col: 1, row: 1) + [0x41] // extra 'A' after
        let result = try #require(InputEvent.parse(bytes))
        #expect(result.consumed == bytes.count - 1)
    }
}
