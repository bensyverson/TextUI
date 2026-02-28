import Testing
@testable import TextUI

@Suite("Buffer")
struct BufferTests {
    // MARK: - Initialization

    @Test("Buffer initializes with blank cells")
    func initBlank() {
        let buf = Buffer(width: 5, height: 3)
        #expect(buf.width == 5)
        #expect(buf.height == 3)
        for r in 0 ..< 3 {
            for c in 0 ..< 5 {
                #expect(buf[r, c] == .blank)
            }
        }
    }

    // MARK: - Subscript

    @Test("Out-of-bounds read returns blank")
    func oobRead() {
        let buf = Buffer(width: 3, height: 3)
        #expect(buf[-1, 0] == .blank)
        #expect(buf[0, -1] == .blank)
        #expect(buf[3, 0] == .blank)
        #expect(buf[0, 3] == .blank)
    }

    @Test("Out-of-bounds write is ignored")
    func oobWrite() {
        var buf = Buffer(width: 3, height: 3)
        buf[-1, 0] = Cell(char: "X")
        buf[0, 3] = Cell(char: "X")
        // Should not crash and all cells remain blank
        for r in 0 ..< 3 {
            for c in 0 ..< 3 {
                #expect(buf[r, c] == .blank)
            }
        }
    }

    // MARK: - Write ASCII

    @Test("Write ASCII string")
    func writeASCII() {
        var buf = Buffer(width: 10, height: 1)
        buf.write("Hello", row: 0, col: 0)
        #expect(buf.text == "Hello")
    }

    @Test("Write with style")
    func writeWithStyle() {
        var buf = Buffer(width: 5, height: 1)
        buf.write("Hi", row: 0, col: 0, style: .bold)
        #expect(buf[0, 0].char == "H")
        #expect(buf[0, 0].style == .bold)
        #expect(buf[0, 1].char == "i")
        #expect(buf[0, 1].style == .bold)
    }

    @Test("Write clips at right edge")
    func writeClipsRight() {
        var buf = Buffer(width: 3, height: 1)
        let consumed = buf.write("Hello", row: 0, col: 0)
        #expect(consumed == 3)
        #expect(buf.text == "Hel")
    }

    @Test("Write at column offset")
    func writeAtOffset() {
        var buf = Buffer(width: 10, height: 1)
        buf.write("AB", row: 0, col: 3)
        #expect(buf[0, 3].char == "A")
        #expect(buf[0, 4].char == "B")
    }

    // MARK: - Wide Characters

    @Test("Write wide CJK character creates primary + continuation")
    func writeCJK() {
        var buf = Buffer(width: 10, height: 1)
        buf.write("你", row: 0, col: 0)
        #expect(buf[0, 0].char == "你")
        #expect(!buf[0, 0].isContinuation)
        #expect(buf[0, 1].isContinuation)
    }

    @Test("Write emoji creates primary + continuation")
    func writeEmoji() {
        var buf = Buffer(width: 10, height: 1)
        buf.write("👋", row: 0, col: 0)
        #expect(buf[0, 0].char == "👋")
        #expect(buf[0, 1].isContinuation)
    }

    @Test("Wide char at last column replaced with space")
    func wideCharAtLastColumn() {
        var buf = Buffer(width: 3, height: 1)
        buf.write("你", row: 0, col: 2)
        // Can't fit — should be replaced with space
        #expect(buf[0, 2].char == " ")
        #expect(!buf[0, 2].isContinuation)
    }

    @Test("Mixed ASCII and CJK string")
    func mixedASCIICJK() {
        var buf = Buffer(width: 10, height: 1)
        buf.write("A你B", row: 0, col: 0)
        #expect(buf.text == "A你B")
        #expect(buf[0, 0].char == "A")
        #expect(buf[0, 1].char == "你")
        #expect(buf[0, 2].isContinuation)
        #expect(buf[0, 3].char == "B")
    }

    @Test("Mixed ASCII and emoji string")
    func mixedASCIIEmoji() {
        var buf = Buffer(width: 10, height: 1)
        buf.write("Hi👋!", row: 0, col: 0)
        #expect(buf.text == "Hi👋!")
    }

    // MARK: - Overwrite Cleanup

    @Test("Narrow char overwriting continuation blanks preceding primary")
    func narrowOverwritesContinuation() {
        var buf = Buffer(width: 10, height: 1)
        buf.write("你", row: 0, col: 0)
        // Now overwrite the continuation cell at col 1
        buf.write("X", row: 0, col: 1)
        // The primary at col 0 should be blanked
        #expect(buf[0, 0].char == " ")
        #expect(buf[0, 1].char == "X")
    }

    @Test("Narrow char overwriting primary of wide blanks continuation")
    func narrowOverwritesPrimary() {
        var buf = Buffer(width: 10, height: 1)
        buf.write("你", row: 0, col: 0)
        // Now overwrite the primary cell at col 0
        buf.write("X", row: 0, col: 0)
        // The continuation at col 1 should be blanked
        #expect(buf[0, 0].char == "X")
        #expect(buf[0, 1].char == " ")
        #expect(!buf[0, 1].isContinuation)
    }

    @Test("Wide char overwriting two adjacent wide chars")
    func wideOverwritesWide() {
        var buf = Buffer(width: 10, height: 1)
        buf.write("你好", row: 0, col: 0)
        // "你" at [0,0]+[0,1], "好" at [0,2]+[0,3]
        // Now write a wide char at col 1 — overlaps continuation of 你 and primary of 好
        buf.write("世", row: 0, col: 1)
        // Col 0: was primary of 你, continuation was overwritten → should be blanked
        #expect(buf[0, 0].char == " ")
        // Col 1: new primary 世
        #expect(buf[0, 1].char == "世")
        // Col 2: continuation of 世
        #expect(buf[0, 2].isContinuation)
        // Col 3: was continuation of 好, primary was overwritten → should be blanked
        #expect(buf[0, 3].char == " ")
        #expect(!buf[0, 3].isContinuation)
    }

    // MARK: - buffer.text

    @Test("text skips continuation cells")
    func textSkipsContinuations() {
        var buf = Buffer(width: 10, height: 1)
        buf.write("你好", row: 0, col: 0)
        #expect(buf.text == "你好")
    }

    @Test("text trims trailing spaces per row")
    func textTrimsTrailingSpaces() {
        var buf = Buffer(width: 10, height: 2)
        buf.write("Hi", row: 0, col: 0)
        buf.write("AB", row: 1, col: 0)
        #expect(buf.text == "Hi\nAB")
    }

    @Test("text trims trailing empty rows")
    func textTrimsTrailingRows() {
        var buf = Buffer(width: 10, height: 5)
        buf.write("Hi", row: 0, col: 0)
        #expect(buf.text == "Hi")
    }

    // MARK: - Fill

    @Test("Fill region with character")
    func fillRegion() {
        var buf = Buffer(width: 5, height: 3)
        let region = Region(row: 0, col: 0, width: 3, height: 2)
        buf.fill(region, char: "#")
        #expect(buf[0, 0].char == "#")
        #expect(buf[0, 2].char == "#")
        #expect(buf[1, 2].char == "#")
        #expect(buf[0, 3].char == " ") // outside region
        #expect(buf[2, 0].char == " ") // outside region
    }

    // MARK: - Lines

    @Test("Horizontal line")
    func horizontalLine() {
        var buf = Buffer(width: 5, height: 1)
        buf.horizontalLine(row: 0, col: 1, length: 3)
        #expect(buf[0, 0].char == " ")
        #expect(buf[0, 1].char == "─")
        #expect(buf[0, 2].char == "─")
        #expect(buf[0, 3].char == "─")
        #expect(buf[0, 4].char == " ")
    }

    @Test("Vertical line")
    func verticalLine() {
        var buf = Buffer(width: 1, height: 5)
        buf.verticalLine(row: 1, col: 0, length: 3)
        #expect(buf[0, 0].char == " ")
        #expect(buf[1, 0].char == "│")
        #expect(buf[2, 0].char == "│")
        #expect(buf[3, 0].char == "│")
        #expect(buf[4, 0].char == " ")
    }

    // MARK: - Write Wrapping

    @Test("Write wrapping within region")
    func writeWrapping() {
        var buf = Buffer(width: 10, height: 5)
        let region = Region(row: 0, col: 0, width: 3, height: 3)
        let rows = buf.writeWrapping("ABCDEF", in: region)
        #expect(rows == 2)
        #expect(buf[0, 0].char == "A")
        #expect(buf[0, 1].char == "B")
        #expect(buf[0, 2].char == "C")
        #expect(buf[1, 0].char == "D")
        #expect(buf[1, 1].char == "E")
        #expect(buf[1, 2].char == "F")
    }

    @Test("Write wrapping with wide characters")
    func writeWrappingWide() {
        var buf = Buffer(width: 10, height: 5)
        let region = Region(row: 0, col: 0, width: 4, height: 3)
        buf.writeWrapping("你好世", in: region)
        // "你" takes 2 cols, "好" takes 2 cols → fills row 0
        // "世" wraps to row 1
        #expect(buf[0, 0].char == "你")
        #expect(buf[0, 1].isContinuation)
        #expect(buf[0, 2].char == "好")
        #expect(buf[0, 3].isContinuation)
        #expect(buf[1, 0].char == "世")
        #expect(buf[1, 1].isContinuation)
    }

    @Test("Write wrapping handles newlines")
    func writeWrappingNewlines() {
        var buf = Buffer(width: 10, height: 5)
        let region = Region(row: 0, col: 0, width: 5, height: 3)
        let rows = buf.writeWrapping("AB\nCD", in: region)
        #expect(rows == 2)
        #expect(buf[0, 0].char == "A")
        #expect(buf[0, 1].char == "B")
        #expect(buf[1, 0].char == "C")
        #expect(buf[1, 1].char == "D")
    }

    @Test("Write wrapping wide char that doesn't fit at end of line wraps")
    func writeWrappingWideAtEdge() {
        var buf = Buffer(width: 10, height: 5)
        // Region is 3 cols wide — a wide char at col 2 won't fit
        let region = Region(row: 0, col: 0, width: 3, height: 3)
        buf.writeWrapping("A你B", in: region)
        // 'A' at (0,0), '你' needs 2 cols but only 2 remain at col 1 — fits
        // Wait: col 1 and col 2 = 2 cols, wide char needs 2, so it fits
        #expect(buf[0, 0].char == "A")
        #expect(buf[0, 1].char == "你")
        #expect(buf[0, 2].isContinuation)
        #expect(buf[1, 0].char == "B")
    }
}
