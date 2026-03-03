import Testing
@testable import TextUI

/// Mutable flag for use in test closures.
private final class Flag {
    var value: Bool = false
}

@MainActor
@Suite("Keyboard Shortcut Discovery")
struct KeyboardShortcutDiscoveryTests {
    @Test("Discovery registers shortcut when wrapping a Button")
    func discoveryRegistersButton() {
        let fired = Flag()
        let registry = CommandRegistry()
        var ctx = RenderContext()
        ctx.commandRegistry = registry

        let view = KeyboardShortcutView(
            content: Button("Quit") { fired.value = true },
            shortcut: KeyboardShortcut("q", modifiers: .control),
        )

        var buffer = Buffer(width: 10, height: 1)
        let region = Region(row: 0, col: 0, width: 10, height: 1)
        view.render(into: &buffer, region: region, context: ctx)

        #expect(registry.discoveredEntries.count == 1)
        #expect(registry.discoveredEntries[0].name == "Quit")
        #expect(registry.discoveredEntries[0].group == "Shortcuts")
        #expect(registry.discoveredEntries[0].shortcut == KeyboardShortcut("q", modifiers: .control))

        // Action should be callable
        registry.discoveredEntries[0].action()
        #expect(fired.value)
    }

    @Test("beginDiscovery clears previous discovered entries")
    func beginDiscoveryClearsPrevious() {
        let registry = CommandRegistry()
        var ctx = RenderContext()
        ctx.commandRegistry = registry

        let view = KeyboardShortcutView(
            content: Button("Test") {},
            shortcut: KeyboardShortcut("t", modifiers: .control),
        )

        var buffer = Buffer(width: 10, height: 1)
        let region = Region(row: 0, col: 0, width: 10, height: 1)
        view.render(into: &buffer, region: region, context: ctx)
        #expect(registry.discoveredEntries.count == 1)

        registry.beginDiscovery()
        #expect(registry.discoveredEntries.isEmpty)
    }

    @Test("Static group shortcuts take priority over discovered ones")
    func staticPriorityOverDiscovered() {
        let staticFired = Flag()
        let discoveredFired = Flag()

        let registry = CommandRegistry()
        let group = CommandGroup("File") {
            Button("StaticQuit") { staticFired.value = true }
                .keyboardShortcut("q", modifiers: .control)
        }
        registry.register([group])

        var ctx = RenderContext()
        ctx.commandRegistry = registry

        let view = KeyboardShortcutView(
            content: Button("DiscoveredQuit") { discoveredFired.value = true },
            shortcut: KeyboardShortcut("q", modifiers: .control),
        )

        var buffer = Buffer(width: 20, height: 1)
        let region = Region(row: 0, col: 0, width: 20, height: 1)
        view.render(into: &buffer, region: region, context: ctx)

        // Both should exist
        #expect(registry.allEntries.count == 2)

        // matchShortcut should return the static one
        let matched = registry.matchShortcut(.ctrl("q"))
        #expect(matched?.name == "StaticQuit")

        matched?.action()
        #expect(staticFired.value)
        #expect(!discoveredFired.value)
    }

    @Test("Non-Button content does not register a shortcut")
    func nonButtonContentSkipped() {
        let registry = CommandRegistry()
        var ctx = RenderContext()
        ctx.commandRegistry = registry

        let view = KeyboardShortcutView(
            content: Text("Not a button"),
            shortcut: KeyboardShortcut("x", modifiers: .control),
        )

        var buffer = Buffer(width: 20, height: 1)
        let region = Region(row: 0, col: 0, width: 20, height: 1)
        view.render(into: &buffer, region: region, context: ctx)

        #expect(registry.discoveredEntries.isEmpty)
    }

    @Test("Disabled context suppresses registration")
    func disabledContextSuppresses() {
        let registry = CommandRegistry()
        var ctx = RenderContext()
        ctx.commandRegistry = registry
        ctx.isDisabled = true

        let view = KeyboardShortcutView(
            content: Button("Disabled") {},
            shortcut: KeyboardShortcut("d", modifiers: .control),
        )

        var buffer = Buffer(width: 20, height: 1)
        let region = Region(row: 0, col: 0, width: 20, height: 1)
        view.render(into: &buffer, region: region, context: ctx)

        #expect(registry.discoveredEntries.isEmpty)
    }

    @Test("Discovered shortcuts appear in filteredEntries")
    func discoveredInFilteredEntries() {
        let registry = CommandRegistry()
        var ctx = RenderContext()
        ctx.commandRegistry = registry

        let view = KeyboardShortcutView(
            content: Button("Export") {},
            shortcut: KeyboardShortcut("e", modifiers: .control),
        )

        var buffer = Buffer(width: 20, height: 1)
        let region = Region(row: 0, col: 0, width: 20, height: 1)
        view.render(into: &buffer, region: region, context: ctx)

        // Should appear in allEntries and filteredEntries
        #expect(registry.allEntries.count == 1)
        #expect(registry.filteredEntries.count == 1)
        #expect(registry.filteredEntries[0].name == "Export")

        // Filter should work on discovered entries too
        registry.filterText = "exp"
        #expect(registry.filteredEntries.count == 1)
        registry.filterText = "xyz"
        #expect(registry.filteredEntries.isEmpty)
    }

    @Test("matchShortcut finds discovered shortcuts")
    func matchShortcutFindsDiscovered() {
        let fired = Flag()
        let registry = CommandRegistry()
        var ctx = RenderContext()
        ctx.commandRegistry = registry

        let view = KeyboardShortcutView(
            content: Button("Help") { fired.value = true },
            shortcut: KeyboardShortcut("h", modifiers: .control),
        )

        var buffer = Buffer(width: 10, height: 1)
        let region = Region(row: 0, col: 0, width: 10, height: 1)
        view.render(into: &buffer, region: region, context: ctx)

        let entry = registry.matchShortcut(.ctrl("h"))
        #expect(entry?.name == "Help")
        entry?.action()
        #expect(fired.value)
    }
}
