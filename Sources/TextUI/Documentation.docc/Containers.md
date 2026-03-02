# Containers

Complex container views for scrolling, tabular data, and tabbed navigation.

## Overview

TextUI provides three container primitives that go beyond simple stacking:

- **ScrollView** — A vertically scrollable viewport into child content
- **Table** — A multi-column data display with coordinated column widths
- **TabView** — A tab bar with switchable content panes

All three containers are focusable and respond to keyboard input for navigation.

### ScrollView

ScrollView wraps child content in a vertical viewport. When the content height
exceeds the viewport, the user can scroll using Up/Down/PageUp/PageDown/Home/End
keys. An optional scroll indicator (proportional thumb on a track) appears on the
right edge.

```swift
ScrollView {
    ForEach(items) { item in
        Text(item.name)
    }
}
```

Use ``View/defaultScrollAnchor(_:)`` to pin the viewport to the bottom — ideal
for live logs or chat feeds. The ScrollView will start at the bottom and
auto-follow new content, but respects the user's position if they scroll away.
Scrolling back to the bottom resumes auto-following.

```swift
ScrollView {
    ForEach(logEntries) { entry in
        Text(entry.message)
    }
}
.defaultScrollAnchor(.bottom)
```

ScrollView registers itself in the focus ring, so Tab cycles to it. When a
focusable child (e.g. a Button) inside the ScrollView is focused, scroll keys
still work via the ancestor handler chain.

### Table

Table renders a bold header row, a horizontal divider, then scrollable data rows.
Columns can be **fixed** (exact character width) or **flex** (share remaining
space equally). Columns are separated by `│` characters.

```swift
Table(rows: users.map { [$0.id, $0.name, $0.email] }) {
    Column.fixed("ID", width: 6)
    Column.flex("Name")
    Column.flex("Email")
}
```

Table is focusable and supports the same scroll keys as ScrollView for navigating
its body rows.

### TabView

TabView displays a 1-row tab bar at the top with the selected tab's content
below. The tab bar is focusable and responds to Left/Right arrow keys. The
selected tab is highlighted with inverse styling when focused, bold when not.

```swift
TabView {
    TabView.Tab("Home") {
        Text("Welcome!")
    }
    TabView.Tab("Settings") {
        SettingsPanel()
    }
}
```

The tab bar and content area are in separate focus sections, so Tab moves
between the tab bar and any focusable content within the selected tab.

## Topics

### Container Views

- ``ScrollView``
- ``Table``
- ``TabView``

### Result Builders

- ``ColumnBuilder``
- ``TabBuilder``
