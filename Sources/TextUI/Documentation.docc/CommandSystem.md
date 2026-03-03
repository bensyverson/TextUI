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
        [CommandGroup("File") {
            Button("Save") { save() }
                .keyboardShortcut("s", modifiers: .control)
            Button("Open") { open() }
                .keyboardShortcut("o", modifiers: .control)
        },
        CommandGroup("Edit") {
            Button("Copy") { copy() }
                .keyboardShortcut("c", modifiers: .control)
        }]
    }

    var body: some View {
        VStack {
            mainContent
            CommandBar()
        }
    }
}
```

### Inline Keyboard Shortcuts

You can also attach `.keyboardShortcut()` directly to any `Button` in your
view body. The shortcut is automatically discovered during rendering and
registered with the command system:

```swift
var body: some View {
    VStack {
        Button("Quit") { quit() }
            .keyboardShortcut("q", modifiers: .control)
        Text("Press Ctrl+Q to quit")
    }
}
```

Inline shortcuts follow the same lifecycle as the view tree — if a button is
conditionally hidden or disabled, its shortcut is automatically removed.
Static ``CommandGroup`` shortcuts take priority when there is a conflict.

### Key Routing Order

When a key is pressed, the run loop checks in this order:

1. **Ctrl+C** — always exits the application
2. **Focus system** — inline handlers, `onKeyPress`, `onSubmit`
3. **Tab / Shift-Tab** — focus ring navigation
4. **Arrow keys** — directional focus navigation
5. **Command shortcuts** — matched against registered ``KeyboardShortcut`` values

Focus routing happens before shortcuts so that focused controls (like
`TextField`) consume their input keys first. Modifier shortcuts like Ctrl+S
still work because `TextField` returns `.ignored` for unrecognized keys.

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

### Command Palette

Press **Ctrl+P** at any time to open the command palette — a centered overlay
that lets users search and execute commands by name. The palette supports:

- **Typing** — filters commands case-insensitively by name
- **Up / Down arrows** — navigate the filtered list
- **Enter** — execute the highlighted command and close the palette
- **Escape** or **Ctrl+P** — close the palette without executing

The palette is automatically available in any app that defines commands
via the `commands` property on ``App``. No additional views or
configuration are required.

```
╭──── Command Palette ──────────────────╮
│ > search text█                        │
├───────────────────────────────────────┤
│   Save                           ^S  │
│ ▸ Open                           ^O  │
│   Copy                           ^C  │
╰───────────────────────────────────────╯
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
