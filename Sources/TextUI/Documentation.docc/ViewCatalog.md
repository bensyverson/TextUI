# View Catalog

A catalog of all built-in views in TextUI.

## Overview

TextUI provides a rich set of views for building terminal interfaces. Views
are value types conforming to the ``View`` protocol. Primitive views handle
their own sizing and rendering; composite views define a `body` property.

### Text Display

``Text`` renders a string with an optional ``Style``:

```swift
Text("Hello, world!")
Text("Error!", style: Style(fg: .red).bolded())
```

``AttributedText`` renders pre-styled spans built with `@SpanBuilder`:

```swift
AttributedText {
    Span("Bold ", style: .bold)
    Span("and dim", style: .dim)
}
```

### Stacks

``VStack`` arranges children vertically. ``HStack`` arranges them horizontally.
``ZStack`` layers children on top of each other:

```swift
VStack(alignment: .leading, spacing: 1) {
    Text("First")
    Text("Second")
}

HStack(spacing: 2) {
    Text("Left")
    Text("Right")
}
```

### Spacer and Divider

``Spacer`` expands to fill available space along the stack axis:

```swift
HStack {
    Text("Left")
    Spacer()
    Text("Right")
}
```

``Divider`` draws a line separator:

```swift
VStack {
    Text("Above")
    Divider.horizontal
    Text("Below")
}
```

### Color and Canvas

``Color`` fills its region with a solid color:

```swift
Color(.blue).frame(width: 20, height: 3)
```

``Canvas`` provides direct buffer access for custom drawing:

```swift
Canvas { buffer, region in
    buffer.write("Custom", row: region.row, col: region.col, style: .bold)
}
```

### Iteration

``ForEach`` creates views from a collection:

```swift
ForEach(items) { item in
    Text(item.name)
}
```

``Group`` collects views without adding layout behavior:

```swift
Group {
    Text("A")
    Text("B")
}
```

### Containers

``ScrollView`` enables vertical scrolling with an optional scroll indicator.
Use ``View/defaultScrollAnchor(_:)`` to pin to the bottom for live-updating
content:

```swift
ScrollView {
    ForEach(items) { item in
        Text(item.description)
    }
}
.defaultScrollAnchor(.bottom)
```

``Table`` displays tabular data with fixed and flexible columns:

```swift
Table(rows: data.map { row in
    [Text(row.name), Text(row.value)] as [any View]
}) {
    Table.Column.flex("Name")
    Table.Column.fixed("Value", width: 10)
}
```

``TabView`` organizes content into switchable tabs:

```swift
TabView {
    TabView.Tab("Settings") {
        SettingsView()
    }
    TabView.Tab("About") {
        AboutView()
    }
}
```

### Interactive Controls

``Button`` triggers an action when activated:

```swift
Button("Save") { save() }
```

``TextField`` accepts text input with a change callback:

```swift
TextField("Name", text: name) { newValue in
    name = newValue
}
```

``Toggle`` switches a boolean value:

```swift
Toggle("Dark mode", isOn: darkMode) { newValue in
    darkMode = newValue
}
```

``Picker`` selects from a list of options:

```swift
Picker("Color", selection: index, options: ["Red", "Green", "Blue"]) { newIndex in
    index = newIndex
}
```

### Progress

``ProgressView`` shows progress in compact or bar styles:

```swift
ProgressView("Loading")                          // Indeterminate spinner
ProgressView("Download", value: 0.65)            // Determinate bar
ProgressView("Indexing", value: 0.5)
    .progressViewStyle(.compact)                 // Compact block
```

### Commands

``CommandBar`` displays registered keyboard shortcuts as a status bar:

```swift
VStack {
    mainContent
    CommandBar()
}
```

## Topics

### Display

- ``Text``
- ``AttributedText``
- ``EmptyView``

### Layout

- ``HStack``
- ``VStack``
- ``ZStack``
- ``Spacer``
- ``Divider``
- ``Color``
- ``Canvas``

### Iteration

- ``ForEach``
- ``Group``

### Containers

- ``ScrollView``
- ``Table``
- ``TabView``

### Controls

- ``Button``
- ``TextField``
- ``Toggle``
- ``Picker``

### Progress

- ``ProgressView``
- ``ProgressViewStyle``

### Commands

- ``CommandBar``
