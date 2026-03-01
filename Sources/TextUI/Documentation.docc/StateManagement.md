# State Management

Reactive state, environment objects, and the app lifecycle.

## Overview

TextUI provides a reactive state system inspired by SwiftUI. When state changes, the UI automatically re-renders. The key components are:

### Observed Properties

The ``Observed`` property wrapper signals the run loop when a value changes. Use it on `@MainActor` state classes:

```swift
@MainActor
final class AppState {
    @Observed var count = 0
    @Observed var name = "World"
}
```

Every mutation triggers ``StateSignal/send()``, which the run loop consumes to schedule a re-render. No equality gating is performed — the ``Screen``'s differential flush efficiently handles no-op changes.

> Note: SwiftUI developers: ``Observed`` replaces both `@State` and
> `@Published`. There is no `@Binding` — pass `onChange` closures instead.
> See <doc:SwiftUIDifferences> for a full comparison.

### Environment Objects

Environment objects use dependency injection to share state across the view tree without explicit parameter passing.

Inject an object into the hierarchy:

```swift
MyView()
    .environmentObject(appState)
```

Read it in a descendant view:

```swift
struct CounterView: View {
    @EnvironmentObject var state: AppState

    var body: some View {
        Text("Count: \(state.count)")
    }
}
```

### App Protocol

The ``App`` protocol defines the entry point for a TextUI application. Conform to it and provide a ``App/body`` property:

```swift
@main
struct MyApp: App {
    var body: some View {
        VStack {
            Text("Hello, TextUI!")
        }
    }

    static func main() async {
        await MyApp.main()
    }
}
```

The ``App/main()`` method handles terminal setup, the event loop, and cleanup.

## Topics

### State

- ``Observed``
- ``StateSignal``

### Environment

- ``EnvironmentObject``
- ``RenderContext``
- ``RenderEnvironment``

### App Lifecycle

- ``App``
