import Testing
@testable import TextUI

@MainActor
@Suite("CommandBar")
struct CommandBarTests {
    @Test("Sizing: height 1, greedy width")
    func sizing() {
        let bar = CommandBar()
        let size = bar.sizeThatFits(SizeProposal(width: 80, height: 24))
        #expect(size == Size2D(width: 80, height: 1))
    }

    @Test("Sizing with nil width returns zero")
    func sizingNilWidth() {
        let bar = CommandBar()
        let size = bar.sizeThatFits(SizeProposal(width: nil, height: 24))
        #expect(size == Size2D(width: 0, height: 0))
    }

    @Test("Renders shortcut and name for entries")
    func rendersEntries() {
        let registry = CommandRegistry()
        let group = CommandGroup("File") {
            Button("Save") {}
                .keyboardShortcut("s", modifiers: .control)
        }
        registry.register([group])

        var ctx = RenderContext()
        ctx.commandRegistry = registry

        let bar = CommandBar()
        var buffer = Buffer(width: 20, height: 1)
        let region = Region(row: 0, col: 0, width: 20, height: 1)
        bar.render(into: &buffer, region: region, context: ctx)

        // "^S" should be at start
        #expect(buffer[0, 0].char == "^")
        #expect(buffer[0, 1].char == "S")
        // Shortcut should have bold+inverse style
        #expect(buffer[0, 0].style.bold)
        #expect(buffer[0, 0].style.inverse)
        // " Save" should follow
        #expect(buffer[0, 2].char == " ")
        #expect(buffer[0, 3].char == "S")
        #expect(buffer[0, 4].char == "a")
        // Name should be dim
        #expect(buffer[0, 3].style.dim)
    }

    @Test("Group filtering")
    func groupFiltering() {
        let registry = CommandRegistry()
        let fileGroup = CommandGroup("File") {
            Button("Save") {}
                .keyboardShortcut("s", modifiers: .control)
        }
        let editGroup = CommandGroup("Edit") {
            Button("Copy") {}
                .keyboardShortcut("c", modifiers: .control)
        }
        registry.register([fileGroup, editGroup])

        var ctx = RenderContext()
        ctx.commandRegistry = registry

        // Only show File group
        let bar = CommandBar(groups: ["File"])
        var buffer = Buffer(width: 40, height: 1)
        let region = Region(row: 0, col: 0, width: 40, height: 1)
        bar.render(into: &buffer, region: region, context: ctx)

        // "^S" for Save should appear
        #expect(buffer[0, 0].char == "^")
        #expect(buffer[0, 1].char == "S")

        // "^C" for Copy should NOT appear — check that remaining area is empty
        let text = (0 ..< 40).map { String(buffer[0, $0].char) }.joined().trimmingCharacters(in: .whitespaces)
        #expect(!text.contains("Copy"))
    }

    @Test("Truncation at entry boundary")
    func truncation() {
        let registry = CommandRegistry()
        let group = CommandGroup("File") {
            Button("Save") {}
                .keyboardShortcut("s", modifiers: .control)
            Button("Open") {}
                .keyboardShortcut("o", modifiers: .control)
        }
        registry.register([group])

        var ctx = RenderContext()
        ctx.commandRegistry = registry

        // Width only enough for first entry: "^S Save" = 7 chars
        let bar = CommandBar()
        var buffer = Buffer(width: 8, height: 1)
        let region = Region(row: 0, col: 0, width: 8, height: 1)
        bar.render(into: &buffer, region: region, context: ctx)

        // First entry fits
        #expect(buffer[0, 0].char == "^")
        // Second entry should NOT partially render
        // "^S Save" = 7 chars, next entry needs gap(2) + "^O Open"(7) = 16 total
        #expect(buffer[0, 7].char == " ") // blank, not partial
    }

    @Test("Empty registry renders nothing")
    func emptyRegistry() {
        let registry = CommandRegistry()
        var ctx = RenderContext()
        ctx.commandRegistry = registry

        let bar = CommandBar()
        var buffer = Buffer(width: 20, height: 1)
        let region = Region(row: 0, col: 0, width: 20, height: 1)
        bar.render(into: &buffer, region: region, context: ctx)

        // All spaces
        for col in 0 ..< 20 {
            #expect(buffer[0, col].char == " ")
        }
    }

    @Test("No crash without commandRegistry in context")
    func noCrashWithoutRegistry() {
        let ctx = RenderContext()
        let bar = CommandBar()
        var buffer = Buffer(width: 20, height: 1)
        let region = Region(row: 0, col: 0, width: 20, height: 1)
        bar.render(into: &buffer, region: region, context: ctx)
        // Should render nothing without crashing
        #expect(buffer[0, 0].char == " ")
    }

    @Test("Entries without shortcuts are skipped")
    func entriesWithoutShortcutsSkipped() {
        let registry = CommandRegistry()
        let group = CommandGroup("File") {
            Button("About") {}
            Button("Save") {}
                .keyboardShortcut("s", modifiers: .control)
        }
        registry.register([group])

        var ctx = RenderContext()
        ctx.commandRegistry = registry

        let bar = CommandBar()
        var buffer = Buffer(width: 30, height: 1)
        let region = Region(row: 0, col: 0, width: 30, height: 1)
        bar.render(into: &buffer, region: region, context: ctx)

        // "About" has no shortcut so should not appear
        // "^S Save" should appear
        #expect(buffer[0, 0].char == "^")
        #expect(buffer[0, 1].char == "S")
    }
}
