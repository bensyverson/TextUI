# Command System

Define global keyboard shortcuts and display them in a command bar.

## Overview

The command system lets you declare global keyboard shortcuts that are matched
before focus-based key routing. Commands are organized into named groups using
``CommandGroup``, and can be displayed to the user via ``CommandBar``.

### Defining Commands

Use ``CommandGroup`` with `Button` and `.keyboardShortcut()` to declare commands:

```swift
struct MyApp: App {
    var commands: [CommandGroup] {
        CommandGroup("File") {
            Button("Save") { save() }
                .keyboardShortcut("s", modifiers: .control)
            Button("Open") { open() }
                .keyboardShortcut("o", modifiers: .control)
        }
        CommandGroup("Edit") {
            Button("Copy") { copy() }
                .keyboardShortcut("c", modifiers: .control)
        }
    }

    var body: some View {
        VStack {
            mainContent
            CommandBar()
        }
    }
}
```

### Key Routing Order

When a key is pressed, the run loop checks shortcuts in this order:

1. **Ctrl+C** — always exits the application
2. **Command shortcuts** — matched against registered ``KeyboardShortcut`` values
3. **Focus system** — inline handlers, `onKeyPress`, `onSubmit`
4. **Tab / Shift-Tab** — focus ring navigation
5. **Arrow keys** — directional focus navigation

### Keyboard Shortcuts

A ``KeyboardShortcut`` combines a ``KeyEquivalent`` (a character or named key)
with ``EventModifiers`` (control, shift, option). Common shortcuts:

```swift
KeyboardShortcut("s", modifiers: .control)      // Ctrl+S
KeyboardShortcut(.defaultAction)                  // Enter
KeyboardShortcut(.cancelAction)                   // Escape
KeyboardShortcut(KeyEquivalent(.tab), modifiers: .shift)  // Shift+Tab
```

### CommandBar

``CommandBar`` is a primitive view that renders registered shortcuts as a
single-line status bar. Each entry shows the shortcut in bold/inverse and
the command name in dim text. Use group filtering to show only relevant commands:

```swift
CommandBar()                        // All groups
CommandBar(groups: ["File"])        // Only "File" group
```

## Topics

### Types

- ``KeyEquivalent``
- ``EventModifiers``
- ``KeyboardShortcut``
- ``CommandEntry``
- ``CommandGroup``
- ``CommandBuilder``
- ``CommandBar``
- ``EmptyCommands``
