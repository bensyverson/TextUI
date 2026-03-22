extension InputEvent {
    /// Parses an input event from raw terminal bytes.
    ///
    /// Detects SGR extended mouse sequences (`ESC [ <`) and parses them
    /// into ``MouseEvent`` values. All other input falls through to
    /// ``KeyEvent/parse(_:)``.
    ///
    /// - Parameter bytes: Raw bytes read from stdin.
    /// - Returns: The parsed event and the number of bytes consumed,
    ///   or `nil` if the buffer is empty.
    public static func parse(_ bytes: [UInt8]) -> (event: InputEvent, consumed: Int)? {
        guard !bytes.isEmpty else { return nil }

        // Check for SGR mouse sequence: ESC [ <
        if bytes.count >= 3, bytes[0] == 0x1B, bytes[1] == 0x5B, bytes[2] == 0x3C {
            return parseSGRMouse(bytes)
        }

        // Fall back to key event parsing
        guard let result = KeyEvent.parse(bytes) else { return nil }
        return (.key(result.event), result.consumed)
    }

    /// Parses an SGR extended mouse sequence.
    ///
    /// Format: `ESC [ < Cb ; Cx ; Cy M` (press) or `ESC [ < Cb ; Cx ; Cy m` (release)
    ///
    /// - `Cb`: Button code with modifier bits (decimal ASCII digits)
    /// - `Cx`: Column, 1-based (decimal ASCII digits)
    /// - `Cy`: Row, 1-based (decimal ASCII digits)
    /// - `M` (0x4D): Press event
    /// - `m` (0x6D): Release event
    ///
    /// Modifier bits in `Cb`: bit 2 = Shift, bit 3 = Alt/Option, bit 4 = Control.
    /// Button identity: `(Cb & 0x03) | (Cb & 0xC0)`.
    private static func parseSGRMouse(_ bytes: [UInt8]) -> (event: InputEvent, consumed: Int) {
        // Find the terminator: M (0x4D) or m (0x6D)
        var terminatorIndex: Int?
        for i in 3 ..< bytes.count {
            if bytes[i] == 0x4D || bytes[i] == 0x6D {
                terminatorIndex = i
                break
            }
        }

        guard let termIdx = terminatorIndex else {
            // Incomplete sequence — consume all bytes as unknown to prevent corruption
            return (.key(.unknown(Array(bytes))), bytes.count)
        }

        let consumed = termIdx + 1
        let kind: MouseEvent.Kind = bytes[termIdx] == 0x4D ? .press : .release

        // Extract the parameter string between '<' and the terminator
        let paramBytes = bytes[3 ..< termIdx]
        let paramString = String(bytes: paramBytes, encoding: .ascii) ?? ""
        let parts = paramString.split(separator: ";", maxSplits: 2)

        guard parts.count == 3,
              let cb = Int(parts[0]),
              let cx = Int(parts[1]),
              let cy = Int(parts[2])
        else {
            // Malformed parameters — return as unknown
            return (.key(.unknown(Array(bytes[0 ..< consumed]))), consumed)
        }

        // Decode button: bits 0-1 and bits 6-7
        let rawButton = (cb & 0x03) | (cb & 0xC0)

        // Decode modifiers: bit 2 = shift, bit 3 = alt/option, bit 4 = control
        var modifiers = EventModifiers()
        if cb & 4 != 0 { modifiers.insert(.shift) }
        if cb & 8 != 0 { modifiers.insert(.option) }
        if cb & 16 != 0 { modifiers.insert(.control) }

        guard let button = MouseEvent.Button(rawValue: rawButton) else {
            // Unknown button code — return as unknown
            return (.key(.unknown(Array(bytes[0 ..< consumed]))), consumed)
        }

        let event = MouseEvent(
            button: button,
            kind: kind,
            column: cx - 1, // Convert from 1-based to 0-based
            row: cy - 1,
            modifiers: modifiers,
        )

        return (.mouse(event), consumed)
    }
}
