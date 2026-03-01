import Testing
@testable import TextUI

/// Thread-safe mutable flag for use in `@Sendable` test closures.
private final class Flag: @unchecked Sendable {
    var value: Bool = false
}

@Suite("CommandGroup")
struct CommandGroupTests {
    @Test("Extracts Button name")
    func extractsButtonName() {
        let group = CommandGroup("File") {
            Button("Save") {}
        }
        #expect(group.entries.count == 1)
        #expect(group.entries[0].name == "Save")
        #expect(group.entries[0].group == "File")
    }

    @Test("Extracts shortcut from .keyboardShortcut()")
    func extractsShortcut() {
        let group = CommandGroup("File") {
            Button("Save") {}
                .keyboardShortcut("s", modifiers: .control)
        }
        #expect(group.entries.count == 1)
        #expect(group.entries[0].shortcut != nil)
        #expect(group.entries[0].shortcut?.matches(.ctrl("s")) == true)
    }

    @Test("Button without shortcut has nil shortcut")
    func noShortcut() {
        let group = CommandGroup("File") {
            Button("About") {}
        }
        #expect(group.entries[0].shortcut == nil)
    }

    @Test("Multiple entries per group")
    func multipleEntries() {
        let group = CommandGroup("File") {
            Button("Save") {}
                .keyboardShortcut("s", modifiers: .control)
            Button("Open") {}
                .keyboardShortcut("o", modifiers: .control)
            Button("Quit") {}
        }
        #expect(group.entries.count == 3)
        #expect(group.entries[0].name == "Save")
        #expect(group.entries[1].name == "Open")
        #expect(group.entries[2].name == "Quit")
    }

    @Test("Extracted action is callable")
    func actionCallable() {
        let fired = Flag()
        let group = CommandGroup("Test") {
            Button("Go") { fired.value = true }
        }
        #expect(!fired.value)
        group.entries[0].action()
        #expect(fired.value)
    }
}

@Suite("CommandBuilder")
struct CommandBuilderTests {
    @Test("Composes multiple groups")
    func composesGroups() {
        @CommandBuilder var commands: [CommandGroup] {
            CommandGroup("File") {
                Button("Save") {}
            }
            CommandGroup("Edit") {
                Button("Copy") {}
            }
        }
        #expect(commands.count == 2)
        #expect(commands[0].name == "File")
        #expect(commands[1].name == "Edit")
    }
}

@Suite("EmptyCommands")
struct EmptyCommandsTests {
    @Test("Produces no entries")
    func noEntries() {
        let empty = EmptyCommands()
        #expect(empty.groups.isEmpty)
    }
}
