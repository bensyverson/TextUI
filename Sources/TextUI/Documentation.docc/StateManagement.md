# State Management

Reactive state, environment objects, and the app lifecycle.

## Overview

TextUI provides a reactive state system inspired by SwiftUI. When state changes, the UI automatically re-renders. The key components are:

### View-Local State

The ``State`` property wrapper provides per-view mutable storage that persists across render frames. Use it for state that belongs to a single view:

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

`@State` stores its value in the same per-control state dictionary used by built-in controls like ``TextField`` and ``ScrollView``. The storage key is derived from the declaration site (`#fileID:#line`), so each `@State` property gets its own slot automatically. Mutations trigger ``StateSignal/send()`` to schedule a re-render.

Because ``View`` is `@MainActor`, `@State` mutations work directly inside control closures — no `@Sendable` annotation is needed:

```swift
Button("+1") { count += 1 }  // count is @State — just works
```

### Observed Properties

The ``Observed`` property wrapper signals the run loop when a value changes. Use it on `@MainActor` state classes for **shared** state:

```swift
@MainActor
final class AppState {
    @Observed var count = 0
    @Observed var name = "World"
}
```

Every mutation triggers ``StateSignal/send()``, which the run loop consumes to schedule a re-render. No equality gating is performed — the ``Screen``'s differential flush efficiently handles no-op changes.

> Note: SwiftUI developers: use ``State`` for view-local values and
> ``Observed`` for shared state on classes. There is no `@Binding` — pass
> `onChange` closures instead. See <doc:SwiftUIDifferences> for a full
> comparison.

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

### View-Scoped Async Tasks

The `.task {}` modifier runs an async closure when a view first appears and cancels it when the view is removed from the tree:

```swift
struct LogView: View {
    @State var entries: [String] = []

    var body: some View {
        ScrollView {
            ForEach(entries, id: \.self) { Text($0) }
        }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                entries.append("New entry at \(Date())")
            }
        }
    }
}
```

Tasks are managed by an internal `TaskStore` using the same `beginFrame()`/`endFrame()` lifecycle as the focus and animation systems. When a view with `.task {}` is no longer rendered (e.g. switching tabs), the task is automatically cancelled.

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

- ``State``
- ``Observed``
- ``StateSignal``

### Environment

- ``EnvironmentObject``
- ``RenderContext``
- ``RenderEnvironment``

### App Lifecycle

- ``App``
