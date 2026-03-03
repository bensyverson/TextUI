import Testing
@testable import TextUI

/// Mutable flag for use in test closures.
private final class Flag {
    var value: Bool = false
}

@MainActor
@Suite("CommandRegistry")
struct CommandRegistryTests {
    @Test("Register groups stores entries")
    func registerStores() {
        let registry = CommandRegistry()
        let group = CommandGroup("File") {
            Button("Save") {}
                .keyboardShortcut("s", modifiers: .control)
        }
        registry.register([group])
        #expect(registry.groups.count == 1)
        #expect(registry.groups[0].name == "File")
        #expect(registry.groups[0].entries.count == 1)
    }

    @Test("matchShortcut returns correct entry")
    func matchReturnsEntry() {
        let registry = CommandRegistry()
        let group = CommandGroup("File") {
            Button("Save") {}
                .keyboardShortcut("s", modifiers: .control)
        }
        registry.register([group])
        let entry = registry.matchShortcut(.ctrl("s"))
        #expect(entry?.name == "Save")
    }

    @Test("matchShortcut returns nil for unregistered shortcuts")
    func matchReturnsNil() {
        let registry = CommandRegistry()
        let group = CommandGroup("File") {
            Button("Save") {}
                .keyboardShortcut("s", modifiers: .control)
        }
        registry.register([group])
        #expect(registry.matchShortcut(.ctrl("x")) == nil)
    }

    @Test("allEntries flattens across groups")
    func allEntriesFlattens() {
        let registry = CommandRegistry()
        let fileGroup = CommandGroup("File") {
            Button("Save") {}
            Button("Open") {}
        }
        let editGroup = CommandGroup("Edit") {
            Button("Copy") {}
        }
        registry.register([fileGroup, editGroup])
        #expect(registry.allEntries.count == 3)
    }

    @Test("Multiple groups with same shortcut: first wins")
    func firstShortcutWins() {
        let registry = CommandRegistry()
        let group1 = CommandGroup("File") {
            Button("FileSave") {}
                .keyboardShortcut("s", modifiers: .control)
        }
        let group2 = CommandGroup("Edit") {
            Button("EditSave") {}
                .keyboardShortcut("s", modifiers: .control)
        }
        registry.register([group1, group2])
        let entry = registry.matchShortcut(.ctrl("s"))
        #expect(entry?.name == "FileSave")
    }

    @Test("isPaletteVisible toggle")
    func paletteToggle() {
        let registry = CommandRegistry()
        #expect(!registry.isPaletteVisible)
        registry.isPaletteVisible.toggle()
        #expect(registry.isPaletteVisible)
    }

    @Test("Matched entry action is callable")
    func matchedActionCallable() {
        let fired = Flag()
        let registry = CommandRegistry()
        let group = CommandGroup("Test") {
            Button("Go") { fired.value = true }
                .keyboardShortcut("g", modifiers: .control)
        }
        registry.register([group])
        let entry = registry.matchShortcut(.ctrl("g"))
        entry?.action()
        #expect(fired.value)
    }

    @Test("filteredEntries returns all when filter is empty")
    func filteredEntriesAllWhenEmpty() {
        let registry = CommandRegistry()
        let group = CommandGroup("File") {
            Button("Save") {}
            Button("Open") {}
        }
        registry.register([group])
        #expect(registry.filteredEntries.count == 2)
    }

    @Test("filteredEntries filters case-insensitively")
    func filteredEntriesCaseInsensitive() {
        let registry = CommandRegistry()
        let group = CommandGroup("File") {
            Button("Save") {}
            Button("Open") {}
        }
        registry.register([group])
        registry.filterText = "sav"
        #expect(registry.filteredEntries.count == 1)
        #expect(registry.filteredEntries[0].name == "Save")
    }

    @Test("filteredEntries returns empty when no match")
    func filteredEntriesNoMatch() {
        let registry = CommandRegistry()
        let group = CommandGroup("File") {
            Button("Save") {}
            Button("Open") {}
        }
        registry.register([group])
        registry.filterText = "xyz"
        #expect(registry.filteredEntries.isEmpty)
    }

    @Test("resetPaletteState clears filter and index")
    func resetPaletteStateClearsBoth() {
        let registry = CommandRegistry()
        registry.filterText = "hello"
        registry.selectedIndex = 3
        registry.resetPaletteState()
        #expect(registry.filterText == "")
        #expect(registry.selectedIndex == 0)
    }

    @Test("Entries without shortcuts are not matched")
    func noShortcutNotMatched() {
        let registry = CommandRegistry()
        let group = CommandGroup("File") {
            Button("About") {}
        }
        registry.register([group])
        #expect(registry.matchShortcut(.enter) == nil)
        #expect(registry.allEntries.count == 1)
    }
}
