import Testing
@testable import TextUI

@Suite("Style")
struct StyleTests {
    @Test("Plain style has no attributes")
    func plainStyle() {
        let style = Style.plain
        #expect(style.fg == nil)
        #expect(style.bg == nil)
        #expect(!style.bold)
        #expect(!style.dim)
        #expect(!style.italic)
        #expect(!style.underline)
        #expect(!style.inverse)
        #expect(!style.strikethrough)
    }

    @Test("Static convenience styles")
    func staticStyles() {
        #expect(Style.bold.bold)
        #expect(Style.dim.dim)
        #expect(Style.italic.italic)
    }

    @Test("Builder methods return modified copies")
    func builderMethods() {
        let base = Style.plain
        #expect(base.foreground(.red).fg == .red)
        #expect(base.background(.blue).bg == .blue)
        #expect(base.bolded().bold)
        #expect(base.dimmed().dim)
        #expect(base.italicized().italic)
        #expect(base.underlined().underline)
        #expect(base.inversed().inverse)
        #expect(base.struckthrough().strikethrough)
    }

    @Test("Builder methods chain correctly")
    func builderChaining() {
        let style = Style.plain
            .foreground(.red)
            .background(.blue)
            .bolded()
            .italicized()
        #expect(style.fg == .red)
        #expect(style.bg == .blue)
        #expect(style.bold)
        #expect(style.italic)
        #expect(!style.dim)
    }

    @Test("ANSI sequence from plain is empty")
    func ansiPlainToPlain() {
        #expect(Style.plain.ansiSequence(from: Style.plain) == "")
    }

    @Test("ANSI sequence for bold")
    func ansiBold() {
        let seq = Style.bold.ansiSequence()
        #expect(seq == "\u{1B}[1m")
    }

    @Test("ANSI sequence for foreground color")
    func ansiForeground() {
        let style = Style(fg: .red)
        let seq = style.ansiSequence()
        #expect(seq == "\u{1B}[31m")
    }

    @Test("ANSI sequence for RGB color")
    func ansiRGB() {
        let style = Style(fg: .rgb(255, 128, 0))
        let seq = style.ansiSequence()
        #expect(seq == "\u{1B}[38;2;255;128;0m")
    }

    @Test("ANSI sequence for palette color")
    func ansiPalette() {
        let style = Style(fg: .palette(208))
        let seq = style.ansiSequence()
        #expect(seq == "\u{1B}[38;5;208m")
    }

    @Test("Differential ANSI only emits changes")
    func ansiDifferential() {
        let prev = Style(fg: .red, bold: true)
        let next = Style(fg: .red, bold: true, italic: true)
        let seq = next.ansiSequence(from: prev)
        #expect(seq == "\u{1B}[3m")
    }

    @Test("Reset emitted when removing attributes")
    func ansiReset() {
        let prev = Style(bold: true)
        let next = Style.plain
        let seq = next.ansiSequence(from: prev)
        #expect(seq.contains("\u{1B}[0m"))
    }

    @Test("Equality")
    func equality() {
        #expect(Style.plain == Style.plain)
        #expect(Style.bold == Style(bold: true))
        #expect(Style.plain != Style.bold)
        #expect(Style(fg: .red) != Style(fg: .blue))
    }

    @Test("Color equality")
    func colorEquality() {
        #expect(Style.Color.red == Style.Color.red)
        #expect(Style.Color.red != Style.Color.blue)
        #expect(Style.Color.palette(42) == Style.Color.palette(42))
        #expect(Style.Color.palette(42) != Style.Color.palette(43))
        #expect(Style.Color.rgb(1, 2, 3) == Style.Color.rgb(1, 2, 3))
        #expect(Style.Color.rgb(1, 2, 3) != Style.Color.rgb(1, 2, 4))
    }

    @Test("Background color codes")
    func backgroundCodes() {
        let style = Style(bg: .green)
        let seq = style.ansiSequence()
        #expect(seq == "\u{1B}[42m")
    }

    @Test("Multiple attributes combined")
    func multipleAttributes() {
        let style = Style(fg: .cyan, bold: true, underline: true)
        let seq = style.ansiSequence()
        #expect(seq.contains("1"))
        #expect(seq.contains("4"))
        #expect(seq.contains("36"))
    }

    // MARK: - Merging

    @Test("Merging bold into plain adds bold")
    func mergingBold() {
        let result = Style.plain.merging(Style(bold: true))
        #expect(result.bold)
        #expect(result.fg == nil)
    }

    @Test("Merging fg color into bold preserves bold")
    func mergingFgPreservesBold() {
        let base = Style(bold: true)
        let result = base.merging(Style(fg: .red))
        #expect(result.bold)
        #expect(result.fg == .red)
    }

    @Test("Merging override fg replaces base fg")
    func mergingOverrideFg() {
        let base = Style(fg: .blue)
        let result = base.merging(Style(fg: .red))
        #expect(result.fg == .red)
    }

    @Test("Merging nil fg preserves base fg")
    func mergingNilFgPreservesBase() {
        let base = Style(fg: .blue)
        let result = base.merging(Style(bold: true))
        #expect(result.fg == .blue)
        #expect(result.bold)
    }

    @Test("Merging ORs all boolean attributes")
    func mergingORsBooleans() {
        let base = Style(bold: true, italic: true)
        let override = Style(dim: true, underline: true)
        let result = base.merging(override)
        #expect(result.bold)
        #expect(result.italic)
        #expect(result.dim)
        #expect(result.underline)
    }

    @Test("Merging preserves bg when override bg is nil")
    func mergingPreservesBg() {
        let base = Style(bg: .green)
        let result = base.merging(Style(bold: true))
        #expect(result.bg == .green)
    }

    @Test("Merging override bg replaces base bg")
    func mergingOverrideBg() {
        let base = Style(bg: .green)
        let result = base.merging(Style(bg: .red))
        #expect(result.bg == .red)
    }

    @Test("Merging two plain styles is plain")
    func mergingPlainIsPlain() {
        let result = Style.plain.merging(.plain)
        #expect(result == .plain)
    }
}
