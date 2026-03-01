# Interactive Controls

Build forms and interactive interfaces with focusable controls.

## Overview

TextUI provides four built-in interactive controls that integrate with
the focus system. Each control auto-registers in the focus ring during
rendering and responds to keyboard input when focused.

### Button

A button triggers an action when activated with Enter or Space:

```swift
Button("Submit") {
    submitForm()
}

// Custom label
Button {
    cancel()
} label: {
    Text("Cancel").foregroundColor(.red)
}
```

Buttons use ``FocusInteraction/activate`` and render with inverse styling
when focused. They hug their label content.

### TextField

A single-line text input field:

```swift
TextField("Search", text: state.query) { newValue in
    state.query = newValue
}
    .onSubmit { performSearch() }
```

TextFields use ``FocusInteraction/edit`` and capture all keyboard input
when focused. They are greedy on width (fill available space) with a
fixed height of 1. Features:
- Cursor navigation (Left/Right/Home/End)
- Character insertion and backspace/delete
- Scrolling when text exceeds visible width
- Dim placeholder text when empty and unfocused

### Toggle

A checkbox that switches between on and off:

```swift
Toggle("Dark mode", isOn: settings.darkMode) { newValue in
    settings.darkMode = newValue
}
```

Toggles render as `[x] Label` (on) or `[ ] Label` (off) and respond
to Space or Enter when focused. They use ``FocusInteraction/activate``.

### Picker

A control that cycles through a list of options:

```swift
Picker("Color", selection: state.colorIndex, options: ["Red", "Green", "Blue"]) { newIndex in
    state.colorIndex = newIndex
}
```

Pickers render as `Label: < Option >` and respond to Left/Right arrow
keys when focused. Pressing Space or Enter opens a dropdown overlay
where Up/Down navigates options, Enter confirms, and Escape cancels.
They use ``FocusInteraction/activate``.

### Building a Form

Combine controls with layout views to build forms:

```swift
struct SettingsView: View {
    @EnvironmentObject var settings: Settings

    var body: some View {
        VStack {
            TextField("Username", text: settings.username) { settings.username = $0 }
            TextField("Email", text: settings.email) { settings.email = $0 }
            Toggle("Notifications", isOn: settings.notifications) { settings.notifications = $0 }
            Picker("Theme", selection: settings.themeIndex, options: ["Light", "Dark", "System"]) {
                settings.themeIndex = $0
            }
            Button("Save") { settings.save() }
        }
        .border(.rounded)
        .padding(1)
    }
}
```

### Quitting the Application

Use ``Application/quit()`` to stop the run loop programmatically:

```swift
Button("Quit") { Application.quit() }
    .keyboardShortcut("q", modifiers: .control)
```

## Topics

### Controls

- ``Button``
- ``TextField``
- ``Toggle``
- ``Picker``

### Lifecycle

- ``Application``
