# ``TextUI``

A SwiftUI-inspired framework for building expressive terminal user interfaces.

## Overview

TextUI provides a declarative, composable API for creating terminal applications.
It follows SwiftUI's design patterns — views, modifiers, layout, and state management —
adapted for the character-grid world of terminal emulators.

## Topics

### Rendering

- ``Style``
- ``Cell``
- ``Region``
- ``Buffer``
- ``Screen``

### View Protocols

- ``View``
- ``PrimitiveView``

### Views

- ``Text``
- ``EmptyView``
- ``HStack``
- ``VStack``
- ``Spacer``
- ``Divider``

### Layout

- ``Size2D``
- ``SizeProposal``
- ``HorizontalAlignment``
- ``VerticalAlignment``
- ``sizeThatFits(_:proposal:)``
- ``render(_:into:region:)``
- <doc:LayoutSystem>

### Core

- ``Friendly``
- ``ViewBuilder``
- ``ViewGroup``
