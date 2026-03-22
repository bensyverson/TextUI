# ``TextUI``

A SwiftUI-inspired framework for building expressive terminal user interfaces.

## Overview

TextUI provides a declarative, composable API for creating terminal applications.
It follows SwiftUI's design patterns — views, modifiers, layout, and state management —
adapted for the character-grid world of terminal emulators.

## Topics

### Guides

- <doc:GettingStarted>
- <doc:ViewCatalog>
- <doc:FocusAndInput>
- <doc:SwiftUIDifferences>

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

### View Modifiers

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
- ``InputEvent``
- ``KeyEvent``
- ``MouseEvent``
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
- <doc:FocusSystem>

### Container Views

- ``ScrollView``
- ``Table``
- ``TabView``
- ``ColumnBuilder``
- ``TabBuilder``
- <doc:Containers>

### Interactive Controls

- ``Button``
- ``TextField``
- ``Toggle``
- ``Picker``
- <doc:InteractiveControls>

### Commands

- ``KeyEquivalent``
- ``EventModifiers``
- ``KeyboardShortcut``
- ``CommandEntry``
- ``CommandGroup``
- ``CommandBuilder``
- ``CommandBar``
- ``EmptyCommands``
- <doc:CommandSystem>

### Animation & Progress

- ``AnimationTick``
- ``ProgressView``
- ``ProgressViewStyle``
- <doc:Animation>

### App Lifecycle

- ``App``
- ``Application``

### Core

- ``Friendly``
- ``ViewBuilder``
- ``SpanBuilder``
- ``ViewGroup``
