# Getting Started

Create your first TextUI terminal application.

## Overview

TextUI is a Swift framework for building terminal applications using a
declarative, SwiftUI-inspired API. This guide walks you through setup,
creating a basic app, adding views and interactivity, and registering
commands.

### Package Setup

Add TextUI as a dependency in your `Package.swift`:

```swift
// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "MyApp",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(url: "https://github.com/example/TextUI.git", from: "1.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "MyApp",
            dependencies: ["TextUI"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
```

### Creating an App

Define your app by conforming to the ``App`` protocol. Use `@main` to
mark it as the entry point:

```swift
import TextUI

@main
struct MyApp: App {
    var body: some View {
        VStack {
            Text("Hello, TextUI!")
        }
    }
}
```

Run with `swift run` — this enters the alternate screen buffer, renders
your view, and waits for Ctrl+C to exit.

### Building a View Hierarchy

Compose views using ``VStack``, ``HStack``, and ``ZStack``:

```swift
var body: some View {
    VStack(spacing: 1) {
        Text("Welcome", style: .bold)

        HStack(spacing: 2) {
            Text("Left", style: Style(fg: .cyan))
            Spacer()
            Text("Right", style: Style(fg: .magenta))
        }

        Divider.horizontal
        Text("Footer", style: .dim)
    }
    .padding(1)
    .border()
}
```

### Adding State and Interactivity

Create a state class with properties that trigger re-renders. Inject it
into your view tree with `.environmentObject()`, and read it with
`@EnvironmentObject`:

```swift
final class AppState: @unchecked Sendable {
    var count: Int = 0

    func increment() {
        count += 1
        MainActor.assumeIsolated { StateSignal.send() }
    }
}

struct CounterView: View {
    @EnvironmentObject var state: AppState

    var body: some View {
        VStack {
            Text("Count: \(state.count)")
            Button("Increment") { [state] in state.increment() }
        }
    }
}
```

### Adding Commands

Override the `commands` property on your ``App`` to register global
keyboard shortcuts. Display them with ``CommandBar``:

```swift
@main
struct MyApp: App {
    let state = AppState()

    var body: some View {
        VStack {
            CounterView()
            CommandBar()
        }
        .environmentObject(state)
    }

    var commands: [CommandGroup] {
        [CommandGroup("Edit") {
            Button("Reset") { [state] in state.count = 0 }
                .keyboardShortcut("r", modifiers: .control)
        }]
    }
}
```

Press **Ctrl+P** at any time to open the command palette for searching
and executing commands by name.

## Topics

### App Lifecycle

- ``App``

### Views

- ``Text``
- ``VStack``
- ``HStack``
- ``Spacer``
- ``Divider``

### State

- ``Observed``
- ``EnvironmentObject``
- ``StateSignal``

### Commands

- ``CommandGroup``
- ``CommandBar``
