# TextUI

A SwiftUI-inspired framework for building expressive terminal user interfaces in Swift.

## Quick Start

Add TextUI to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/example/TextUI.git", from: "1.0.0"),
]
```

Create a terminal app:

```swift
import TextUI

@main
struct HelloApp: App {
    var body: some View {
        VStack(spacing: 1) {
            Text("Hello, TextUI!", style: .bold)
            Button("Quit") {}
                .keyboardShortcut("q", modifiers: .control)
            CommandBar()
        }
        .padding(1)
        .border()
    }
}
```

## Features

- **Declarative views** — Text, HStack, VStack, ZStack, Spacer, Divider, Color, Canvas
- **Interactive controls** — Button, TextField, Toggle, Picker with Tab/Shift-Tab focus navigation
- **Containers** — ScrollView, Table, TabView
- **State management** — `@Observed` property wrapper with automatic re-rendering
- **Modifiers** — `.padding()`, `.border()`, `.foregroundColor()`, `.background()`, `.frame()`
- **Command system** — Global keyboard shortcuts, CommandBar, and Ctrl+P command palette
- **Animation** — ProgressView with spinner and bar styles
- **Terminal handling** — Raw mode, alternate screen, resize detection, 24-bit color with automatic downgrade

## Documentation

Generate API documentation with DocC:

```bash
swift package generate-documentation --target TextUI
```

Key guides:
- **Getting Started** — Package setup, creating an app, adding views and state
- **Views** — Catalog of all built-in views with examples
- **Focus and Input** — Keyboard navigation, @FocusState, key event handling
- **Command System** — Global shortcuts, CommandBar, command palette

## Demo App

Run the showcase demo:

```bash
swift run --package-path Examples/Demo
```

The demo includes tabs for form controls, a data table, progress indicators,
and layout primitives.

---

## License

This project is licensed under the [MIT License](LICENSE).

Copyright (c) 2026 Ben Syverson
