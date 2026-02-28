/// A 2D grid of ``Cell``s representing the terminal content.
///
/// Views render into a buffer, which is then flushed to the screen.
/// The buffer supports writing text with styles, filling regions,
/// and drawing box characters. All write operations are display-width-aware:
/// wide characters (emoji, CJK) occupy two cells, with the second marked
/// as a continuation.
public struct Buffer: Sendable {
    /// The width of the buffer in columns.
    public let width: Int

    /// The height of the buffer in rows.
    public let height: Int

    /// The cell data, stored as a flat array in row-major order.
    public var cells: [Cell]

    public init(width: Int, height: Int) {
        self.width = width
        self.height = height
        cells = [Cell](repeating: .blank, count: width * height)
    }

    // MARK: - Cell Access

    /// Get or set the cell at the given row and column.
    ///
    /// Out-of-bounds reads return ``Cell/blank``. Out-of-bounds writes are ignored.
    public subscript(row: Int, col: Int) -> Cell {
        get {
            guard row >= 0, row < height, col >= 0, col < width else { return .blank }
            return cells[row * width + col]
        }
        set {
            guard row >= 0, row < height, col >= 0, col < width else { return }
            cells[row * width + col] = newValue
        }
    }

    // MARK: - Text Writing

    /// Write a string at the given position with a style, clipping to the buffer bounds.
    ///
    /// Returns the number of columns consumed (for cursor tracking).
    /// Wide characters produce a primary cell followed by a continuation cell.
    /// A wide character that would straddle the right edge is replaced with a space.
    @discardableResult
    public mutating func write(
        _ text: String,
        row: Int,
        col: Int,
        style: Style = .plain,
    ) -> Int {
        var c = col
        for char in text {
            let w = char.displayWidth
            guard w > 0 else { continue }

            if w == 2 {
                // Wide character needs 2 columns
                guard c + 1 < width else {
                    // Can't fit — replace with space if in bounds
                    if c >= 0, c < width, row >= 0, row < height {
                        clearWideChar(row: row, col: c)
                        self[row, c] = Cell(char: " ", style: style)
                    }
                    c += 1
                    break
                }
                guard row >= 0, row < height, c >= 0 else {
                    c += 2
                    continue
                }
                clearWideChar(row: row, col: c)
                clearWideChar(row: row, col: c + 1)
                self[row, c] = Cell(char: char, style: style)
                self[row, c + 1] = Cell(char: " ", style: style, isContinuation: true)
                c += 2
            } else {
                // Narrow character
                guard c < width else { break }
                guard row >= 0, row < height, c >= 0 else {
                    c += 1
                    continue
                }
                clearWideChar(row: row, col: c)
                self[row, c] = Cell(char: char, style: style)
                c += 1
            }
        }
        return c - col
    }

    /// Write a string within a region, wrapping at region boundaries.
    ///
    /// Returns the number of rows consumed. Wide characters that don't fit
    /// at the end of a line wrap to the next line.
    @discardableResult
    public mutating func writeWrapping(
        _ text: String,
        in region: Region,
        style: Style = .plain,
    ) -> Int {
        var r = 0
        var c = 0
        for char in text {
            if char == "\n" {
                r += 1
                c = 0
                continue
            }

            let w = char.displayWidth
            guard w > 0 else { continue }
            guard r < region.height else { break }

            if w == 2 {
                // Wide char — check if it fits on this line
                if c + 2 > region.width {
                    // Doesn't fit — wrap to next line
                    r += 1
                    c = 0
                    guard r < region.height else { break }
                }
                let absRow = region.row + r
                let absCol = region.col + c
                clearWideChar(row: absRow, col: absCol)
                clearWideChar(row: absRow, col: absCol + 1)
                self[absRow, absCol] = Cell(char: char, style: style)
                self[absRow, absCol + 1] = Cell(char: " ", style: style, isContinuation: true)
                c += 2
            } else {
                if c >= region.width {
                    r += 1
                    c = 0
                    guard r < region.height else { break }
                }
                let absRow = region.row + r
                let absCol = region.col + c
                clearWideChar(row: absRow, col: absCol)
                self[absRow, absCol] = Cell(char: char, style: style)
                c += 1
            }
        }
        return r + 1
    }

    // MARK: - Region Operations

    /// Fill a region with a character and style.
    public mutating func fill(_ region: Region, char: Character = " ", style: Style = .plain) {
        let cell = Cell(char: char, style: style)
        for r in region.row ..< min(region.row + region.height, height) {
            for c in region.col ..< min(region.col + region.width, width) {
                guard r >= 0, c >= 0 else { continue }
                clearWideChar(row: r, col: c)
                self[r, c] = cell
            }
        }
    }

    /// Draw a horizontal line of a given character.
    public mutating func horizontalLine(
        row: Int,
        col: Int,
        length: Int,
        char: Character = "─",
        style: Style = .plain,
    ) {
        for c in col ..< min(col + length, width) {
            guard row >= 0, row < height, c >= 0 else { continue }
            clearWideChar(row: row, col: c)
            self[row, c] = Cell(char: char, style: style)
        }
    }

    /// Draw a vertical line of a given character.
    public mutating func verticalLine(
        row: Int,
        col: Int,
        length: Int,
        char: Character = "│",
        style: Style = .plain,
    ) {
        for r in row ..< min(row + length, height) {
            guard r >= 0, col >= 0, col < width else { continue }
            clearWideChar(row: r, col: col)
            self[r, col] = Cell(char: char, style: style)
        }
    }

    // MARK: - Private Helpers

    /// Clean up wide character artifacts when overwriting a cell.
    ///
    /// If the cell at `(row, col)` is a continuation, blanks the preceding primary.
    /// If the next cell is a continuation of this cell, blanks it.
    private mutating func clearWideChar(row: Int, col: Int) {
        guard row >= 0, row < height, col >= 0, col < width else { return }

        // If we're overwriting a continuation cell, blank the preceding primary
        if self[row, col].isContinuation, col > 0 {
            cells[row * width + col - 1] = .blank
        }

        // If the next cell is a continuation (meaning this cell is the primary
        // of a wide char), blank the continuation
        if col + 1 < width, self[row, col + 1].isContinuation {
            cells[row * width + col + 1] = .blank
        }
    }
}
