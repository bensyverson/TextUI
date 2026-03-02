# Modifiers

Apply visual and layout transformations to views using the modifier pattern.

## Overview

Modifiers wrap a view in a new view that intercepts sizing, rendering, or both.
They are applied using fluent methods on ``View`` and can be chained:

```swift
Text("Hello")
    .bold()
    .padding(1)
    .border(.rounded)
    .background(.blue)
```

Each modifier call returns an opaque `some View`, so the internal modifier types
are implementation details. You interact with modifiers exclusively through
the ``View`` extension methods.

## Modifier Categories

### Layout Modifiers

Layout modifiers transform the size proposal going down to the child, the size
response coming back up, or both. They change how much space a view occupies
without altering its visual content.

- **`.padding(_:)`** — Adds space around the content. Subtracts from the proposal
  and adds to the response.
- **`.frame(width:height:alignment:)`** — Proposes an exact size and reports it
  to the parent. `nil` dimensions pass through.
- **`.frame(minWidth:maxWidth:minHeight:maxHeight:alignment:)`** — Clamps the
  child's size within bounds. `.frame(maxWidth: .max)` expands a hugging view
  to fill its container.
- **`.fixedSize()`** — Replaces the proposal with `nil`, causing the child to
  report its ideal size instead of truncating.
- **`.hidden()`** — Occupies space but renders nothing.
- **`.layoutPriority(_:)`** — Higher-priority children receive space first in
  stack distribution.

### Visual Modifiers

Visual modifiers do not affect sizing. They post-process the rendered cells
to add styling or background fills.

- **`.bold()`, `.italic()`, `.dim()`, `.underline()`, `.strikethrough()`, `.inverse()`** —
  Toggle individual text attributes. Merged additively with existing styles.
- **`.foregroundColor(_:)`** — Sets the foreground color on all cells.
- **`.style(_:)`** — Applies a complete ``Style`` override.
- **`.background(_:)`** — Fills the region with a background color. Cells where
  the child has already set a background are preserved.
- **`.overlay(_:)`** — Renders additional content on top of the view.

### Text Modifiers

Text modifiers control how ``Text`` views wrap and truncate content. They flow
through the render context so all descendant `Text` views inherit the setting.

- **`.lineLimit(_:)`** — Caps the maximum number of visible lines. When content
  exceeds the limit, the boundary line shows an ellipsis. Pass `nil` to remove
  a previously set limit.
- **`.truncationMode(_:)`** — Controls where the ellipsis appears when text is
  truncated: `.tail` (default), `.head`, or `.middle`.
- **`.multilineTextAlignment(_:)`** — Aligns wrapped lines within the available
  width: `.leading` (default), `.center`, or `.trailing`.

### Lifecycle Modifiers

- **`.task {}`** — Runs an async closure when the view first appears.
  The task is automatically cancelled when the view is removed from the
  tree (e.g. when switching tabs). Useful for periodic updates, network
  polling, or any async work scoped to a view's lifetime.

### Structural Modifiers

- **`.border(_:)`** — Draws a box-drawing border, adding 2 to each axis.
  Supports `.rounded` (╭╮╰╯) and `.square` (┌┐└┘) styles.

## Sizing and Rendering Behavior

Modifiers follow a strict contract:

1. **`sizeThatFits`** — The modifier transforms the incoming proposal, passes it
   to the child, and transforms the child's response before returning it.
2. **`render`** — The modifier adjusts the region, renders the child, and
   optionally post-processes the buffer cells.

Visual modifiers (bold, foreground color, background) always render the child
first, then iterate over the cells in the region to merge style attributes.
This preserves the child's content while adding the modifier's visual effect.

## Common Patterns

### Expanding a hugging view

```swift
// Text hugs its content by default. Use maxWidth: .max to fill the container:
Text("Centered")
    .frame(maxWidth: .max)
```

### Styled bordered panel

```swift
Text("Warning!")
    .bold()
    .foregroundColor(.yellow)
    .padding(horizontal: 2, vertical: 1)
    .border(.rounded)
    .background(.red)
```

### Preventing truncation

```swift
// In a tight stack, fixedSize prevents this text from being compressed:
Text("Important label").fixedSize()
```
