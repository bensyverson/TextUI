# Focus System

Navigate between interactive controls using keyboard input.

## Overview

TextUI's focus system manages which control receives keyboard input. It
mirrors SwiftUI's focus model with a **focus ring** — an ordered list of
focusable controls built automatically during each render pass. Users
navigate the ring with Tab/Shift-Tab, and developers can control focus
programmatically with ``FocusState``.

### How It Works

1. During each render frame, focusable controls (``Button``, ``TextField``,
   ``Toggle``, ``Picker``) register themselves in the `FocusStore`'s ring.
2. Since rendering visits views top-to-bottom (in ``VStack``) and
   left-to-right (in ``HStack``), the ring is automatically ordered for
   Tab navigation.
3. Key events flow through the focused control's handler chain:
   inline handler → ancestor `onKeyPress` chain → `onSubmit` handlers.
4. If no handler consumes the event, focus navigation takes over
   (Tab/Shift-Tab for linear, arrows for directional).

### Programmatic Focus with @FocusState

Use ``FocusState`` with an `Optional<Hashable>` value and the
`.focused(_:equals:)` modifier to bind views to focus values:

```swift
enum Field: Hashable {
    case name, email
}

struct FormView: View {
    @FocusState var focus: Field?
    @EnvironmentObject var state: FormState

    var body: some View {
        VStack {
            TextField("Name", text: state.name) { state.name = $0 }
                .focused($focus, equals: .name)
            TextField("Email", text: state.email) { state.email = $0 }
                .focused($focus, equals: .email)
            Button("Submit") {
                if state.name.isEmpty {
                    focus = .name  // move focus programmatically
                }
            }
        }
    }
}
```

### Focus Sections

Use `.focusSection()` to group controls so arrow key navigation stays
within the group:

```swift
VStack {
    VStack {
        Button("Option A") { ... }
        Button("Option B") { ... }
    }
    .focusSection()  // Up/Down cycles only between A and B

    VStack {
        Button("Save") { ... }
        Button("Cancel") { ... }
    }
    .focusSection()  // Up/Down cycles only between Save and Cancel
}
```

Tab/Shift-Tab still crosses section boundaries.

### Default Focus

Set which control receives focus on the first frame:

```swift
.defaultFocus($focus, .email)  // Email field focused on launch
```

### Key Event Handling

Intercept key events with `.onKeyPress()`:

```swift
VStack { ... }
    .onKeyPress { key in
        if key == .escape {
            dismiss()
            return .handled
        }
        return .ignored
    }
```

Handle Enter on text fields with `.onSubmit()`:

```swift
TextField("Search", text: query) { query = $0 }
    .onSubmit { performSearch() }
```

## Topics

### Focus State

- ``FocusState``
- ``FocusInteraction``
- ``KeyEventResult``

