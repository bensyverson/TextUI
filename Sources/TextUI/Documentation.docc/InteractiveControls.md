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

#### Button Styles

Use `.buttonStyle(_:)` to control the visual treatment of buttons:

```swift
// Plain (default) — label text only
Button("Cancel") { cancel() }
    .buttonStyle(.plain)

// Bordered — label inside a rounded border
Button("Submit") { submit() }
    .buttonStyle(.bordered)

// Bordered prominent — bold label inside a rounded border
Button("Delete") { delete() }
    .buttonStyle(.borderedProminent)
```

The style propagates through the view hierarchy, so you can set it on a
parent to affect all descendant buttons:

```swift
VStack {
    Button("Save") { save() }
    Button("Reset") { reset() }
}
.buttonStyle(.bordered)
```

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

### TabView

A tab container that switches between content panes:

```swift
TabView {
    TabView.Tab("Home") { HomeView() }
    TabView.Tab("Settings") { SettingsView() }
}
```

TabView supports three density levels via `.controlSize(_:)`:
- **`.small`** — 1-line compact tab bar
- **`.regular`** (default) — 2-line with labels in a border row
- **`.large`** — 3-line with full tab boxes

Control the horizontal rule with `.tabDividerStyle(_:)`:
- **`.none`** — tabs float above content
- **`.bottom`** (default) — rule below tabs
- **`.middle`** — rule through center of labels (`.large` only)

Add a content border with `.tabBorderStyle(.rounded)` or `.tabBorderStyle(.square)`,
which merges with the divider. This is ignored when the divider is `.none`.

Position tabs with the `alignment:` parameter:

```swift
TabView(alignment: .center) {
    TabView.Tab("Home") { HomeView() }
    TabView.Tab("Settings") { SettingsView() }
}
.controlSize(.large)
.tabDividerStyle(.bottom)
.tabBorderStyle(.rounded)
```

Inactive tabs render dim, the selected tab renders bold (unfocused) or
inverse (focused). The tab bar responds to Left/Right arrow keys.

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

### Disabling Controls

Use `.disabled(_:)` to prevent interaction with controls. Disabled controls
render with dim styling and are removed from the focus ring:

```swift
Button("Submit") { send() }
    .disabled(isLoading)

VStack {
    TextField("Name", text: name) { name = $0 }
    Button("Save") { save() }
}
.disabled(!isFormValid)
```

### Modal

Use `.modal(isPresented:onDismiss:content:)` to present focused overlay
content on a dimmed background. Background controls are removed from the
focus ring while the modal is visible:

```swift
ContentView()
    .modal(isPresented: state.showConfirm, onDismiss: { state.showConfirm = false }) {
        VStack {
            Text("Are you sure?")
            HStack {
                Button("Cancel") { state.showConfirm = false }
                Button("Confirm") { confirm() }
                    .buttonStyle(.borderedProminent)
            }
        }
        .border(.rounded)
        .padding(1)
    }
```

The modal body is centered within the background region. Add your own
chrome — border, padding, background color — to the modal content.

When `onDismiss` is provided, pressing Escape calls the closure. Pass
`nil` (the default) to leave Escape unhandled.

### Quitting the Application

Use ``Application/quit()`` to stop the run loop programmatically:

```swift
Button("Quit") { Application.quit() }
    .keyboardShortcut("q", modifiers: .control)
```

## Topics

### Controls

- ``Button``
- ``ButtonStyle``
- ``TextField``
- ``Toggle``
- ``Picker``
- ``TabView``
- ``ControlSize``
- ``TabDividerStyle``

### Lifecycle

- ``Application``
