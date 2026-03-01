# TextUI: Tactical Implementation Plan

**Date**: 2026-02-28
**Build order**: Bottom-up
**Phasing**: Each phase is scoped to fit within one Plan Mode execution (~200k tokens)

## Progress

| Phase | Status | Tests | Date |
|-------|--------|-------|------|
| 1 — Rendering Foundation | **Complete** | 113 | 2026-02-28 |
| 2 — Core Protocols & Stack Layout | **Complete** | 82 (195 total) | 2026-02-28 |
| 3 — Modifiers, ZStack & Primitives | **Complete** | 123 (318 total) | 2026-02-28 |
| 4 — Terminal I/O, State & App | **Complete** | 52 (370 total) | 2026-02-28 |
| 5 — Focus & Interactive Controls | **Complete** | 68 (438 total) | 2026-02-28 |
| 6 — ScrollView, Table & TabView | **Complete** | 46 (484 total) | 2026-03-01 |
| 7a — Commands, Animation & ProgressView | **Complete** | 62 (546 total) | 2026-03-01 |
| 7b — Conditional Views & ProgressView Refactor | **Complete** | 7 (553 total) | 2026-03-01 |
| 7c — CommandPalette, Demo App & Docs | **Complete** | 14 (567 total) | 2026-03-01 |

## Prerequisites

All design decisions are captured in the [vision document](2026-02-28-tui-framework-vision.md) and the [SwiftUI layout reference](2026-02-28-swiftui-layout.md). Key decisions resolved during pre-planning:

- **State**: `@Observed` property wrapper on `@MainActor` state classes; auto-signals re-render
- **Concurrency**: `@MainActor` for render engine, views, state — no custom actor
- **Views**: `Sendable` only; data types conform to `Friendly`
- **ViewBuilder**: `[any View]` (type-erased), no tuple views
- **PrimitiveView**: Public protocol
- **Defaults**: Stack spacing = 0, Spacer minLength = 0
- **Colors**: Auto-detect capability in App harness
- **Testing**: Unit tests + inline buffer assertions; no external snapshot files
- **Reference code**: `~/git/OperativeKit/Examples/OK/Sources/OKCore/TUI/`

---

## Phase 1 — Rendering Foundation ✅

**Status**: Complete (2026-02-28) — 113 tests, 7 source files
**Goal**: Build the lowest layer — the character grid that everything renders into. After this phase, we can write cells into buffers, diff them, and generate ANSI output. Every subsequent phase depends on this.

### Files to create

| File | Description | Est. lines |
|------|-------------|------------|
| `Sources/TextUI/Friendly.swift` | `typealias Friendly = Codable & Hashable & Equatable & Sendable` | 5 |
| `Sources/TextUI/Core/DisplayWidth.swift` | `Character.displayWidth`, `String.displayWidth` — emoji, CJK, ZWJ, combining marks | 120 |
| `Sources/TextUI/Rendering/Style.swift` | `Style` struct: fg/bg color, bold/dim/italic/underline/inverse/strikethrough. `Style.Color` enum (basic 16, 256-palette, RGB). ANSI SGR sequence generation. Delta-optimized output. | 250 |
| `Sources/TextUI/Rendering/Cell.swift` | `Cell` struct: char + style + `isContinuation` flag. Default is space with plain style. | 30 |
| `Sources/TextUI/Rendering/Region.swift` | `Region` struct: row, col, width, height. Subregion, inset, iteration helpers. | 60 |
| `Sources/TextUI/Rendering/Buffer.swift` | 2D grid of `Cell`s. Display-width-aware `write()`. Wide characters produce continuation cells. Fill, clear, line-drawing operations. | 220 |
| `Sources/TextUI/Rendering/Screen.swift` | Double-buffered rendering. `clear()` resets back buffer, `flush()` diffs against front and emits ANSI for changed cells only. Resize support. | 130 |

### Tests

| File | Covers |
|------|--------|
| `Tests/TextUITests/Core/DisplayWidthTests.swift` | ASCII, emoji, CJK, ZWJ sequences, combining marks, regional indicators, keycap sequences, variation selectors |
| `Tests/TextUITests/Rendering/StyleTests.swift` | Color rendering, SGR generation, delta optimization, style merging |
| `Tests/TextUITests/Rendering/CellTests.swift` | Default cell, continuation flag, equality |
| `Tests/TextUITests/Rendering/RegionTests.swift` | Subregion, inset, bounds checking |
| `Tests/TextUITests/Rendering/BufferTests.swift` | Write ASCII, write wide chars (continuation cells), clipping, fill, clear, overwrite rules (narrow over wide, wide over narrow, wide at edge) |
| `Tests/TextUITests/Rendering/ScreenTests.swift` | Differential flush correctness, resize |

### Definition of done
- `swift test` passes
- `swiftformat . --lint` passes
- A `Buffer` can be created, written to with mixed ASCII/emoji/CJK, and its contents inspected cell-by-cell
- `Screen.flush()` produces correct ANSI output for changed cells only
- DocC annotations on all public types and methods

### Notes
- Reference `~/git/OperativeKit/Examples/OK/Sources/OKCore/TUI/Buffer/` and `Terminal/Style.swift` for proven implementations
- Cell, Region, Screen can be carried forward with minor modifications
- Buffer.write() is the biggest change — must use `Character.displayWidth` for cursor advancement
- Add a `Buffer.text` computed property (or similar) that returns the buffer contents as a plain string, for use in test assertions

---

## Phase 2 — Core Protocols & Stack Layout ✅

**Status**: Complete (2026-02-28) — 82 new tests (195 total), 17 source files, 13 test files
**Goal**: Establish the `View` / `PrimitiveView` protocol hierarchy, the `SizeProposal` / `Size2D` negotiation types, `@ViewBuilder`, and the rendering engine's dispatch logic. Implement the first primitives: `Text`, `Spacer`, `EmptyView`, `Divider`. Implement `HStack` and `VStack` with the full flexibility-sorted greedy algorithm. After this phase, we can compose declarative layouts like `HStack { Text("left"); Spacer(); Text("right") }` and render them into buffers.

### Implementation decisions

1. **`@ViewBuilder` is NOT on the `View` protocol's `body` property.** Putting `@ViewBuilder` on the protocol causes `Never: View` conformance to fail — Swift's result builder tries to transform `fatalError()` into a `ViewGroup`, which can't be converted to `Never`. Users add `@ViewBuilder` to their own `body` properties when they need multi-view bodies.

2. **`Never: View` uses plain conformance** (not `@retroactive`), since `View` is defined in the same module. The `@retroactive` attribute is only for conforming to protocols from other modules.

3. **`ViewGroup` wraps `[any View]`** as the pragmatic equivalent of the decisions doc's "`[any View]` return type." Swift can't extend `Array` with `where Element == any View` because `any View` is an existential. `ViewGroup` conforms to `PrimitiveView` and is layout-transparent — stacks and the render engine flatten it.

4. **File organization diverged from plan:** All views placed under `Sources/TextUI/Views/` (not split across `Content/` and `Layout/`). Alignment enums split into separate files (`HorizontalAlignment.swift`, `VerticalAlignment.swift`) rather than a single `Alignment.swift`. Added `StackLayout.swift` in Core for the shared algorithm. No combined `Alignment` type yet (not needed).

5. **`StackLayout` is an enum namespace** shared by HStack and VStack, with axis-parameterized helpers. This avoids code duplication while keeping each stack's init and render logic self-contained.

6. **Text does NOT wrap in Phase 2** — only truncation. Wrapping requires width-dependent height calculation, which is Phase 3 scope.

7. **Render engine uses free functions** (`sizeThatFits(_:proposal:)` and `render(_:into:region:)`) with existential dispatch via `as? any PrimitiveView`. Module-qualified calls (`TextUI.render(...)`) are needed inside PrimitiveView implementations to avoid ambiguity with the instance method.

### Files created

| File | Description |
|------|-------------|
| `Sources/TextUI/Core/Size2D.swift` | `Size2D` value type |
| `Sources/TextUI/Core/SizeProposal.swift` | `SizeProposal` with four proposal modes |
| `Sources/TextUI/Core/HorizontalAlignment.swift` | `.leading`, `.center`, `.trailing` |
| `Sources/TextUI/Core/VerticalAlignment.swift` | `.top`, `.center`, `.bottom` |
| `Sources/TextUI/Core/View.swift` | `View` protocol |
| `Sources/TextUI/Core/PrimitiveView.swift` | `PrimitiveView` protocol |
| `Sources/TextUI/Core/Never+View.swift` | `Never` conformance to `View` |
| `Sources/TextUI/Core/ViewGroup.swift` | Structural view holding `[any View]` |
| `Sources/TextUI/Core/ViewBuilder.swift` | `@resultBuilder` for declarative syntax |
| `Sources/TextUI/Core/RenderEngine.swift` | Free functions for sizing/rendering dispatch |
| `Sources/TextUI/Core/StackLayout.swift` | Shared flexibility-sorted greedy algorithm |
| `Sources/TextUI/Views/EmptyView.swift` | Zero-size, no-render view |
| `Sources/TextUI/Views/Text.swift` | Hugging text view with style |
| `Sources/TextUI/Views/Spacer.swift` | Axis-aware expanding view |
| `Sources/TextUI/Views/Divider.swift` | Horizontal/vertical separator |
| `Sources/TextUI/Views/HStack.swift` | Horizontal stack |
| `Sources/TextUI/Views/VStack.swift` | Vertical stack |

### Tests created

| File | Tests | Covers |
|------|-------|--------|
| `Tests/TextUITests/Core/Size2DTests.swift` | 5 | Init, .zero, Equatable, Hashable, Codable |
| `Tests/TextUITests/Core/SizeProposalTests.swift` | 9 | Static constants, inset (nil/clamp), replacingUnspecified, Codable |
| `Tests/TextUITests/Core/AlignmentTests.swift` | 4 | Cases exist, Codable round-trips |
| `Tests/TextUITests/Core/ViewProtocolTests.swift` | 4 | PrimitiveView dispatch, composite body traversal |
| `Tests/TextUITests/Core/ViewBuilderTests.swift` | 9 | buildBlock (0/1/3), buildOptional, buildArray, if/else, for loop, ViewGroup sizing |
| `Tests/TextUITests/Views/EmptyViewTests.swift` | 2 | Always zero, renders nothing |
| `Tests/TextUITests/Views/TextTests.swift` | 12 | Ideal/min/max/concrete sizing, CJK, render, truncation, style, offset, height clip |
| `Tests/TextUITests/Core/RenderEngineTests.swift` | 7 | Primitive/composite/ViewGroup dispatch, empty region |
| `Tests/TextUITests/Views/SpacerTests.swift` | 8 | Both/horizontal/vertical axis, minLength, max, renders nothing |
| `Tests/TextUITests/Views/DividerTests.swift` | 7 | Horizontal/vertical sizing, min height/width, render, empty region |
| `Tests/TextUITests/Views/HStackTests.swift` | 11 | Sizing, spacing, Spacer pushes, alignment (top/center/bottom), flexibility, Divider, empty |
| `Tests/TextUITests/Views/VStackTests.swift` | 10 | Sizing, spacing, Spacer absorbs, alignment (leading/center/trailing), Divider, empty |
| `Tests/TextUITests/Views/LayoutIntegrationTests.swift` | 7 | Status bar, title-divider-body, nested stacks, composite views, four proposal modes, multiple spacers |

### Documentation added
- `Sources/TextUI/Documentation.docc/LayoutSystem.md` — proposal/response contract, four proposal modes, three view categories, stack algorithm overview
- Updated `Sources/TextUI/Documentation.docc/TextUI.md` — added View Protocols, Views, Layout, and Core topic groups

### Definition of done ✅
- ✅ `HStack { Text("left"); Spacer(); Text("right") }` renders correctly in an 80-column buffer
- ✅ `VStack { Text("Title"); Divider.horizontal; Text("Body") }` renders correctly
- ✅ Nested stacks work: `VStack { HStack { ... }; HStack { ... } }`
- ✅ All sizing responses match the spec for all four proposal modes
- ✅ All tests pass (195), linting passes
- ✅ DocC annotations on all public types and methods

---

## Phase 3 — Modifiers, ZStack & Remaining Primitives ✅

**Status**: Complete (2026-02-28) — 123 new tests (318 total), 20 source files, 15 test files
**Goal**: Implement all view modifiers (padding, frame, fixedSize, background, foreground, styled, border, hidden, overlay, layoutPriority), plus `ZStack`, `Color`, `ForEach`, `Group`, `AttributedText`, and `Canvas`. After this phase, the full declarative modifier chain works: `.bold().padding(1).border(.rounded).background(.blue)`.

### Implementation decisions

1. **`BorderedView` is public** — The `BorderStyle` enum is nested inside `BorderedView` per convention, and since it's referenced in the public `View.border()` method signature, `BorderedView` must be public. Its initializer remains internal, so users interact only through the `.border()` modifier.

2. **`BackgroundView` post-processes** — Renders child first, then iterates cells where `bg == nil` and sets the background color. This fills gaps while preserving explicitly-set backgrounds from child views.

3. **`StyledView` merges additively** — Uses `Style.merging()` to OR boolean attributes and replace colors only when the override has non-nil values.

4. **`FlexFrameView` asymmetric clamping** — Only-max case: frame reports `min(proposed, max)` as its width, which is why `.frame(maxWidth: .max)` expands a hugging view. Only-min case: frame reports `max(response, min)`.

5. **`LayoutTransparent` protocol** replaces hardcoded `ViewGroup` checks in `flattenChildren`. `ViewGroup`, `ForEach`, and `Group` all conform.

6. **Priority sort in `StackLayout`** — `layoutGreedy` sorts by priority descending first, then flexibility ascending within same priority. `PrioritizedView` carries a `Double` priority (default 0, matching SwiftUI convention).

7. **`SpanBuilder` is a separate result builder** — Not nested inside `AttributedText` since result builders must be top-level types or enum namespaces. It builds `[AttributedText.TextSpan]`.

### Files created

| File | Description |
|------|-------------|
| `Sources/TextUI/Core/Alignment.swift` | Combined H+V alignment with 9 static constants and offset computation |
| `Sources/TextUI/Core/Style+Merging.swift` | Additive style merging (OR booleans, replace non-nil colors) |
| `Sources/TextUI/Core/View+Modifiers.swift` | All modifier methods on `View` extension |
| `Sources/TextUI/Core/LayoutTransparent.swift` | Protocol for layout-transparent views |
| `Sources/TextUI/Modifiers/PaddedView.swift` | Padding modifier |
| `Sources/TextUI/Modifiers/FixedSizeView.swift` | Fixed size modifier |
| `Sources/TextUI/Modifiers/HiddenView.swift` | Hidden modifier |
| `Sources/TextUI/Modifiers/FrameView.swift` | Fixed frame modifier |
| `Sources/TextUI/Modifiers/FlexFrameView.swift` | Flexible frame with min/max clamping |
| `Sources/TextUI/Modifiers/StyledView.swift` | Style post-processing modifier |
| `Sources/TextUI/Modifiers/BackgroundView.swift` | Background color modifier |
| `Sources/TextUI/Modifiers/OverlayView.swift` | Overlay modifier |
| `Sources/TextUI/Modifiers/BorderedView.swift` | Box-drawing border modifier |
| `Sources/TextUI/Modifiers/PrioritizedView.swift` | Layout priority modifier |
| `Sources/TextUI/Views/ZStack.swift` | Back-to-front overlay stack |
| `Sources/TextUI/Views/Color.swift` | Greedy solid color fill view |
| `Sources/TextUI/Views/ForEach.swift` | Layout-transparent collection iteration |
| `Sources/TextUI/Views/Group.swift` | Layout-transparent grouping container |
| `Sources/TextUI/Views/AttributedText.swift` | Mixed-style text spans |
| `Sources/TextUI/Views/Canvas.swift` | Custom drawing escape hatch |

### Files modified

| File | Change |
|------|--------|
| `Sources/TextUI/Core/StackLayout.swift` | `flattenChildren` uses `LayoutTransparent`; `layoutGreedy` sorts by priority |
| `Sources/TextUI/Core/ViewGroup.swift` | Conforms to `LayoutTransparent` |

### Tests created

| File | Tests | Covers |
|------|-------|--------|
| `Tests/TextUITests/Modifiers/PaddingTests.swift` | 7 | Uniform, per-side, H/V, nil preservation, render offset, zero, tight proposal |
| `Tests/TextUITests/Modifiers/FixedSizeTests.swift` | 5 | Both axes, horizontal-only, vertical-only, neither, render |
| `Tests/TextUITests/Modifiers/HiddenTests.swift` | 3 | Same size, renders nothing, ideal size |
| `Tests/TextUITests/Modifiers/FrameTests.swift` | 7 | Exact width/height, both, nil passthrough, center/topLeading/bottomTrailing alignment, clips |
| `Tests/TextUITests/Modifiers/FlexFrameTests.swift` | 9 | Min+max, only min, only max, maxWidth .max expands, maxHeight .max, nil passthrough, alignment, height constraints |
| `Tests/TextUITests/Modifiers/VisualModifierTests.swift` | 17 | Bold, fg, chaining, preserves child style, overrides, size unchanged, style(), bg fill, bg preserves, bg size, overlay render, overlay sizing, dim, italic, underline, strikethrough, inverse |
| `Tests/TextUITests/Modifiers/BorderTests.swift` | 8 | Rounded corners, square corners, edges, content inside, sizing +2, too small, default rounded, border with padding |
| `Tests/TextUITests/Modifiers/PriorityTests.swift` | 5 | Higher priority first, default 0, size unchanged, spacer interaction, multiple priorities |
| `Tests/TextUITests/Views/ZStackTests.swift` | 7 | Same proposal, max size, center default, topLeading, render order, empty, multi-line |
| `Tests/TextUITests/Views/ColorTests.swift` | 4 | Greedy sizing, ideal zero, solid bg, minimum zero |
| `Tests/TextUITests/Views/ForEachTests.swift` | 5 | VStack all items, empty collection, layout transparent, multi-view closures, HStack |
| `Tests/TextUITests/Views/GroupTests.swift` | 3 | Layout transparent in VStack, empty Group, bare usage |
| `Tests/TextUITests/Views/AttributedTextTests.swift` | 7 | Multi-span sizing, truncation, mixed styles, empty, single span, ideal size, render truncation |
| `Tests/TextUITests/Views/CanvasTests.swift` | 4 | Greedy sizing, ideal zero, draw executes, region correct, canvas in frame |
| `Tests/TextUITests/Modifiers/ModifierChainTests.swift` | 10 | padding.border.background, ZStack Color+Text, maxWidth expands, fixedSize, priority, ForEach, bold.padding.border, multiple visual, frame alignment border, hidden in stack |

### Documentation added
- `Sources/TextUI/Documentation.docc/Modifiers.md` — Modifier pattern, sizing/rendering behavior, layout/visual/structural categories, common patterns
- Updated `Sources/TextUI/Documentation.docc/TextUI.md` — Added Modifiers topic group, new views (ZStack, Color, Canvas, ForEach, Group, AttributedText), Alignment, SpanBuilder

### Definition of done ✅
- ✅ `Text("Hi").padding(1).border(.rounded).background(.blue)` sizes (6×5) and renders correctly
- ✅ `ZStack { Color(.blue); Text("Overlay") }` renders correctly
- ✅ `.frame(maxWidth: .max)` makes a hugging view fill its container
- ✅ `.fixedSize()` prevents truncation
- ✅ `.layoutPriority()` affects stack distribution
- ✅ `ForEach` in a VStack renders all items
- ✅ All tests pass (318), linting passes
- ✅ DocC coverage complete

---

## Phase 4 — Terminal I/O, State & App Lifecycle ✅

**Status**: Complete (2026-02-28) — 52 new tests (370 total)
**Goal**: Build the terminal control layer (raw mode, alternate screen, resize), keyboard input parsing, the `@Observed` state system, `.environmentObject()`, and the `App` protocol with its run loop. After this phase, a minimal interactive app can launch, display views, respond to keyboard input, and re-render on state changes.

### Files to create

| File | Description | Est. lines |
|------|-------------|------------|
| `Sources/TextUI/Terminal/Terminal.swift` | Static terminal control: raw mode, alternate screen, cursor visibility, size queries (ioctl), signal handling (SIGWINCH, SIGINT/SIGTERM). Cross-platform (Darwin/Glibc). | 130 |
| `Sources/TextUI/Terminal/KeyEvent.swift` | Parsed key event enum: printable chars, arrows, home/end, page up/down, function keys, ctrl+key, escape. Full CSI/SS3 escape sequence parser. | 200 |
| `Sources/TextUI/Terminal/KeyReader.swift` | Reads stdin on background thread, parses into KeyEvents, exposes `AsyncStream<KeyEvent>`. Escape timeout handling. | 80 |
| `Sources/TextUI/Terminal/ColorCapability.swift` | Auto-detect terminal color support from TERM/COLORTERM/NO_COLOR env vars. `ColorCapability` enum: basic16, palette256, truecolor. | 50 |
| `Sources/TextUI/State/Observed.swift` | `@Observed` property wrapper. On `didSet`, sends signal to a shared `AsyncStream<Void>` (the state change channel). `@MainActor`. | 60 |
| `Sources/TextUI/State/EnvironmentObject.swift` | `.environmentObject()` modifier and `@EnvironmentObject` property wrapper (or `@Environment`-based access). Object flows down the view tree. | 80 |
| `Sources/TextUI/App/App.swift` | `App` protocol: `body: some View`, `commands: some Commands`. `@main` support. Terminal lifecycle (enter raw mode, alternate screen on launch; restore on exit). | 60 |
| `Sources/TextUI/App/RunLoop.swift` | Merges key events, state change signals, resize signals, and ticks into a single event stream. Processes sequentially on `@MainActor`. Drives view evaluation → layout → render → flush cycle. | 160 |

### Tests

| File | Covers |
|------|--------|
| `Tests/TextUITests/Terminal/KeyEventTests.swift` | Parsing: printable chars, arrow keys, ctrl combos, escape sequences, UTF-8 characters |
| `Tests/TextUITests/Terminal/ColorCapabilityTests.swift` | Detection from env vars: xterm-256color, truecolor, NO_COLOR, dumb terminal |
| `Tests/TextUITests/State/ObservedTests.swift` | Property mutation triggers signal. Multiple properties. Signal coalescing. |
| `Tests/TextUITests/State/EnvironmentObjectTests.swift` | Object injection, retrieval by descendant views, missing object error |

### Definition of done
- A minimal `App` struct can launch, display a `Text("Hello")`, and exit on Ctrl+C
- `@Observed` property changes trigger re-render
- `.environmentObject()` makes an object accessible to descendant views
- KeyReader correctly parses arrow keys, printable characters, and ctrl combos
- Color capability detection works for common TERM values
- All tests pass, linting passes
- DocC annotations on all public types and methods

### Notes
- Reference `~/git/OperativeKit/Examples/OK/Sources/OKCore/TUI/Terminal/` for proven Terminal, KeyEvent, KeyReader implementations
- The run loop merges: `AsyncStream<KeyEvent>`, `AsyncStream<Void>` (state changes), `AsyncStream<(Int, Int)>` (resize via SIGWINCH), and a tick timer
- The `@Observed` → `AsyncStream<Void>` signal channel needs debouncing so multiple rapid mutations produce one re-render
- Environment object storage travels as a dictionary alongside the render traversal — threaded through `sizeThatFits` and `render` calls

---

## Phase 5 — Focus System & Interactive Controls ✅

**Status**: Complete (2026-02-28) — 68 new tests (438 total)
**Goal**: Build the focus management system (`FocusState`, `FocusStore`, focus ring, Tab/Shift-Tab navigation) and all interactive controls (`Button`, `TextField`, `Toggle`, `Picker`). Wire key events through the focus system. After this phase, interactive forms work: Tab between fields, type in text fields, press Enter on buttons.

### Files to create

| File | Description | Est. lines |
|------|-------------|------------|
| `Sources/TextUI/Focus/FocusState.swift` | `@FocusState<Value>` property wrapper. Bool and Hashable variants. Two-way binding to FocusStore. | 60 |
| `Sources/TextUI/Focus/FocusStore.swift` | Engine-internal: tracks focus ring (ordered list of focusable view IDs), current focus, handles Tab/Shift-Tab cycling. | 100 |
| `Sources/TextUI/Focus/FocusModifiers.swift` | `.focused()`, `.focusable()`, `.defaultFocus()`. Registers views in the focus ring during render traversal. | 80 |
| `Sources/TextUI/Focus/FocusGroup.swift` | Automatic focus groups in stacks. HStack: Left/Right arrows. VStack: Up/Down arrows. | 60 |
| `Sources/TextUI/Focus/FocusSection.swift` | `.focusSection()` — groups focusable children for directional navigation. | 50 |
| `Sources/TextUI/Input/KeyEquivalent.swift` | `KeyEquivalent` struct: character keys and `NamedKey` enum (return, escape, arrows, etc.) | 40 |
| `Sources/TextUI/Input/EventModifiers.swift` | `EventModifiers` OptionSet: `.control`, `.shift`, `.option` | 20 |
| `Sources/TextUI/Input/KeyboardShortcut.swift` | `KeyboardShortcut` struct: key + modifiers. `.defaultAction`, `.cancelAction`. | 30 |
| `Sources/TextUI/Input/KeyPress.swift` | `KeyPress` event type with `.handled` / `.ignored` result for event propagation. | 20 |
| `Sources/TextUI/Modifiers/KeyPressView.swift` | `.onKeyPress()` modifier — handles key events with propagation. | 40 |
| `Sources/TextUI/Modifiers/SubmitView.swift` | `.onSubmit()` modifier — fires on Enter in text fields. | 30 |
| `Sources/TextUI/Modifiers/ShortcutView.swift` | `.keyboardShortcut()` modifier — registers shortcut, transparent to layout. | 35 |
| `Sources/TextUI/Controls/Button.swift` | Label + action. Focusable (`.activate`). Enter/Space triggers. Focus styling (inverse). | 60 |
| `Sources/TextUI/Controls/TextField.swift` | Single-line text input. Focusable (`.edit`). Cursor, editing, placeholder. Greedy width. | 150 |
| `Sources/TextUI/Controls/Toggle.swift` | `[x]` / `[ ]` checkbox + label. Focusable (`.activate`). Space toggles. | 50 |
| `Sources/TextUI/Controls/Picker.swift` | Inline selection: `◀ Option ▶`. Focusable (`.activate`). Up/Down cycles options. | 70 |

### Tests

| File | Covers |
|------|--------|
| `Tests/TextUITests/Focus/FocusStoreTests.swift` | Focus ring construction, Tab/Shift-Tab cycling, programmatic focus changes |
| `Tests/TextUITests/Focus/FocusGroupTests.swift` | Automatic groups in HStack/VStack, arrow key navigation |
| `Tests/TextUITests/Focus/FocusStateTests.swift` | Bool binding, Hashable binding, two-way sync |
| `Tests/TextUITests/Controls/ButtonTests.swift` | Sizing, focus styling, action trigger on Enter/Space |
| `Tests/TextUITests/Controls/TextFieldTests.swift` | Sizing (greedy width), cursor movement, character input, backspace, placeholder rendering |
| `Tests/TextUITests/Controls/ToggleTests.swift` | Sizing, checked/unchecked rendering, Space toggle |
| `Tests/TextUITests/Controls/PickerTests.swift` | Sizing, option display, Up/Down cycling |
| `Tests/TextUITests/Input/KeyEventRoutingTests.swift` | Event priority: focused view → propagation → shortcuts → focus navigation |

### Definition of done
- A form with TextField, Button, and Toggle: Tab navigates between them, typing works in TextField, Enter submits
- `.onKeyPress()` captures and propagates events correctly
- `.keyboardShortcut()` triggers regardless of focus
- Focus styling (inverse for focused Button, cursor for focused TextField) renders correctly
- All tests pass, linting passes
- DocC annotations on all public types and methods

---

## Phase 6 — ScrollView, Table & TabView ✅

**Status**: Complete (2026-03-01) — 46 new tests (484 total)
**Goal**: Implement the three complex container primitives. ScrollView provides vertical scrolling with keyboard navigation and optional scroll indicator. Table coordinates column widths across rows. TabView provides a tab bar with content switching. After this phase, all layout containers from the vision doc are implemented.

### Files to create

| File | Description | Est. lines |
|------|-------------|------------|
| `Sources/TextUI/Layout/ScrollView.swift` | Vertical scrolling viewport. Proposes nil on scroll axis. Measures children, builds offset array. Clips to visible region. Keyboard: Up/Down scroll, Page Up/Down, Home/End. Optional scroll indicator. | 200 |
| `Sources/TextUI/Layout/Table.swift` | Multi-column data display. `Column` type with `.fixed(Int)` and `.flex()` widths. Measures all rows, runs HStack algorithm for column widths, renders with shared widths. Wraps ScrollView for vertical scrolling. | 220 |
| `Sources/TextUI/Controls/TabView.swift` | Tab container: tab bar (1 row) + content area. `Tab` type with label, id, content. Left/Right switches tabs. Tab bar renders with selection highlighting. Greedy on both axes. | 180 |

### Tests

| File | Covers |
|------|--------|
| `Tests/TextUITests/Layout/ScrollViewTests.swift` | Content taller than viewport, scroll offset, clipping, keyboard navigation, variable-height children, scroll indicator |
| `Tests/TextUITests/Layout/TableTests.swift` | Fixed columns, flex columns, mixed, column width coordination across rows, scrolling |
| `Tests/TextUITests/Controls/TabViewTests.swift` | Tab switching, tab bar rendering, content area sizing, active tab display |

### Definition of done
- ScrollView with 100 items in a 24-row viewport: scrolls correctly, clips correctly, Page Up/Down work
- Table with fixed + flex columns: column widths consistent across all rows
- TabView with 3 tabs: Left/Right switches tabs, correct tab is rendered, tab bar highlights active tab
- All tests pass, linting passes
- DocC annotations on all public types and methods

---

## Phase 7a — Commands Infrastructure, Animation & ProgressView ✅

**Status**: Complete (2026-03-01) — 62 new tests (546 total), 16 source files, 6 test files
**Goal**: Build the command system infrastructure (KeyEquivalent, KeyboardShortcut, CommandGroup, CommandRegistry, CommandBar), the animation system (`@AnimationTick`, `AnimationTracker`), and ProgressView. After this phase, apps can define global keyboard shortcuts, display a command bar, and show animated progress indicators.

### Implementation decisions

1. **ProgressView is a `PrimitiveView`, not a composite view.** The plan called for a composite view using `@AnimationTick` in `body`, but Swift's `some View` return type requires a single concrete type. ProgressView's `body` needs `if/else` branches returning different types (e.g., `HStack` vs `Canvas`, `Text` vs `Canvas`). TextUI's `@ViewBuilder` returns `ViewGroup` (type-erased `[any View]`), not `_ConditionalContent<A, B>`, so the compiler can't infer the opaque type. Making ProgressView a PrimitiveView sidesteps this entirely — it calls `animationTracker.requestAnimation()` directly in `render()` instead of via `@AnimationTick`. This works identically; the only difference is ProgressView can't be decomposed by the render engine. **Phase 7b adds `ConditionalView` to fix this systemically.**

2. **`@AnimationTick` works but is limited to views with uniform body types.** It reads from `RenderEnvironment.current` (a `@TaskLocal`) just like `@EnvironmentObject`. Any view whose `body` doesn't branch on different return types can use it.

3. **CommandGroup entry extraction** walks the flattened `ViewGroup` children, unwrapping `KeyboardShortcutView(Button(...))` pairs. Only `Button` views with `Text` labels are supported — custom label views fall back to "Command".

4. **Command shortcuts are matched before focus routing** in `RunLoop.handleKey()`. This ensures global shortcuts work regardless of focus state. Ctrl+P toggles `isPaletteVisible` for the future CommandPalette.

5. **CommandBar skips entries without shortcuts** when rendering. The `isFirst` tracking ensures no gap before the first rendered entry even if earlier entries in the list have no shortcut.

6. **`CommandBuilder` is simpler than `SpanBuilder`** — just `buildBlock` and `buildArray`, no `buildExpression` (which caused type conflicts with the variadic `buildBlock`).

### Files created

| File | Description |
|------|-------------|
| `Sources/TextUI/Commands/KeyEquivalent.swift` | Character or named key, custom Codable for Character |
| `Sources/TextUI/Commands/EventModifiers.swift` | OptionSet: control, shift, option |
| `Sources/TextUI/Commands/KeyboardShortcut.swift` | Key + modifiers, `.defaultAction`, `.cancelAction` |
| `Sources/TextUI/Commands/KeyboardShortcut+KeyEvent.swift` | `matches(_:)` and `displayString` |
| `Sources/TextUI/Commands/CommandEntry.swift` | Name, group, shortcut, action |
| `Sources/TextUI/Commands/CommandGroup.swift` | Named group, extracts entries from ViewBuilder |
| `Sources/TextUI/Commands/CommandBuilder.swift` | Result builder for `[CommandGroup]` |
| `Sources/TextUI/Commands/EmptyCommands.swift` | Default empty commands |
| `Sources/TextUI/Commands/KeyboardShortcutView.swift` | Transparent modifier carrying a shortcut |
| `Sources/TextUI/Commands/CommandRegistry.swift` | Stores groups, matches shortcuts |
| `Sources/TextUI/Commands/CommandBar.swift` | Status bar rendering shortcuts |
| `Sources/TextUI/State/AnimationTick.swift` | `@propertyWrapper` reading tick from context |
| `Sources/TextUI/State/AnimationTracker.swift` | Frame counter with needsAnimation flag |
| `Sources/TextUI/Views/ProgressView.swift` | PrimitiveView: spinner + bar, compact + full |
| `Sources/TextUI/Views/ProgressViewStyle.swift` | `.compact` and `.bar(showPercent:)` |
| `Sources/TextUI/Modifiers/ProgressViewStyleView.swift` | Threads style through RenderContext |

### Files modified

| File | Change |
|------|--------|
| `Sources/TextUI/Core/RenderContext.swift` | Added `animationTracker`, `commandRegistry`, `progressViewStyle` |
| `Sources/TextUI/App/RunLoop.swift` | Animation timer (33ms tick task), command registry, shortcut matching before focus routing, Ctrl+P toggle |
| `Sources/TextUI/App/App.swift` | Added `commands: [CommandGroup]` property with default `[]` |
| `Sources/TextUI/Core/View+Modifiers.swift` | Added `.keyboardShortcut()` (3 overloads) and `.progressViewStyle()` |

### Tests created

| File | Tests | Covers |
|------|-------|--------|
| `Tests/TextUITests/Commands/KeyboardShortcutTests.swift` | 18 | KeyEquivalent init/equality/Codable, KeyboardShortcut matching (ctrl, shift+tab, bare char, case-insensitive), displayString, static shortcuts |
| `Tests/TextUITests/Commands/CommandGroupTests.swift` | 7 | Entry extraction, shortcut unwrapping, multiple entries, callable actions, CommandBuilder, EmptyCommands |
| `Tests/TextUITests/Commands/CommandRegistryTests.swift` | 8 | Registration, shortcut matching (hit/miss), allEntries, first-wins priority, palette toggle, action callable, no-shortcut entries |
| `Tests/TextUITests/Commands/CommandBarTests.swift` | 8 | Sizing, rendering with styles, group filtering, truncation, empty registry, no-registry safety, no-shortcut skip |
| `Tests/TextUITests/State/AnimationTickTests.swift` | 6 | AnimationTracker (beginFrame/request/tick), AnimationTick reads context, requests animation, returns 0 without tracker |
| `Tests/TextUITests/Views/ProgressViewTests.swift` | 15 | Compact indeterminate (sizing/render/tick variation), compact determinate (0/0.5/1.0), bar determinate (sizing/render/percent), bar indeterminate, with label, default styles, style overrides |

### Documentation added
- `Sources/TextUI/Documentation.docc/CommandSystem.md` — Command system overview, key routing order, shortcut API, CommandBar
- `Sources/TextUI/Documentation.docc/Animation.md` — `@AnimationTick`, ProgressView, ProgressViewStyle
- Updated `Sources/TextUI/Documentation.docc/TextUI.md` — Added Commands and Animation & Progress topic groups

### Definition of done ✅
- ✅ `CommandGroup("File") { Button("Save") { ... }.keyboardShortcut("s", modifiers: .control) }` produces correct `CommandEntry`
- ✅ `CommandBar` renders registered shortcuts with bold/inverse shortcut + dim name
- ✅ `ProgressView()` animates spinner, `ProgressView(value: 0.5)` renders bar
- ✅ `@AnimationTick` signals the run loop to start/stop the animation timer
- ✅ All tests pass (546), linting passes
- ✅ DocC generates without warnings

---

## Phase 7b — Conditional Views ✅

**Status**: Complete (2026-03-01) — 7 new tests (553 total)
**Goal**: Add `ConditionalView` support so that `if/else` branches in a view's `body` can return different view types. This is a foundational gap — without it, any composite view that branches on state or configuration must fall back to `PrimitiveView`. After this phase, ProgressView can be refactored to a composite view, and user views can freely use conditionals in `body`.

### Problem

TextUI's `@ViewBuilder` returns `ViewGroup` (a type-erased `[any View]` array). SwiftUI's `@ViewBuilder` returns `_ConditionalContent<TrueContent, FalseContent>` for `if/else`, which preserves type identity. Without conditional content, Swift can't infer `some View` when branches return different concrete types:

```swift
// This fails to compile:
var body: some View {
    if showSpinner {
        Text("⠋")      // returns Text
    } else {
        Canvas { ... }  // returns Canvas — different type!
    }
}
```

### Approach

Add `buildEither(first:)` and `buildEither(second:)` to `ViewBuilder`, returning a `ConditionalView<First, Second>` that wraps either branch. Also add `buildOptional` returning an optional-wrapping view.

### Files to create

| File | Description | Est. lines |
|------|-------------|------------|
| `Sources/TextUI/Core/ConditionalView.swift` | `ConditionalView<First: View, Second: View>: PrimitiveView` — stores `.first(First)` or `.second(Second)`, delegates sizing/rendering | 50 |
| `Sources/TextUI/Core/OptionalView.swift` | `OptionalView<Wrapped: View>: PrimitiveView` — stores `Wrapped?`, sizes to zero when nil | 30 |
| `Tests/TextUITests/Core/ConditionalViewTests.swift` | if/else in ViewBuilder, optional views, nested conditionals | — |

### Files to modify

| File | Change |
|------|--------|
| `Sources/TextUI/Core/ViewBuilder.swift` | Add `buildEither(first:)`, `buildEither(second:)`, `buildOptional(_:)` |
| `Sources/TextUI/Views/ProgressView.swift` | Refactor from PrimitiveView to composite View using `@AnimationTick` |

### Definition of done
- `if/else` in a `@ViewBuilder` body compiles and renders correctly
- `if let` / optional chains in body work
- ProgressView is a composite view
- All tests pass, linting passes, DocC passes

---

## Phase 7c — CommandPalette, Demo App & Documentation ✅

**Status**: Complete (2026-03-01) — 14 new tests (567 total), 3 source files, 1 test file, 3 doc articles, 7 demo files
**Goal**: Build CommandPalette (modal overlay with filtered command list), a demo app showcasing the full framework, and comprehensive documentation. After this phase, TextUI is feature-complete per the vision doc.

### Implementation decisions

1. **CommandPalette is `internal`, not public.** It's rendered directly by `RunLoop` after the root view — not placed in the user's view tree. Users don't need to reference it; they just press Ctrl+P. This keeps the public API clean.

2. **Palette key handling intercepts all keys (except Ctrl+C) when visible.** This prevents key events from leaking through to the focus system or command shortcuts while the palette is open. Ctrl+P acts as a toggle (open/close).

3. **Demo state uses `@unchecked Sendable` with manual `StateSignal.send()`.** The `@Observed` property wrapper is `@MainActor`, which causes strict concurrency errors when accessed from nonisolated `View.body`. The demo works around this with `didSet` observers calling `StateSignal.send()` via `MainActor.assumeIsolated`. This is a known friction point — the framework should consider making `View.body` `@MainActor` or providing a nonisolated state mechanism.

4. **ViewCatalog.md instead of Views.md** to avoid DocC ambiguity with the `Views` topic group in `TextUI.md`.

5. **Demo showcases all 22 meaningful view primitives** across 5 tabs (Form, Table, Progress, Layout, All Views). Only `EmptyView` is omitted (no visual output). Every control, layout container, and display primitive appears at least once.

### Files created

| File | Description |
|------|-------------|
| `Sources/TextUI/Commands/CommandPalette.swift` | Internal PrimitiveView: centered bordered overlay with filter, entry list, shortcut hints, scroll, "No matches" empty state |
| `Examples/Demo/Package.swift` | Standalone executable with path dependency on TextUI |
| `Examples/Demo/Sources/DemoApp.swift` | `@main` App with TabView, commands (Ctrl+Q, Ctrl+R), CommandBar |
| `Examples/Demo/Sources/DemoState.swift` | Shared state with manual `StateSignal.send()` |
| `Examples/Demo/Sources/FormTab.swift` | TextField, Toggle, Picker, Button, @FocusState demo |
| `Examples/Demo/Sources/TableTab.swift` | ScrollView + Table with sample process data |
| `Examples/Demo/Sources/ProgressTab.swift` | ProgressView: indeterminate spinner, determinate bar, compact and bar styles |
| `Examples/Demo/Sources/LayoutTab.swift` | Nested HStack/VStack, Color blocks, Spacer, Divider, .border(), .padding() |
| `Examples/Demo/Sources/ViewsTab.swift` | AttributedText, ForEach, Group, ZStack, Canvas |
| `Tests/TextUITests/Commands/CommandPaletteTests.swift` | Border/title, filter text, inverse selection, shortcuts, empty states, separator, tiny region safety |

### Files modified

| File | Change |
|------|--------|
| `Sources/TextUI/Commands/CommandRegistry.swift` | Added `filterText`, `selectedIndex`, `filteredEntries`, `resetPaletteState()` |
| `Sources/TextUI/App/RunLoop.swift` | Added `handlePaletteKey(_:)`, palette rendering after root view, reset on open |
| `Tests/TextUITests/Commands/CommandRegistryTests.swift` | Added 4 tests for filtering and reset |
| `Sources/TextUI/Documentation.docc/TextUI.md` | Added Guides topic group linking to GettingStarted, ViewCatalog, FocusAndInput |
| `Sources/TextUI/Documentation.docc/CommandSystem.md` | Added Command Palette section |
| `README.md` | Replaced placeholder with tagline, quick start, features, demo instructions |

### Documentation added
- `Sources/TextUI/Documentation.docc/GettingStarted.md` — Package setup through commands tutorial
- `Sources/TextUI/Documentation.docc/ViewCatalog.md` — Complete catalog of all views with code examples
- `Sources/TextUI/Documentation.docc/FocusAndInput.md` — Focus ring, @FocusState, key events, command palette

### Definition of done ✅
- ✅ `swift test --quiet` — 567 tests pass
- ✅ `swiftformat . --lint` — clean
- ✅ `swift build --package-path Examples/Demo` — demo compiles
- ✅ `swift package generate-documentation --target TextUI` — no warnings
- ✅ CommandPalette renders, filters, navigates, executes
- ✅ Demo app showcases all 22 meaningful view primitives
- ✅ README updated with overview, quick start, feature highlights, demo instructions

---

## Phase Summary

| Phase | Focus | Source files | Test files | Tests | Status |
|-------|-------|-------------|------------|-------|--------|
| 1 | Rendering foundation | 7 | 6 | 113 | ✅ Complete |
| 2 | Core protocols & stack layout | 17 | 13 | 82 | ✅ Complete |
| 3 | Modifiers, ZStack & primitives | 20 | 15 | 123 | ✅ Complete |
| 4 | Terminal I/O, state & app lifecycle | 12 | 4 | 52 | ✅ Complete |
| 5 | Focus system & interactive controls | 16 | 7 | 68 | ✅ Complete |
| 6 | ScrollView, Table & TabView | 6 | 3 | 46 | ✅ Complete |
| 7a | Commands, animation & ProgressView | 16 | 6 | 62 | ✅ Complete |
| 7b | Conditional views | 3 | 1 | 7 | ✅ Complete |
| 7c | CommandPalette, demo app & docs | 3 + 7 demo + 3 docs | 1 | 14 | ✅ Complete |

**All phases complete**: ~100 source files, 56 test files, 567 tests, 3 documentation articles, 7 demo app files

### Cross-cutting concerns (resolved)

- **DocC**: Written incrementally per phase. Three comprehensive articles added in Phase 7c. `swift package generate-documentation` runs clean.
- **Demo app**: Complete in Phase 7c. Showcases all 22 meaningful view primitives across 5 tabs.
- **swiftformat**: Run in every phase. Lint passes clean.
- **Commits**: Offered at end of each phase.

### Risk areas (retrospective)

1. **`@Observed` + `@MainActor` interaction** — Confirmed friction: `@Observed` is `@MainActor` but `View.body` is nonisolated. Demo works around this with manual `StateSignal.send()` + `@unchecked Sendable`. A future improvement should make `View.body` `@MainActor` or provide a nonisolated state mechanism.
2. **`any View` existential performance** — No issues observed. 567 tests run in ~30ms.
3. **Focus ring construction during render** — Worked well. `beginFrame()` resets the ring each frame; controls register during `render()`.
4. **Table column coordination** — Implemented with multi-pass measurement. No performance issues with demo-scale data.
5. **CommandPalette** — Simpler than expected as an internal `PrimitiveView`. Direct buffer rendering avoided the complexity of composing TextField + ScrollView.
