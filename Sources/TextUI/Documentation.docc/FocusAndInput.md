# Focus and Input

Handle keyboard input and navigate between interactive controls.

## Overview

TextUI routes keyboard events through a focus system that determines which
control receives input. This guide covers the focus ring, programmatic focus
management, key event handling, and the command palette.

### Focus Ring

Interactive controls (``Button``, ``TextField``, ``Toggle``, ``Picker``)
automatically join the **focus ring** during each render pass. The ring
determines the order of Tab navigation, matching the visual layout order:
top-to-bottom in ``VStack``, left-to-right in ``HStack``.

Navigate the ring with:
- **Tab** — move to the next control
- **Shift+Tab** — move to the previous control
- **Arrow keys** — move directionally within a focus section
- **Ctrl+Shift+Left/Right** — switch tabs globally in the innermost ``TabView``

### @FocusState

Use ``FocusState`` to programmatically control which view is focused:

```swift
enum Field: Hashable {
    case name, email
}

struct FormView: View {
    @FocusState var focus: Field?

    var body: some View {
        VStack {
            TextField("Name", text: name) { name = $0 }
                .focused($focus, equals: .name)
            TextField("Email", text: email) { email = $0 }
                .focused($focus, equals: .email)
        }
    }
}
```

Set `focus = .email` to move focus programmatically.

### Default Focus

Specify which control should be focused when the app first renders:

```swift
.defaultFocus($focus, .name)
```

### Focus Sections

Group controls with `.focusSection()` so arrow keys cycle only within
the group, while Tab/Shift-Tab still crosses boundaries:

```swift
HStack {
    VStack {
        Button("A") { ... }
        Button("B") { ... }
    }
    .focusSection()

    VStack {
        Button("X") { ... }
        Button("Y") { ... }
    }
    .focusSection()
}
```

### Key Event Handling

Intercept key events on any view with `.onKeyPress()`:

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

### TextField Input

``TextField`` handles character input, backspace, and cursor display
automatically when focused. Use the `onChange` callback to update your
state as the user types.

### Command Palette

Press **Ctrl+P** to open the command palette overlay. The palette
displays all registered commands from your app's ``CommandGroup``
definitions and supports:

- **Typing** — filters commands by name (case-insensitive)
- **Up/Down** — navigate the filtered list
- **Enter** — execute the selected command
- **Escape** — close the palette

The palette is available in any TextUI app that defines commands,
with no additional setup required.

## Topics

### Focus

- ``FocusState``
- ``FocusInteraction``
- ``KeyEventResult``

### Input

- ``InputEvent``
- ``KeyEvent``
- ``MouseEvent``
- ``KeyReader``
- ``TextField``
