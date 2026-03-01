import Testing
@testable import TextUI

@Suite("CommandPalette")
struct CommandPaletteTests {
    /// Creates a registry with common test commands.
    private func makeRegistry() -> CommandRegistry {
        let registry = CommandRegistry()
        let group = CommandGroup("File") {
            Button("Save") {}
                .keyboardShortcut("s", modifiers: .control)
            Button("Open") {}
                .keyboardShortcut("o", modifiers: .control)
            Button("Copy") {}
                .keyboardShortcut("c", modifiers: .control)
        }
        registry.register([group])
        registry.isPaletteVisible = true
        return registry
    }

    /// Creates a render context with the given registry.
    private func makeContext(registry: CommandRegistry) -> RenderContext {
        var ctx = RenderContext()
        ctx.commandRegistry = registry
        return ctx
    }

    @Test("Renders border and title")
    func rendersBorderAndTitle() {
        let registry = makeRegistry()
        let ctx = makeContext(registry: registry)

        let palette = CommandPalette()
        var buffer = Buffer(width: 60, height: 20)
        let region = Region(row: 0, col: 0, width: 60, height: 20)
        palette.render(into: &buffer, region: region, context: ctx)

        // Find the top-left corner (╭)
        var foundCorner = false
        var cornerRow = 0
        var cornerCol = 0
        for r in 0 ..< buffer.height {
            for c in 0 ..< buffer.width {
                if buffer[r, c].char == "╭" {
                    foundCorner = true
                    cornerRow = r
                    cornerCol = c
                    break
                }
            }
            if foundCorner { break }
        }
        #expect(foundCorner, "Should find top-left rounded corner")

        // Check title text is present in the top row
        let topRowText = (cornerCol ..< cornerCol + 50).map { String(buffer[cornerRow, $0].char) }.joined()
        #expect(topRowText.contains("Command Palette"))
    }

    @Test("Renders filter text with > prefix")
    func rendersFilterText() {
        let registry = makeRegistry()
        registry.filterText = "sav"
        let ctx = makeContext(registry: registry)

        let palette = CommandPalette()
        var buffer = Buffer(width: 60, height: 20)
        let region = Region(row: 0, col: 0, width: 60, height: 20)
        palette.render(into: &buffer, region: region, context: ctx)

        // Find the filter line by looking for "> "
        var filterRow = -1
        for r in 0 ..< buffer.height {
            let text = (0 ..< buffer.width).map { String(buffer[r, $0].char) }.joined()
            if text.contains("> sav") {
                filterRow = r
                break
            }
        }
        #expect(filterRow >= 0, "Should find filter text with > prefix")
    }

    @Test("Highlights selected entry with inverse style")
    func highlightsSelectedEntry() {
        let registry = makeRegistry()
        registry.selectedIndex = 1 // "Open"
        let ctx = makeContext(registry: registry)

        let palette = CommandPalette()
        var buffer = Buffer(width: 60, height: 20)
        let region = Region(row: 0, col: 0, width: 60, height: 20)
        palette.render(into: &buffer, region: region, context: ctx)

        // Find the row with "▸" (selection indicator)
        var selRow = -1
        for r in 0 ..< buffer.height {
            let text = (0 ..< buffer.width).map { String(buffer[r, $0].char) }.joined()
            if text.contains("▸") {
                selRow = r
                break
            }
        }
        #expect(selRow >= 0, "Should find selection indicator")

        // The selected row should have inverse style on the indicator
        if selRow >= 0 {
            // Find the ▸ column
            for c in 0 ..< buffer.width {
                if buffer[selRow, c].char == "▸" {
                    #expect(buffer[selRow, c].style.inverse, "Selection indicator should be inverse")
                    break
                }
            }
        }
    }

    @Test("Renders shortcut hints right-aligned")
    func rendersShortcutHints() {
        let registry = makeRegistry()
        let ctx = makeContext(registry: registry)

        let palette = CommandPalette()
        var buffer = Buffer(width: 60, height: 20)
        let region = Region(row: 0, col: 0, width: 60, height: 20)
        palette.render(into: &buffer, region: region, context: ctx)

        // Find a row containing "^S" (the Save shortcut)
        var foundShortcut = false
        for r in 0 ..< buffer.height {
            let text = (0 ..< buffer.width).map { String(buffer[r, $0].char) }.joined()
            if text.contains("^S"), text.contains("Save") {
                foundShortcut = true
                // Verify ^S appears to the right of Save
                if let saveRange = text.range(of: "Save"),
                   let shortcutRange = text.range(of: "^S")
                {
                    #expect(shortcutRange.lowerBound > saveRange.lowerBound,
                            "Shortcut should be right of name")
                }
                break
            }
        }
        #expect(foundShortcut, "Should find shortcut hint")
    }

    @Test("Empty filter shows all commands")
    func emptyFilterShowsAll() {
        let registry = makeRegistry()
        // filterText is already empty
        let ctx = makeContext(registry: registry)

        let palette = CommandPalette()
        var buffer = Buffer(width: 60, height: 20)
        let region = Region(row: 0, col: 0, width: 60, height: 20)
        palette.render(into: &buffer, region: region, context: ctx)

        // Should see all three commands: Save, Open, Copy
        var foundSave = false
        var foundOpen = false
        var foundCopy = false
        for r in 0 ..< buffer.height {
            let text = (0 ..< buffer.width).map { String(buffer[r, $0].char) }.joined()
            if text.contains("Save") { foundSave = true }
            if text.contains("Open") { foundOpen = true }
            if text.contains("Copy") { foundCopy = true }
        }
        #expect(foundSave, "Should show Save")
        #expect(foundOpen, "Should show Open")
        #expect(foundCopy, "Should show Copy")
    }

    @Test("No crash with empty registry")
    func noCrashEmptyRegistry() {
        let registry = CommandRegistry()
        registry.isPaletteVisible = true
        let ctx = makeContext(registry: registry)

        let palette = CommandPalette()
        var buffer = Buffer(width: 60, height: 20)
        let region = Region(row: 0, col: 0, width: 60, height: 20)
        palette.render(into: &buffer, region: region, context: ctx)
        // Should not crash; should show "No matches"
        var foundNoMatches = false
        for r in 0 ..< buffer.height {
            let text = (0 ..< buffer.width).map { String(buffer[r, $0].char) }.joined()
            if text.contains("No matches") {
                foundNoMatches = true
                break
            }
        }
        #expect(foundNoMatches, "Should show 'No matches' for empty registry")
    }

    @Test("No crash with tiny region")
    func noCrashTinyRegion() {
        let registry = makeRegistry()
        let ctx = makeContext(registry: registry)

        let palette = CommandPalette()
        var buffer = Buffer(width: 10, height: 3)
        let region = Region(row: 0, col: 0, width: 10, height: 3)
        palette.render(into: &buffer, region: region, context: ctx)
        // Should not crash and should not render anything (too small)
        #expect(buffer[0, 0].char == " ")
    }

    @Test("Separator renders between filter and list")
    func separatorRenders() {
        let registry = makeRegistry()
        let ctx = makeContext(registry: registry)

        let palette = CommandPalette()
        var buffer = Buffer(width: 60, height: 20)
        let region = Region(row: 0, col: 0, width: 60, height: 20)
        palette.render(into: &buffer, region: region, context: ctx)

        // Find ├ (left T-junction of separator)
        var foundSeparator = false
        for r in 0 ..< buffer.height {
            for c in 0 ..< buffer.width {
                if buffer[r, c].char == "├" {
                    // Check the right end has ┤
                    for c2 in stride(from: buffer.width - 1, through: c + 1, by: -1) {
                        if buffer[r, c2].char == "┤" {
                            foundSeparator = true
                            break
                        }
                    }
                    break
                }
            }
            if foundSeparator { break }
        }
        #expect(foundSeparator, "Should find separator with ├ and ┤")
    }

    @Test("Selection clamped to filtered list count")
    func selectionClamped() {
        let registry = makeRegistry()
        registry.filterText = "sav" // Only "Save" matches
        registry.selectedIndex = 5 // Way past end
        let ctx = makeContext(registry: registry)

        let palette = CommandPalette()
        var buffer = Buffer(width: 60, height: 20)
        let region = Region(row: 0, col: 0, width: 60, height: 20)
        // Should not crash even with out-of-range selectedIndex
        palette.render(into: &buffer, region: region, context: ctx)

        // The entry should still render (even if selectedIndex is past the end,
        // it just won't highlight any entry)
        var foundSave = false
        for r in 0 ..< buffer.height {
            let text = (0 ..< buffer.width).map { String(buffer[r, $0].char) }.joined()
            if text.contains("Save") {
                foundSave = true
                break
            }
        }
        #expect(foundSave, "Save should still render")
    }

    @Test("No crash without commandRegistry in context")
    func noCrashWithoutRegistry() {
        let ctx = RenderContext()
        let palette = CommandPalette()
        var buffer = Buffer(width: 60, height: 20)
        let region = Region(row: 0, col: 0, width: 60, height: 20)
        palette.render(into: &buffer, region: region, context: ctx)
        // Should not crash
        #expect(buffer[0, 0].char == " ")
    }
}
