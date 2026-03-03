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
        .package(url: "https://github.com/bensyverson/TextUI.git", from: "1.0.0"),
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

All custom views are implicitly `@MainActor` because the ``View``
protocol is `@MainActor`-isolated. This means closures in controls
(button actions, text field callbacks) can mutate `@MainActor` state
directly without any `@Sendable` annotation.

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

Use ``State`` for view-local mutable values. Mutations automatically
trigger a re-render:

```swift
struct CounterView: View {
    @State var count: Int = 0

    var body: some View {
        HStack {
            Text("Count: \(count)")
            Button("+1") { count += 1 }
        }
    }
}
```

### Sharing State Across Views

When multiple views need access to the same state, create a
`@MainActor` class with ``Observed`` properties. Inject it with
`.environmentObject()` and read it with `@EnvironmentObject`:

```swift
@MainActor
final class AppState {
    @Observed var count = 0
}

struct CounterView: View {
    @EnvironmentObject var state: AppState

    var body: some View {
        HStack {
            Text("Count: \(state.count)")
            Button("+1") { [state] in state.count += 1 }
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

- ``State``
- ``Observed``
- ``EnvironmentObject``

### Commands

- ``CommandGroup``
- ``CommandBar``
