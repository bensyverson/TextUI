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
- ``AttributedText``
- ``EmptyView``
- ``HStack``
- ``VStack``
- ``ZStack``
- ``Spacer``
- ``Divider``
- ``Color``
- ``Canvas``
- ``ForEach``
- ``Group``

### Modifiers

- ``BorderedView``
- <doc:Modifiers>

### Layout

- ``Size2D``
- ``SizeProposal``
- ``Alignment``
- ``HorizontalAlignment``
- ``VerticalAlignment``
- ``sizeThatFits(_:proposal:context:)``
- ``render(_:into:region:context:)``
- <doc:LayoutSystem>

### Terminal I/O

- ``Terminal``
- ``KeyEvent``
- ``KeyReader``
- ``ColorCapability``
- <doc:Terminal>

### State Management

- ``Observed``
- ``StateSignal``
- ``EnvironmentObject``
- ``RenderContext``
- ``RenderEnvironment``
- <doc:StateManagement>

### Focus System

- ``FocusState``
- ``FocusInteraction``
- ``KeyEventResult``
- ``FocusedView``
- ``FocusSectionView``
- ``DefaultFocusView``
- ``OnKeyPressView``
- ``OnSubmitView``
- <doc:FocusSystem>

### Interactive Controls

- ``Button``
- ``TextField``
- ``Toggle``
- ``Picker``
- <doc:InteractiveControls>

### App Lifecycle

- ``App``

### Core

- ``Friendly``
- ``ViewBuilder``
- ``SpanBuilder``
- ``ViewGroup``
