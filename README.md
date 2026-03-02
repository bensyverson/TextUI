# TextUI

A SwiftUI-inspired framework for building expressive terminal UIs in Swift, with zero dependencies.

Why? Why not! It makes building fancy terminal apps super fun.

## Quick Start

Add TextUI to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/bensyverson/TextUI.git", branch: "main"),
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
- **State management** — View-local `@State` and shared state via `@EnvironmentObject`
- **Modifiers** — `.padding()`, `.border()`, `.foregroundColor()`, `.background()`, `.frame()`
- **Command system** — Global keyboard shortcuts, CommandBar, and Ctrl+P command palette
- **Animation** — ProgressView with spinner and bar styles
- **Terminal handling** — Raw mode, alternate screen, resize detection, 24-bit color with automatic downgrade

## Documentation

[Browse the documentation online](https://bensyverson.com/documentation/TextUI/), or check out the DocC catalog at [`Sources/TextUI/Documentation.docc/`](Sources/TextUI/Documentation.docc/). Key articles:

- **[Getting Started](Sources/TextUI/Documentation.docc/GettingStarted.md)** — Get up to speed on the core concepts quickly
- **[SwiftUI Differences](Sources/TextUI/Documentation.docc/SwiftUIDifferences.md)** — Coming from SwiftUI? Read this first.
- **[Focus System](Sources/TextUI/Documentation.docc/FocusSystem.md)** — Learn how TextUI approaches focus and keyboard navigation
- **[StateManagement](Sources/TextUI/Documentation.docc/StateManagement.md)** — Observe and interact with local or shared state
- **[Animation](Sources/TextUI/Documentation.docc/Animation.md)** — Create animations using TextUI's global `@AnimationTick`

You can generate the API documentation with DocC:

```bash
swift package generate-documentation --target TextUI

# Serve the docs:
swift package --disable-sandbox preview-documentation --target TextUI
```

Key guides:
- **Getting Started** — Package setup, creating an app, adding views and state
- **Views** — Catalog of all built-in views with examples
- **Focus and Input** — Keyboard navigation, @FocusState, key event handling
- **Command System** — Global shortcuts, CommandBar, command palette
- **TextUI vs SwiftUI** — Key differences for SwiftUI developers

## Requirements

- Swift 6.2+
- macOS 13+ or Linux (glibc)

## Development

Enable the pre-commit hook (runs swiftformat lint + tests):

```bash
git config core.hooksPath scripts
```

## Demo App

Run the showcase demo:

```bash
cd Examples/Demo
swift run
```

The demo includes tabs for form controls, a data table, progress indicators, a log which updates via an async process, and a tab of the remaining layout primitives.

---

## License

This project is licensed under the [MIT License](LICENSE).

Copyright (c) 2026 Ben Syverson
