/// A parsed terminal key event.
///
/// Represents all key inputs TextUI handles, including special keys,
/// modifiers, and escape sequences parsed from raw stdin bytes.
///
/// ```swift
/// for await key in keyReader.events {
///     switch key {
///     case .character(let ch): handleChar(ch)
///     case .enter: submit()
///     case .ctrl("c"): quit()
///     default: break
///     }
/// }
/// ```
public enum KeyEvent: Hashable, Equatable, Sendable {
    /// A printable character (may include emoji, unicode).
    case character(Character)

    /// Enter / Return key.
    case enter

    /// Backspace / Delete key.
    case backspace

    /// Tab key.
    case tab

    /// Shift+Tab (reverse tab / backtab).
    case shiftTab

    /// Escape key (standalone, not part of a sequence).
    case escape

    /// Arrow keys.
    case up, down, left, right

    /// Home / End keys.
    case home, end

    /// Page Up / Page Down keys.
    case pageUp, pageDown

    /// Delete (forward delete) key.
    case delete

    /// Function key (F1–F12).
    case function(Int)

    /// Ctrl+key combination.
    case ctrl(Character)

    /// An unrecognized escape sequence.
    case unknown([UInt8])
}

// MARK: - Parsing

extension KeyEvent {
    /// Parses a key event from a buffer of raw bytes read from stdin.
    ///
    /// Returns the parsed event and the number of bytes consumed,
    /// or `nil` if the buffer is empty.
    public static func parse(_ bytes: [UInt8]) -> (event: KeyEvent, consumed: Int)? {
        guard !bytes.isEmpty else { return nil }

        let first = bytes[0]

        // Escape sequences
        if first == 0x1B {
            return parseEscapeSequence(bytes)
        }

        // Ctrl+key (0x01-0x1A, excluding special ones)
        if first >= 0x01, first <= 0x1A {
            switch first {
            case 0x09: return (.tab, 1) // Ctrl+I = Tab
            case 0x0A, 0x0D: return (.enter, 1) // Ctrl+J/M = Enter
            default:
                let char = Character(UnicodeScalar(first + 0x60))
                return (.ctrl(char), 1)
            }
        }

        // Backspace (0x7F)
        if first == 0x7F {
            return (.backspace, 1)
        }

        // Regular UTF-8 character
        let (char, charLen) = parseUTF8Character(bytes)
        if let char {
            return (.character(char), charLen)
        }

        return (.unknown([first]), 1)
    }

    private static func parseEscapeSequence(_ bytes: [UInt8]) -> (event: KeyEvent, consumed: Int) {
        // Standalone escape (no more bytes or timeout)
        guard bytes.count > 1 else {
            return (.escape, 1)
        }

        let second = bytes[1]

        // CSI sequences: ESC [
        if second == 0x5B { // '['
            return parseCSI(bytes)
        }

        // SS3 sequences: ESC O (some terminals use this for arrows/function keys)
        if second == 0x4F { // 'O'
            guard bytes.count > 2 else { return (.escape, 1) }
            switch bytes[2] {
            case 0x41: return (.up, 3) // ESC O A
            case 0x42: return (.down, 3) // ESC O B
            case 0x43: return (.right, 3) // ESC O C
            case 0x44: return (.left, 3) // ESC O D
            case 0x48: return (.home, 3) // ESC O H
            case 0x46: return (.end, 3) // ESC O F
            case 0x50: return (.function(1), 3) // ESC O P = F1
            case 0x51: return (.function(2), 3) // ESC O Q = F2
            case 0x52: return (.function(3), 3) // ESC O R = F3
            case 0x53: return (.function(4), 3) // ESC O S = F4
            default: return (.unknown(Array(bytes[0 ... 2])), 3)
            }
        }

        // Standalone escape followed by something we don't recognize
        return (.escape, 1)
    }

    private static func parseCSI(_ bytes: [UInt8]) -> (event: KeyEvent, consumed: Int) {
        // Minimum CSI sequence: ESC [ <final>
        guard bytes.count > 2 else { return (.escape, 1) }

        // Find the final byte (0x40-0x7E)
        var idx = 2
        while idx < bytes.count, bytes[idx] < 0x40 || bytes[idx] > 0x7E {
            idx += 1
        }

        guard idx < bytes.count else {
            return (.unknown(Array(bytes[0 ..< bytes.count])), bytes.count)
        }

        let finalByte = bytes[idx]
        let consumed = idx + 1
        let params = Array(bytes[2 ..< idx])

        switch finalByte {
        case 0x41: return (.up, consumed) // CSI A
        case 0x42: return (.down, consumed) // CSI B
        case 0x43: return (.right, consumed) // CSI C
        case 0x44: return (.left, consumed) // CSI D
        case 0x48: return (.home, consumed) // CSI H
        case 0x46: return (.end, consumed) // CSI F
        case 0x5A: return (.shiftTab, consumed) // CSI Z (backtab)
        case 0x7E: // CSI <n> ~
            let paramStr = String(bytes: params, encoding: .ascii) ?? ""
            switch paramStr {
            case "3": return (.delete, consumed)
            case "5": return (.pageUp, consumed)
            case "6": return (.pageDown, consumed)
            case "1", "7": return (.home, consumed)
            case "4", "8": return (.end, consumed)
            // Function keys via CSI <n> ~
            case "11": return (.function(1), consumed)
            case "12": return (.function(2), consumed)
            case "13": return (.function(3), consumed)
            case "14": return (.function(4), consumed)
            case "15": return (.function(5), consumed)
            case "17": return (.function(6), consumed)
            case "18": return (.function(7), consumed)
            case "19": return (.function(8), consumed)
            case "20": return (.function(9), consumed)
            case "21": return (.function(10), consumed)
            case "23": return (.function(11), consumed)
            case "24": return (.function(12), consumed)
            default: return (.unknown(Array(bytes[0 ..< consumed])), consumed)
            }
        default:
            return (.unknown(Array(bytes[0 ..< consumed])), consumed)
        }
    }

    private static func parseUTF8Character(_ bytes: [UInt8]) -> (Character?, Int) {
        let first = bytes[0]
        let expectedLength: Int

        if first & 0x80 == 0 {
            expectedLength = 1
        } else if first & 0xE0 == 0xC0 {
            expectedLength = 2
        } else if first & 0xF0 == 0xE0 {
            expectedLength = 3
        } else if first & 0xF8 == 0xF0 {
            expectedLength = 4
        } else {
            return (nil, 1)
        }

        guard bytes.count >= expectedLength else { return (nil, 1) }

        let slice = Array(bytes[0 ..< expectedLength])
        if let str = String(bytes: slice, encoding: .utf8), let char = str.first {
            return (char, expectedLength)
        }
        return (nil, 1)
    }
}
