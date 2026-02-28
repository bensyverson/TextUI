/// Double-buffered screen that performs differential flushes.
///
/// Each frame, views render into the back buffer. When ``flush()`` is called,
/// only cells that differ from the front buffer are emitted as ANSI escape
/// sequences, minimizing I/O and preventing flicker.
///
/// `flush()` returns the ANSI string rather than writing to a terminal directly,
/// making the screen fully testable without a real terminal.
public struct Screen: Sendable {
    /// The current (displayed) buffer.
    private var front: Buffer

    /// The next (pending) buffer that views render into.
    public var back: Buffer

    /// The width of the screen in columns.
    public var width: Int {
        front.width
    }

    /// The height of the screen in rows.
    public var height: Int {
        front.height
    }

    public init(width: Int, height: Int) {
        front = Buffer(width: width, height: height)
        back = Buffer(width: width, height: height)
    }

    /// Resize the screen, clearing both buffers.
    public mutating func resize(width: Int, height: Int) {
        front = Buffer(width: width, height: height)
        back = Buffer(width: width, height: height)
    }

    /// Clear the back buffer to prepare for a new frame.
    public mutating func clear() {
        back = Buffer(width: front.width, height: front.height)
    }

    /// Flush changed cells from the back buffer, returning an ANSI escape string.
    ///
    /// Walks cell-by-cell comparing front and back buffers, emitting ANSI
    /// escape sequences only for cells that changed. After flushing, the
    /// back buffer becomes the new front buffer.
    ///
    /// Continuation cells are skipped — the wide character at the preceding
    /// column already occupies both terminal columns when rendered.
    public mutating func flush() -> String {
        let width = back.width
        let height = back.height
        var output = ""
        output.reserveCapacity(width * height)

        var lastStyle: Style = .plain

        for row in 0 ..< height {
            for col in 0 ..< width {
                let backCell = back[row, col]

                // Skip continuation cells — the terminal auto-advances after wide chars
                if backCell.isContinuation { continue }

                let frontCell = front[row, col]
                if backCell == frontCell {
                    continue
                }

                // Position cursor absolutely to avoid drift from wide characters
                output.append("\u{1B}[\(row + 1);\(col + 1)H")

                // Apply style delta
                let styleSeq = backCell.style.ansiSequence(from: lastStyle)
                if !styleSeq.isEmpty {
                    output.append(styleSeq)
                }
                lastStyle = backCell.style

                // Sanitize control characters to prevent cursor displacement
                let ch = backCell.char
                if ch.asciiValue.map({ $0 < 0x20 || $0 == 0x7F }) == true {
                    output.append(" ")
                } else {
                    output.append(String(ch))
                }
            }
        }

        // Reset style at end
        if lastStyle != .plain {
            output.append("\u{1B}[0m")
        }

        // Swap: back becomes front
        front = back

        return output
    }

    /// Force a full redraw by marking all front cells as dirty.
    ///
    /// The next call to ``flush()`` will re-emit every cell.
    public mutating func invalidate() {
        let sentinel = Cell(char: "\u{FFFF}", style: .plain)
        for i in 0 ..< front.cells.count {
            front.cells[i] = sentinel
        }
    }
}
