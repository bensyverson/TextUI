# TextUI vs SwiftUI

Key differences for experienced SwiftUI developers.

## Overview

TextUI is modeled closely on SwiftUI, so most concepts transfer directly.
This guide highlights what's **different** so you can get productive quickly
without stumbling over assumptions that don't hold in a terminal environment.

### Coordinate System

SwiftUI works in floating-point points on a high-resolution display. TextUI
works in **integer character cells** on a fixed-width grid. All sizes,
positions, padding, and spacing values are `Int` — there are no fractional
units. A ``Size2D`` is `(width: Int, height: Int)`.

### Views Are Type-Erased

SwiftUI's `@ViewBuilder` uses generic tuple views to preserve static types.
TextUI's ``ViewBuilder`` returns `[any View]` — all children are
type-erased. This simplifies the type system (no deeply nested generics)
but means you cannot inspect child types at compile time. In practice,
you compose views the same way; the difference is invisible at the call site.

### State Management

| SwiftUI | TextUI | Notes |
|---------|--------|-------|
| `@State` | — | Not available; use `@Observed` on a class instead |
| `@StateObject` | `@Observed` | Annotate properties on a `@MainActor final class` |
| `@Binding` | Closures | Pass `onChange` closures instead of bindings |
| `@ObservedObject` | `@EnvironmentObject` | Inject with `.environmentObject()` |
| `@Published` | ``Observed`` | Every `@Observed` mutation signals a re-render |
| Equality gating | None | All mutations trigger a re-render; ``Screen``'s diff flush is the optimization layer |

> Tip: See <doc:StateManagement> for the full pattern.

### Layout

The proposal/response contract is the same — parent proposes, child responds —
but all values are integer cells. Key defaults that differ from SwiftUI:

- **Default stack spacing** is `0` (SwiftUI uses ~8 points)
- **Spacer minimum length** is `0` (SwiftUI defaults to ~8 points)
- **`.border()`** adds exactly **2 cells** to each axis (1 per side)
- **`.frame()`** takes `Int` or `Int?` parameters, not `CGFloat`

Stack allocation uses a **two-phase algorithm** (guarantee minimums, then
distribute surplus) with `.layoutPriority()` support. See
<doc:LayoutSystem> for details.

### Modifiers

Modifier chaining works identically — each call returns an opaque `some View`.
Key differences:

- **No implicit animations.** There is no `.animation()` or `withAnimation()`.
  Use ``AnimationTick`` for frame-driven animation.
- **Visual modifiers** (`.bold()`, `.dim()`, `.foregroundColor()`) post-process
  buffer cells rather than propagating through the environment.
- **`.background(_:)`** takes a ``Style/Color``, not a `View`.

### Focus and Input

TextUI is keyboard-only — there are no gestures, hover states, or pointer
events. Navigation uses:

- **Tab / Shift-Tab** — linear focus ring
- **Arrow keys** — directional within a `.focusSection()`
- **`.onKeyPress()`** — replaces gesture recognizers
- **`.onSubmit()`** — handles Enter on text fields

``FocusState`` works like SwiftUI's `@FocusState`, and `.focused(_:equals:)`
binds views to focus values. See <doc:FocusSystem> for the full model.

### Controls — What's Available

| Control | Status |
|---------|--------|
| ``Button`` | Available |
| ``TextField`` | Available (single-line) |
| ``Toggle`` | Available (checkbox-style) |
| ``Picker`` | Available (inline cycling + dropdown overlay) |
| ``ScrollView`` | Available (vertical, keyboard-driven) |
| ``Table`` | Available (fixed + flex columns) |
| ``TabView`` | Available (tab bar + content panes) |
| ``ProgressView`` | Available (spinner + bar styles) |

### What's Missing from SwiftUI

These SwiftUI concepts have **no TextUI equivalent**:

- `NavigationStack` / `NavigationLink` — use ``TabView`` or manual state
- `List` — use ``ScrollView`` with ``ForEach``, or ``Table``
- `Shape` / `Path` / `GeometryReader` — use ``Canvas`` for custom drawing
- `@State` / `@Binding` — use ``Observed`` and closures
- Implicit animations / transitions
- `Slider`, `DatePicker`, `Stepper`, `Menu`, `Alert`, `Sheet`
- SwiftUI's `Layout` protocol — use stacks and ``PrimitiveView``

### What's Added Beyond SwiftUI

These concepts exist in TextUI but have no direct SwiftUI counterpart:

- ``Canvas`` — direct buffer drawing for custom visuals
- ``CommandBar`` / command palette (Ctrl+P) — global shortcut system
- ``Table`` — built-in multi-column data display
- ``AnimationTick`` — explicit frame counter for animation
- ``PrimitiveView`` — public protocol for custom sizing and rendering
- ``AttributedText`` / ``SpanBuilder`` — styled text composition
- ``Application/quit()`` — programmatic run loop exit

## Topics

### Guides

- <doc:StateManagement>
- <doc:LayoutSystem>
- <doc:FocusSystem>
- <doc:InteractiveControls>
