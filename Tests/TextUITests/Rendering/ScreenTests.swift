import Testing
@testable import TextUI

@Suite("Screen")
struct ScreenTests {
    @Test("Initial flush emits all non-blank cells")
    func initialFlush() {
        var screen = Screen(width: 5, height: 1)
        screen.back.write("Hi", row: 0, col: 0)
        let output = screen.flush()
        #expect(output.contains("H"))
        #expect(output.contains("i"))
    }

    @Test("Second flush with no changes returns empty string")
    func noChangesEmpty() {
        var screen = Screen(width: 5, height: 1)
        screen.back.write("Hi", row: 0, col: 0)
        _ = screen.flush()

        // Re-render same content
        screen.clear()
        screen.back.write("Hi", row: 0, col: 0)
        let output = screen.flush()
        #expect(output == "")
    }

    @Test("Differential flush emits only changed cells")
    func differentialFlush() {
        var screen = Screen(width: 5, height: 1)
        screen.back.write("Hello", row: 0, col: 0)
        _ = screen.flush()

        screen.clear()
        screen.back.write("Hallo", row: 0, col: 0)
        let output = screen.flush()
        // Only 'a' at col 1 changed — should have exactly one cursor position command
        #expect(output.contains("a"))
        let positionCount = output.components(separatedBy: "\u{1B}[").count - 1
        #expect(positionCount == 1)
    }

    @Test("Continuation cells are skipped in flush")
    func continuationSkipped() {
        var screen = Screen(width: 10, height: 1)
        screen.back.write("你", row: 0, col: 0)
        let output = screen.flush()
        // The output should contain the character once, not emit anything for the continuation
        let charCount = output.count(where: { $0 == "你" })
        #expect(charCount == 1)
    }

    @Test("Resize clears both buffers")
    func resizeClearsBuffers() {
        var screen = Screen(width: 5, height: 5)
        screen.back.write("Hi", row: 0, col: 0)
        _ = screen.flush()

        screen.resize(width: 10, height: 3)
        #expect(screen.width == 10)
        #expect(screen.height == 3)
        // After resize, flushing blank to blank should produce empty
        let output = screen.flush()
        #expect(output == "")
    }

    @Test("Invalidate forces full redraw")
    func invalidateForcesFull() {
        var screen = Screen(width: 5, height: 1)
        screen.back.write("Hello", row: 0, col: 0)
        _ = screen.flush()

        // Same content, but invalidate
        screen.clear()
        screen.back.write("Hello", row: 0, col: 0)
        screen.invalidate()
        let output = screen.flush()
        // Should re-emit everything
        #expect(output.contains("H"))
        #expect(output.contains("e"))
        #expect(output.contains("l"))
        #expect(output.contains("o"))
    }

    @Test("Width and height properties")
    func dimensionProperties() {
        let screen = Screen(width: 80, height: 24)
        #expect(screen.width == 80)
        #expect(screen.height == 24)
    }

    @Test("Clear resets back buffer")
    func clearResetsBack() {
        var screen = Screen(width: 5, height: 1)
        screen.back.write("Hi", row: 0, col: 0)
        screen.clear()
        #expect(screen.back[0, 0] == .blank)
        #expect(screen.back[0, 1] == .blank)
    }

    @Test("Styled output includes ANSI sequences")
    func styledOutput() {
        var screen = Screen(width: 5, height: 1)
        screen.back.write("Hi", row: 0, col: 0, style: .bold)
        let output = screen.flush()
        // Should contain bold ANSI code
        #expect(output.contains("\u{1B}[1m"))
    }

    @Test("Style reset emitted at end when styled")
    func styleReset() {
        var screen = Screen(width: 5, height: 1)
        screen.back.write("X", row: 0, col: 0, style: .bold)
        let output = screen.flush()
        #expect(output.hasSuffix("\u{1B}[0m"))
    }

    @Test("No style reset when only plain cells")
    func noResetWhenPlain() {
        var screen = Screen(width: 5, height: 1)
        screen.back.write("X", row: 0, col: 0)
        let output = screen.flush()
        #expect(!output.contains("\u{1B}[0m"))
    }
}
