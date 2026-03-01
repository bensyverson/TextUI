import Testing
@testable import TextUI

@Suite("KeyEvent Parsing")
struct KeyEventTests {
    // MARK: - Printable Characters

    @Test("parses ASCII letter")
    func asciiLetter() throws {
        let result = try #require(KeyEvent.parse([0x41])) // 'A'
        #expect(result.event == .character("A"))
        #expect(result.consumed == 1)
    }

    @Test("parses space character")
    func space() throws {
        let result = try #require(KeyEvent.parse([0x20]))
        #expect(result.event == .character(" "))
        #expect(result.consumed == 1)
    }

    @Test("parses 2-byte UTF-8 character")
    func utf8TwoByte() throws {
        // é = 0xC3 0xA9
        let result = try #require(KeyEvent.parse([0xC3, 0xA9]))
        #expect(result.event == .character("é"))
        #expect(result.consumed == 2)
    }

    @Test("parses 3-byte UTF-8 character")
    func utf8ThreeByte() throws {
        // 你 = 0xE4 0xBD 0xA0
        let result = try #require(KeyEvent.parse([0xE4, 0xBD, 0xA0]))
        #expect(result.event == .character("你"))
        #expect(result.consumed == 3)
    }

    @Test("parses 4-byte UTF-8 character (emoji)")
    func utf8FourByte() throws {
        // 😀 = 0xF0 0x9F 0x98 0x80
        let result = try #require(KeyEvent.parse([0xF0, 0x9F, 0x98, 0x80]))
        #expect(result.event == .character("😀"))
        #expect(result.consumed == 4)
    }

    // MARK: - Special Keys

    @Test("parses enter (CR)")
    func enter() throws {
        let result = try #require(KeyEvent.parse([0x0D]))
        #expect(result.event == .enter)
    }

    @Test("parses enter (LF)")
    func enterLF() throws {
        let result = try #require(KeyEvent.parse([0x0A]))
        #expect(result.event == .enter)
    }

    @Test("parses backspace (0x7F)")
    func backspace() throws {
        let result = try #require(KeyEvent.parse([0x7F]))
        #expect(result.event == .backspace)
    }

    @Test("parses tab")
    func tab() throws {
        let result = try #require(KeyEvent.parse([0x09]))
        #expect(result.event == .tab)
    }

    @Test("parses shift-tab (CSI Z)")
    func shiftTab() throws {
        let result = try #require(KeyEvent.parse([0x1B, 0x5B, 0x5A]))
        #expect(result.event == .shiftTab)
        #expect(result.consumed == 3)
    }

    // MARK: - Ctrl Keys

    @Test("parses Ctrl+A")
    func ctrlA() throws {
        let result = try #require(KeyEvent.parse([0x01]))
        #expect(result.event == .ctrl("a"))
    }

    @Test("parses Ctrl+C")
    func ctrlC() throws {
        let result = try #require(KeyEvent.parse([0x03]))
        #expect(result.event == .ctrl("c"))
    }

    @Test("parses Ctrl+Z")
    func ctrlZ() throws {
        let result = try #require(KeyEvent.parse([0x1A]))
        #expect(result.event == .ctrl("z"))
    }

    // MARK: - Arrow Keys (CSI)

    @Test("parses up arrow (CSI A)")
    func upArrow() throws {
        let result = try #require(KeyEvent.parse([0x1B, 0x5B, 0x41]))
        #expect(result.event == .up)
    }

    @Test("parses down arrow (CSI B)")
    func downArrow() throws {
        let result = try #require(KeyEvent.parse([0x1B, 0x5B, 0x42]))
        #expect(result.event == .down)
    }

    @Test("parses right arrow (CSI C)")
    func rightArrow() throws {
        let result = try #require(KeyEvent.parse([0x1B, 0x5B, 0x43]))
        #expect(result.event == .right)
    }

    @Test("parses left arrow (CSI D)")
    func leftArrow() throws {
        let result = try #require(KeyEvent.parse([0x1B, 0x5B, 0x44]))
        #expect(result.event == .left)
    }

    // MARK: - Arrow Keys (SS3)

    @Test("parses up arrow (SS3 A)")
    func upArrowSS3() throws {
        let result = try #require(KeyEvent.parse([0x1B, 0x4F, 0x41]))
        #expect(result.event == .up)
    }

    @Test("parses down arrow (SS3 B)")
    func downArrowSS3() throws {
        let result = try #require(KeyEvent.parse([0x1B, 0x4F, 0x42]))
        #expect(result.event == .down)
    }

    // MARK: - Navigation Keys

    @Test("parses Home (CSI H)")
    func homeCsiH() throws {
        let result = try #require(KeyEvent.parse([0x1B, 0x5B, 0x48]))
        #expect(result.event == .home)
    }

    @Test("parses End (CSI F)")
    func endCsiF() throws {
        let result = try #require(KeyEvent.parse([0x1B, 0x5B, 0x46]))
        #expect(result.event == .end)
    }

    @Test("parses Home (SS3 H)")
    func homeSS3() throws {
        let result = try #require(KeyEvent.parse([0x1B, 0x4F, 0x48]))
        #expect(result.event == .home)
    }

    @Test("parses End (SS3 F)")
    func endSS3() throws {
        let result = try #require(KeyEvent.parse([0x1B, 0x4F, 0x46]))
        #expect(result.event == .end)
    }

    @Test("parses Page Up (CSI 5~)")
    func pageUp() throws {
        let result = try #require(KeyEvent.parse([0x1B, 0x5B, 0x35, 0x7E]))
        #expect(result.event == .pageUp)
    }

    @Test("parses Page Down (CSI 6~)")
    func pageDown() throws {
        let result = try #require(KeyEvent.parse([0x1B, 0x5B, 0x36, 0x7E]))
        #expect(result.event == .pageDown)
    }

    @Test("parses Delete (CSI 3~)")
    func deleteKey() throws {
        let result = try #require(KeyEvent.parse([0x1B, 0x5B, 0x33, 0x7E]))
        #expect(result.event == .delete)
    }

    // MARK: - Function Keys

    @Test("parses F1 (SS3 P)")
    func f1SS3() throws {
        let result = try #require(KeyEvent.parse([0x1B, 0x4F, 0x50]))
        #expect(result.event == .function(1))
    }

    @Test("parses F2 (SS3 Q)")
    func f2SS3() throws {
        let result = try #require(KeyEvent.parse([0x1B, 0x4F, 0x51]))
        #expect(result.event == .function(2))
    }

    @Test("parses F3 (SS3 R)")
    func f3SS3() throws {
        let result = try #require(KeyEvent.parse([0x1B, 0x4F, 0x52]))
        #expect(result.event == .function(3))
    }

    @Test("parses F4 (SS3 S)")
    func f4SS3() throws {
        let result = try #require(KeyEvent.parse([0x1B, 0x4F, 0x53]))
        #expect(result.event == .function(4))
    }

    @Test("parses F5 (CSI 15~)")
    func f5() throws {
        let bytes: [UInt8] = [0x1B, 0x5B, 0x31, 0x35, 0x7E]
        let result = try #require(KeyEvent.parse(bytes))
        #expect(result.event == .function(5))
    }

    @Test("parses F12 (CSI 24~)")
    func f12() throws {
        let bytes: [UInt8] = [0x1B, 0x5B, 0x32, 0x34, 0x7E]
        let result = try #require(KeyEvent.parse(bytes))
        #expect(result.event == .function(12))
    }

    // MARK: - Escape

    @Test("standalone escape with no more bytes")
    func standaloneEscape() throws {
        let result = try #require(KeyEvent.parse([0x1B]))
        #expect(result.event == .escape)
        #expect(result.consumed == 1)
    }

    // MARK: - Unknown Sequences

    @Test("unknown CSI sequence")
    func unknownCSI() throws {
        // ESC [ 9 9 ~
        let bytes: [UInt8] = [0x1B, 0x5B, 0x39, 0x39, 0x7E]
        let result = try #require(KeyEvent.parse(bytes))
        if case .unknown = result.event {} else {
            Issue.record("Expected .unknown, got \(result.event)")
        }
    }

    // MARK: - Modified Arrow Keys

    @Test("parses Ctrl+Shift+Right (CSI 1;6C)")
    func ctrlShiftRight() throws {
        // ESC [ 1 ; 6 C
        let bytes: [UInt8] = [0x1B, 0x5B, 0x31, 0x3B, 0x36, 0x43]
        let result = try #require(KeyEvent.parse(bytes))
        #expect(result.event == .ctrlShiftRight)
        #expect(result.consumed == 6)
    }

    @Test("parses Ctrl+Shift+Left (CSI 1;6D)")
    func ctrlShiftLeft() throws {
        let bytes: [UInt8] = [0x1B, 0x5B, 0x31, 0x3B, 0x36, 0x44]
        let result = try #require(KeyEvent.parse(bytes))
        #expect(result.event == .ctrlShiftLeft)
        #expect(result.consumed == 6)
    }

    @Test("parses Shift+Right (CSI 1;2C)")
    func shiftRight() throws {
        let bytes: [UInt8] = [0x1B, 0x5B, 0x31, 0x3B, 0x32, 0x43]
        let result = try #require(KeyEvent.parse(bytes))
        #expect(result.event == .shiftRight)
        #expect(result.consumed == 6)
    }

    @Test("parses Ctrl+Up (CSI 1;5A)")
    func ctrlUp() throws {
        let bytes: [UInt8] = [0x1B, 0x5B, 0x31, 0x3B, 0x35, 0x41]
        let result = try #require(KeyEvent.parse(bytes))
        #expect(result.event == .ctrlUp)
        #expect(result.consumed == 6)
    }

    // MARK: - Edge Cases

    @Test("empty buffer returns nil")
    func emptyBuffer() {
        let result = KeyEvent.parse([])
        #expect(result == nil)
    }
}
