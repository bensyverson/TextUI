# TerminalUI: A SwiftUI-Inspired Terminal UI Framework

## Why

Terminal user interfaces are experiencing a renaissance. Tools like `htop`, `lazygit`, `k9s`, and our own OK example app demonstrate that rich, interactive terminal UIs are both possible and desirable. But building them today means writing imperative, character-by-character rendering code — the equivalent of calling `CGContext` methods by hand instead of using SwiftUI.

Our OK example app's TUI proves the concept. It has double-buffered differential rendering, a layout engine, and result builders. But every view hand-manages its own sizing and rendering. A simple status bar with left-aligned and right-aligned text requires 34 lines of imperative column arithmetic. A tab bar is 90 lines of character placement. There's no way to compose views declaratively — if you want `HStack { Text("left"); Spacer(); Text("right") }`, you have to implement the entire layout yourself.

SwiftUI solved this for graphical UIs with one key insight: **views describe what they want, not how to draw it**. A `Text` knows its intrinsic size. A `Spacer` knows it wants to expand. A `VStack` knows how to negotiate between its children. The framework handles the rest.

We will bring this model to the terminal.

### Goals

- **Declarative composition**: Build complex UIs by nesting simple views. A status bar is `HStack { Text(...); Spacer(); Text(...) }.background(.gray)`, not 34 lines of buffer manipulation.
- **Automatic layout negotiation**: Views declare sizing preferences. Parent containers distribute space using a well-defined algorithm. No manual offset calculations.
- **Two-tier architecture**: Composite views have a `body` property (like SwiftUI). Primitive views implement sizing and rendering directly. Users almost never write primitives.
- **Interactive controls**: Button, TextField, Toggle, Picker — with a focus management system for keyboard navigation.
- **Keyboard shortcuts and commands**: A built-in system for defining, displaying, and dispatching keyboard-driven commands.
- **Correct Unicode handling**: Full support for emoji, CJK characters, and grapheme clusters with accurate terminal display width calculations from day one.
- **App lifecycle**: A top-level `App` protocol that manages terminal setup/teardown, the render loop, signal handling, and command registration.
- **Zero dependencies**: Pure Swift, cross-platform (macOS, Linux). No Combine, no Foundation beyond basics.

### Non-goals

- Pixel-perfect SwiftUI compatibility. We're inspired by SwiftUI, not cloning it.
- Animation system. Terminal refresh rates don't justify a continuous animation framework. Simple tick-driven animation (spinners, progress bars) is sufficient.
- Accessibility beyond what the terminal provides. Screen readers already interact with terminal content.

---

## Architecture Overview

### The Two-Tier View Protocol

Every visual element conforms to `View`. There are exactly two kinds of views:

**Composite views** have a `body` that returns other views. This is what users write 99% of the time. They never implement sizing or rendering — it's computed from the `body` tree automatically:

```swift
struct StatusBar: View {
    let breadcrumb: String
    let logLevel: String

    var body: some View {
        HStack {
            Text(" \(breadcrumb) ").bold()
            Spacer()
            Text("[\(logLevel)] ").dim()
        }
        .background(.brightBlack)
    }
}
```

**Primitive views** implement `sizeThatFits` and `render` directly. These are the building blocks shipped with the framework — `Text`, `Spacer`, `VStack`, `HStack`, modifier wrappers, etc. Users rarely need to create new ones.

```swift
protocol View {
    associatedtype Body: View
    var body: Body { get }
}

protocol PrimitiveView: View where Body == Never {
    func sizeThatFits(_ proposal: SizeProposal) -> Size2D
    func render(into buffer: inout Buffer, region: Region)
}

extension PrimitiveView {
    var body: Never { fatalError("Primitives do not have a body") }
}

extension Never: View {
    typealias Body = Never
    var body: Never { fatalError() }
}
```

Modern Swift (5.7+) handles `any View` with associated types natively — no `AnyView` type erasure needed. `[any View]`, `any View` return types, and existential opening all work correctly.

### The Rendering Engine

The rendering engine traverses the view tree, dispatching between composites and primitives:

```swift
func sizeThatFits(_ view: any View, proposal: SizeProposal) -> Size2D {
    if let primitive = view as? any PrimitiveView {
        return primitive.sizeThatFits(proposal)
    } else {
        return sizeThatFits(view.body, proposal: proposal)
    }
}

func render(_ view: any View, into buffer: inout Buffer, region: Region) {
    if let primitive = view as? any PrimitiveView {
        primitive.render(into: &buffer, region: region)
    } else {
        render(view.body, into: &buffer, region: region)
    }
}
```

Composite views are **layout-transparent** — the engine evaluates their `body` and recurses until it hits primitives. A composite view's size is whatever its `body`'s size is.

### Result Builder

A `@ViewBuilder` result builder enables declarative syntax with `if`/`else`, `if let`, and `for` loops:

```swift
@resultBuilder
enum ViewBuilder {
    static func buildBlock(_ components: any View...) -> [any View]
    static func buildOptional(_ component: (any View)?) -> any View
    static func buildEither(first: any View) -> any View
    static func buildEither(second: any View) -> any View
    static func buildArray(_ components: [any View]) -> any View  // ForEach support
    static func buildExpression(_ expression: any View) -> any View
}
```

---

## The Layout System

### The Proposal/Response Contract

Layout is a three-phase recursive negotiation between parent and child. This is the heart of the framework.

**Phase 1 — Propose (top-down):** The root view receives the terminal dimensions as its initial proposal. Each parent proposes a `SizeProposal` to each child. The proposal is a suggestion, not a constraint.

**Phase 2 — Respond (bottom-up):** The child returns a concrete `Size2D`. It may accept the proposal exactly, partially use it, ignore it, or even exceed it. **The child always chooses its own size. The parent must respect that choice.**

**Phase 3 — Place (top-down):** The parent positions each child within its coordinate space using alignment rules, then renders.

```swift
struct SizeProposal: Sendable, Hashable {
    /// Proposed width. nil = "what's your ideal width?"
    var width: Int?

    /// Proposed height. nil = "what's your ideal height?"
    var height: Int?
}

struct Size2D: Sendable, Hashable {
    var width: Int
    var height: Int
}
```

### The Four Proposal Modes

Each dimension of `SizeProposal` operates independently in one of four modes:

| Value | Name | Meaning | Child should return |
|-------|------|---------|---------------------|
| `nil` | Ideal | "What's your natural/intrinsic size?" | Ideal size for that dimension |
| `0` | Minimum | "What's the least space you need?" | Minimum usable size |
| `Int.max` | Maximum | "What's the most you could use?" | Maximum useful size |
| Concrete (e.g. `40`) | Explicit | "You have this much space" | Size appropriate for that offer |

Proposals can mix modes across dimensions. `SizeProposal(width: 80, height: nil)` means "I'm offering 80 columns; tell me your ideal height at that width." This is how wrapping text works — the height response depends on the width proposal.

### View Categories

Every view falls into one of three categories based on how it responds to proposals:

**Hugging views** shrink to their content. They never expand beyond what they need.
- `Text("Hello")` proposed 80 columns → responds `(5, 1)`. Does not fill to 80.
- `Text("Hello")` proposed `nil` → responds `(5, 1)`. Its ideal is its content.
- Non-wrapping text proposed less than content width → truncates, responds with proposed width.
- Wrapping text proposed less than content width → wraps, responds with proposed width and increased height.

**Expanding (greedy) views** fill the proposed space.
- `Spacer()` proposed 40 → responds `(40, 0)` on its expanding axis.
- `Color(.blue)` proposed `(80, 24)` → responds `(80, 24)`.
- Proposed `nil` → responds with a small default or zero (ideal is minimal).

**Neutral views** inherit behavior from their children.
- `VStack`, `HStack`, `ZStack` — their size is determined entirely by their children's sizes.
- Custom composite views — layout-transparent, size comes from `body`.

### Helper Methods on SizeProposal

```swift
extension SizeProposal {
    /// Both dimensions nil — "tell me your ideal size."
    static let unspecified = SizeProposal(width: nil, height: nil)

    /// Both dimensions zero — "tell me your minimum size."
    static let zero = SizeProposal(width: 0, height: 0)

    /// Both dimensions .max — "tell me your maximum size."
    static let max = SizeProposal(width: .max, height: .max)

    /// Subtract padding from the proposal, preserving nil.
    func inset(horizontal: Int, vertical: Int) -> SizeProposal {
        SizeProposal(
            width: width.map { Swift.max(0, $0 - horizontal) },
            height: height.map { Swift.max(0, $0 - vertical) }
        )
    }

    /// Replace nil dimensions with defaults.
    func replacingUnspecified(width: Int = 0, height: Int = 0) -> SizeProposal {
        SizeProposal(
            width: self.width ?? width,
            height: self.height ?? height
        )
    }
}
```

---

## The Stack Layout Algorithm

`VStack` and `HStack` use the same algorithm with axes swapped. It is a **single sequential greedy pass** — not a constraint solver.

### Terminology

- **Primary axis:** The stack's layout direction. Height for VStack, width for HStack.
- **Cross axis:** The perpendicular direction. Width for VStack, height for HStack.
- **Flexibility:** How much a view's size can vary along the primary axis. Computed as `sizeThatFits(.max).primary - sizeThatFits(.zero).primary`. A `Text("Hi")` has flexibility 2 (always 2 wide). A `Spacer` has flexibility `Int.max`.

### The Algorithm

```
Input: children, available space along primary axis, available space along cross axis
Output: each child's allocated size and offset along primary axis

1. Subtract total spacing from available primary-axis space.
   (Spacing is a fixed value between each pair of adjacent children.)

   remainingSpace = available - (spacing * (children.count - 1))

2. Group children by layoutPriority (descending — highest first).
   Default layoutPriority is 0.

3. For each priority group (highest first):

   a. Sort children within the group by flexibility (ascending — least flexible first).
      flexibility(child) = child.sizeThatFits(primary: .max, cross: available).primary
                         - child.sizeThatFits(primary: 0,    cross: available).primary

   b. For each child in flexibility order:
      equalShare = remainingSpace / remainingChildrenInGroup
      proposedSize = SizeProposal(primary: equalShare, cross: available)
      childSize = child.sizeThatFits(proposedSize)
      allocate childSize.primary to this child
      remainingSpace -= childSize.primary
      remainingChildrenInGroup -= 1

4. Place children sequentially along the primary axis with spacing between them.
   Align each child on the cross axis according to the stack's alignment parameter.

5. The stack's own size:
   - Primary axis: sum of all children's primary sizes + total spacing
   - Cross axis: maximum of all children's cross sizes
```

### Why This Works

The key insight is **least-flexible children are processed first**. A `Text("OK")` has flexibility 2 — it always wants 2 columns. When offered its equal share (say, 26 columns), it responds `(2, 1)`. The 24 surplus columns cascade to more flexible children. A `Spacer` with near-infinite flexibility is processed last and absorbs all remaining space.

This means `HStack { Text("left"); Spacer(); Text("right") }` in 80 columns naturally produces: `Text` gets 4, `Text` gets 5, `Spacer` gets 71. No special-casing needed.

### Cross-Axis Alignment

VStack accepts a `HorizontalAlignment` parameter (default `.leading`). HStack accepts a `VerticalAlignment` parameter (default `.top`).

```swift
enum HorizontalAlignment: Sendable, Hashable {
    case leading
    case center
    case trailing
}

enum VerticalAlignment: Sendable, Hashable {
    case top
    case center
    case bottom
}
```

A child that doesn't fill the cross-axis is positioned according to the alignment. For example, in a `VStack(alignment: .center)` that is 80 columns wide, a `Text("Hi")` (2 columns) is placed at column 39.

### ZStack Algorithm

`ZStack` is simpler: it proposes the **same size** to all children independently. Children don't affect each other's sizing. Children are rendered in order (first = back, last = front). The ZStack's own size is the maximum width and maximum height across all children.

```swift
struct ZStack: PrimitiveView {
    let children: [any View]
    let alignment: Alignment  // combines both axes

    func sizeThatFits(_ proposal: SizeProposal) -> Size2D {
        var maxWidth = 0
        var maxHeight = 0
        for child in children {
            let size = sizeThatFits(child, proposal: proposal)
            maxWidth = max(maxWidth, size.width)
            maxHeight = max(maxHeight, size.height)
        }
        return Size2D(width: maxWidth, height: maxHeight)
    }
}
```

---

## Primitive Views Catalog

### Layout Containers

**`VStack`** — Arranges children vertically. Distributes height using the stack algorithm. Cross-axis alignment defaults to `.leading`.

```swift
VStack(alignment: .center, spacing: 1) {
    Text("Title").bold()
    Divider.horizontal
    Text("Body content here")
}
```

**`HStack`** — Arranges children horizontally. Distributes width using the stack algorithm. Cross-axis alignment defaults to `.top`.

```swift
HStack(spacing: 2) {
    Text("Name:").bold()
    Text(userName)
}
```

**`ZStack`** — Overlays children back-to-front. All children receive the same size proposal. Alignment defaults to `.topLeading`.

```swift
ZStack {
    mainContent
    if showOverlay {
        Color(.black).opacity(0.5)
        overlayContent
    }
}
```

**`ScrollView`** — A viewport over content that may exceed the visible region. Proposes `nil` (ideal) on the scroll axis so children render at natural size, then clips to the visible region. Supports vertical scrolling (primary use case) with a scroll indicator.

```swift
ScrollView {
    ForEach(items) { item in
        ItemRow(item: item)
    }
}
```

Implementation: measures each child's height by calling `sizeThatFits(width: available, height: nil)`, builds a prefix-sum offset array, and renders only the children visible at the current scroll offset. Scroll offset is in rows (not item indices), enabling smooth scrolling through variable-height content.

**`Table`** — Multi-column data display with coordinated column widths across rows.

```swift
Table(data: processes) {
    Column("PID", width: .fixed(8)) { Text("\($0.pid)") }
    Column("Name", width: .flex()) { Text($0.name) }
    Column("CPU", width: .fixed(6)) { Text("\($0.cpu)%") }
}
```

Implementation: collects all column width preferences, runs the stack algorithm horizontally to determine column widths, then renders each row with those shared widths. Wraps a ScrollView for vertical scrolling.

### Content Views

**`Text`** — The fundamental content view. Hugging: never expands beyond its content.

```swift
Text("Hello, world!").bold().foregroundColor(.cyan)
```

Sizing behavior:
- `sizeThatFits(width: nil)` → `(contentLength, 1)` — ideal is the full unwrapped line
- `sizeThatFits(width: n)` where `n >= contentLength` → `(contentLength, 1)` — hugs, doesn't expand
- `sizeThatFits(width: n)` where `n < contentLength` and wrapping enabled → `(n, wrappedLines)` — wraps at word boundaries, height increases
- `sizeThatFits(width: n)` where `n < contentLength` and wrapping disabled → `(n, 1)` — truncates with ellipsis during render
- `sizeThatFits(width: 0)` → `(0, 0)` — minimum is zero

When `Text` contains newlines, the ideal width is the longest line and the ideal height is the number of lines. Wrapping is per-line.

**`AttributedText`** — A single line of mixed-style spans. Hugging, like `Text`.

```swift
AttributedText {
    TextSpan("[PM]", style: .init(fg: .cyan, bold: true))
    TextSpan(" read_file ", style: .plain)
    TextSpan("✓", style: .init(fg: .green))
}
```

Sizing: width is the sum of all span lengths. Height is always 1. Truncates from the right if the allocated region is narrower than the content.

**`Color`** — Fills the proposed region with a solid color. Greedy: accepts the full proposal.

```swift
ZStack {
    Color(.black)  // full backdrop
    content
}
```

Sizing: `sizeThatFits(width: n, height: m)` → `(n, m)`. Proposed `nil` → `(0, 0)` (minimal ideal). Proposed `.max` → `(.max, .max)`.

**`Canvas`** — Escape hatch for custom drawing. Hands the user a `Buffer` and `Region`.

```swift
Canvas { buffer, region in
    // Direct buffer manipulation for custom visuals
    for col in 0..<region.width {
        let char: Character = col % 2 == 0 ? "█" : "░"
        buffer[region.row, region.col + col] = Cell(char: char, style: .plain)
    }
}
```

Sizing: greedy by default (fills proposal). Can be overridden with `.frame()`.

**`ProgressView`** — A unified progress indicator that displays as either a spinner or a progress bar depending on whether a value is provided. This replaces separate Spinner and ProgressBar types.

```swift
// Indeterminate spinner (single animated character, default compact style)
ProgressView()
// ⠋ (braille spinner, animates with tick)

// Indeterminate bar (animated shimmer/stripe pattern)
ProgressView()
    .progressViewStyle(.bar)
// ░░▒▒░░▒▒░░▒▒░░░░░░░░ (animated stripe scrolling)

// Determinate compact (single character using block fill: ▏▎▍▌▋▊▉█)
ProgressView(value: 0.42)
// ▍ (8 levels of fill in a single character)

// Determinate bar (default style for determinate)
ProgressView(value: 0.42, total: 1.0)
    .progressViewStyle(.bar)
// ████████░░░░░░░░░░░░ 42%

// With label
ProgressView("Downloading...", value: 0.42)
    .progressViewStyle(.bar)
// Downloading... ████████░░░░░░░░░░░░ 42%

// Hide the label
ProgressView("Downloading...", value: 0.42)
    .progressViewStyle(.bar)
    .labelStyle(.hidden)
// ████████░░░░░░░░░░░░ 42%
```

API:

```swift
struct ProgressView: PrimitiveView {
    // Indeterminate
    init()
    init(_ label: String)

    // Determinate
    init(value: Double, total: Double = 1.0)
    init(_ label: String, value: Double, total: Double = 1.0)
}

enum ProgressViewStyle: Sendable, Hashable {
    /// Single character. Default for indeterminate (braille spinner).
    /// For determinate, uses block fill characters (▏▎▍▌▋▊▉█, 8 levels).
    case compact

    /// Horizontal bar. Default for determinate.
    /// For indeterminate, shows animated shimmer/stripe.
    /// `showPercent` controls whether "42%" is appended (default true).
    case bar(showPercent: Bool = true)
}
```

The default style flips based on content: `ProgressView()` (no value) defaults to `.compact` because a single spinning character is the natural loading indicator. `ProgressView(value:)` (with value) defaults to `.bar` because you want to see progress filling. Either can be overridden.

Sizing: `.compact` style is width 1, height 1. `.bar` style is greedy on width, height 1. With a label, width accommodates label + gap + bar.

### Structural Views

**`Spacer`** — Expands along the containing stack's primary axis. Transparent (renders nothing).

```swift
HStack {
    Text("Left")
    Spacer()         // absorbs all remaining width
    Text("Right")
}
```

Sizing: On the primary axis, `sizeThatFits(0)` → `minLength` (default 0), `sizeThatFits(.max)` → `.max`. Flexibility is near-infinite, so the stack algorithm processes it last. On the cross axis, returns 0 (doesn't affect cross-axis sizing).

**`Divider`** — A hairline separator. Expands on the primary axis, fixed at 1 on the cross axis.

```swift
VStack {
    header
    Divider.horizontal
    content
}
```

A horizontal `Divider` fills the available width and has height 1. A vertical `Divider` fills the available height and has width 1. Renders using box-drawing characters (`─` or `│`).

**`EmptyView`** — An invisible view that occupies zero space.

**`ForEach`** — Generates views from a collection. Layout-transparent: children connect directly to the parent container.

```swift
VStack {
    ForEach(items) { item in
        Text(item.name)
    }
}
```

`ForEach` is not a layout container — it's a structural element that the parent stack flattens before layout. Its children participate in the parent's layout algorithm directly.

**`Group`** — Layout-transparent container for applying modifiers to multiple views without affecting layout.

```swift
Group {
    Text("One")
    Text("Two")
    Text("Three")
}
.foregroundColor(.cyan)
```

---

## Modifiers

Modifiers are primitive views that wrap content and transform the proposal/response pipeline. They chain naturally: `.bold().padding(1).background(.blue)` produces `BackgroundView<PaddedView<StyledView<Content>>>`.

Users create custom "modifiers" simply as extension methods that compose existing ones:

```swift
extension View {
    func card() -> some View {
        self.padding(1).border(.rounded).background(.brightBlack)
    }
}
```

### Layout Modifiers

**`.padding()`** — Subtracts from proposal, adds to response.

```swift
func sizeThatFits(_ proposal: SizeProposal) -> Size2D {
    let inner = proposal.inset(horizontal: left + right, vertical: top + bottom)
    let contentSize = sizeThatFits(content, proposal: inner)
    return Size2D(
        width: contentSize.width + left + right,
        height: contentSize.height + top + bottom
    )
}
```

Variants: `.padding(_ amount: Int)`, `.padding(top:left:bottom:right:)`, `.paddingH(_ amount: Int)`, `.paddingV(_ amount: Int)`.

When the proposal dimension is `nil`, padding passes `nil` through to the child (preserving the "ideal" query) and adds its insets to the child's response.

**`.frame(width:height:)`** — Fixed frame. Proposes exact size to child, reports exact size to parent regardless of child's response.

```swift
Text("Hi")
    .frame(width: 20, height: 3)
// Proposes (20, 3) to Text. Text responds (2, 1).
// Frame reports (20, 3) to parent. Text is placed within using alignment.
```

Per dimension: if the value is specified, the frame proposes it to the child and reports it to the parent. If `nil`, the dimension is transparent (proposal and response pass through).

**`.frame(minWidth:maxWidth:minHeight:maxHeight:)`** — Flexible frame with clamping.

The clamping logic per dimension:
- Both min and max set → clamp the **proposed** value between min and max
- Only min set → `max(childSize, min)` (floor on content)
- Only max set → `min(proposed, max)` (ceiling on proposal)

This asymmetry is inherited from SwiftUI and enables idioms like `.frame(maxWidth: .max)` to make a hugging view fill its container.

**`.fixedSize()`** — Replaces the parent's proposal with `nil`, causing the child to render at its ideal size. Useful for preventing truncation.

```swift
Text("Don't truncate me")
    .fixedSize()
// Parent proposes width: 10 → fixedSize proposes width: nil
// Text returns its ideal: (18, 1)
// May overflow parent bounds
```

Variants: `.fixedSize(horizontal:vertical:)` to apply on one axis only.

**`.layoutPriority()`** — Sets the view's priority for space allocation within a stack. Higher priority views get offered space first. Default is 0. Negative values are valid.

### Visual Modifiers

**`.foregroundColor(_ color: Style.Color)`** — Sets text/foreground color.

**`.background(_ color: Style.Color)`** — Fills the region with a background color, then renders content on top. Does not affect sizing.

**`.style(_ style: Style)`** — Applies a full `Style` (fg, bg, bold, dim, italic, underline, inverse, strikethrough).

**`.bold()`, `.dim()`, `.italic()`, `.underline()`, `.strikethrough()`, `.inverse()`** — Convenience style modifiers.

**`.border()`** — Draws a box-drawing border around the content. Adds 2 to both width and height sizing (1 per side). Content is rendered in the interior.

Variants: `.border(.rounded)` for rounded corners (`╭╮╰╯`), `.border(.square)` for square corners (`┌┐└┘`).

**`.overlay { }`** — Renders additional content on top of the primary view, sized to the primary view's bounds. Does not affect layout.

```swift
Text("Loading...")
    .overlay {
        if isLoading {
            Spinner()
        }
    }
```

**`.hidden()`** — Renders as empty space, preserving layout. The view's `sizeThatFits` is still called, but `render` produces nothing.

---

## Focus System

Interactive terminal UIs are entirely keyboard-driven. The focus system determines which view receives key events and provides visual indication of the active control.

### Focus State

Focus state is managed by a `@FocusState` property wrapper that supports two patterns:

**Single target (Bool):**
```swift
@FocusState var isSearchFocused: Bool

TextField("Search", text: query, onChange: { ... })
    .focused($isSearchFocused)

// Programmatic focus:
isSearchFocused = true
```

**Multiple targets (optional Hashable):**
```swift
enum Field: Hashable { case name, email, submit }
@FocusState var focus: Field?

TextField("Name", text: name, onChange: { ... })
    .focused($focus, equals: .name)
TextField("Email", text: email, onChange: { ... })
    .focused($focus, equals: .email)
Button("Submit") { ... }
    .focused($focus, equals: .submit)

// Programmatic focus:
focus = .email

// Clear focus:
focus = nil
```

### How Focus State Works

Unlike SwiftUI's `DynamicProperty` system, our focus state is backed by the rendering engine's **focus store** — a shared mutable state that tracks the currently focused view ID. `@FocusState` is a property wrapper that reads from and writes to this store.

When a view tree is rendered, the engine collects all `.focused()` bindings to build a **focus ring** — an ordered list of focusable views in reading order (top-to-bottom in VStack, left-to-right in HStack). Tab/Shift-Tab cycles through this ring.

```swift
@propertyWrapper
struct FocusState<Value: Hashable> {
    // Backed by the engine's focus store
    var wrappedValue: Value
    var projectedValue: Binding { ... }

    struct Binding {
        // Two-way binding to the focus store
    }
}
```

### Focus Navigation

| Key | Action |
|-----|--------|
| Tab | Move to next focusable view in reading order |
| Shift+Tab | Move to previous focusable view |
| Arrow keys | Move to nearest focusable view in that direction (when focus sections are defined) |

Focus order follows the view tree's structure — no explicit tab indices needed. The order in which views appear in their parent's children determines the navigation sequence.

### Focus Modifiers

**`.focused()`** — Binds a view to a `@FocusState`. Two variants (Bool and Hashable) as shown above.

**`.focusable()`** — Makes a custom view capable of receiving focus. Standard interactive controls (`Button`, `TextField`, `Toggle`, `Picker`) are implicitly focusable and don't need this.

```swift
MyCustomControl()
    .focusable()
    .focused($focus, equals: .custom)
```

Accepts an optional `interactions` parameter:
- `.edit` — View captures key input when focused (like a text field). Gains focus on interaction.
- `.activate` — View responds to Enter/Space when focused (like a button). Only gains focus via Tab navigation.

**`.defaultFocus()`** — Sets which view should receive focus when the view tree first appears.

```swift
VStack {
    TextField("Name", ...)
        .focused($focus, equals: .name)
    TextField("Email", ...)
        .focused($focus, equals: .email)
}
.defaultFocus($focus, .name)
```

**`.focusSection()`** — Groups focusable children into a section for arrow-key navigation. Without focus sections, arrow keys have no effect (only Tab works). With them, pressing Right from a view in the left section jumps to the nearest focusable view in the right section.

```swift
HStack {
    VStack {
        Button("Sidebar 1") { ... }
        Button("Sidebar 2") { ... }
    }
    .focusSection()

    VStack {
        // main content
    }
    .focusSection()
}
```

### Key Event Handling

**`.onKeyPress()`** — Handles key events when the view (or a descendant) has focus. Returns `.handled` to consume the event or `.ignored` to let it propagate up.

```swift
.onKeyPress(.return) {
    submitForm()
    return .handled
}

.onKeyPress { event in
    if event.char == "q" {
        quit()
        return .handled
    }
    return .ignored  // propagate to parent
}
```

Event flow:
1. Key event arrives from the terminal
2. The focused view's `onKeyPress` gets first chance
3. If `.ignored`, event propagates up the view hierarchy
4. Parent views' `onKeyPress` handlers get a chance
5. If still unhandled, the focus system processes it (Tab moves focus, etc.)

**`.onSubmit()`** — Fires when Enter is pressed on a focused text field. Propagates up the view hierarchy, so a single handler on a `Form` catches submissions from all fields.

```swift
VStack {
    TextField("Name", ...)
        .onSubmit { focus = .email }     // Enter → move to email
    TextField("Email", ...)
        .onSubmit { focus = .submit }    // Enter → move to submit
    Button("Submit") { performSubmit() }
}
```

### Focus Styling

Views can react to their focus state to render differently. The `@Environment(\.isFocused)` value indicates whether the view or a descendant holds focus:

```swift
struct FancyButton: View {
    let label: String
    let action: () -> Void
    @Environment(\.isFocused) var isFocused

    var body: some View {
        Text(" \(label) ")
            .style(isFocused ? Style(inverse: true, bold: true) : .dim)
            .border(isFocused ? .rounded : .square)
    }
}
```

Interactive primitives (`Button`, `TextField`, `Toggle`, `Picker`) have built-in focus styling:
- **Button**: Inverse video when focused, dim when unfocused
- **TextField**: Visible cursor when focused, placeholder text when unfocused
- **Toggle**: Bold checkbox when focused
- **Picker**: Highlighted selection arrow when focused

---

## Interactive Controls

### Button

A pressable control with a label and action. Implicitly focusable (`.activate` interaction). Responds to Enter and Space when focused.

```swift
Button("Submit") {
    performSubmit()
}

// Custom label:
Button(action: { performSubmit() }) {
    HStack {
        Text("✓").foregroundColor(.green)
        Text("Submit").bold()
    }
}
```

Sizing: hugs its label content. Height is the label's height.

### TextField

A single-line text input with placeholder text. Implicitly focusable (`.edit` interaction). When focused, displays a cursor and captures key input.

```swift
TextField("Enter your name", text: name, onChange: { newValue in
    name = newValue
})
```

Sizing: width is greedy (fills proposed width) to provide a typing area. Height is 1. Minimum width accommodates the placeholder or a reasonable input area.

Behavior when focused:
- Printable characters are appended at the cursor position
- Backspace deletes behind the cursor
- Left/Right arrows move the cursor
- Home/End jump to start/end
- Enter triggers `onSubmit`
- Escape clears focus (if the app handles it)

### Toggle

A checkbox control. Implicitly focusable (`.activate` interaction). Space toggles the value.

```swift
Toggle("Dark mode", isOn: darkMode, onChange: { newValue in
    darkMode = newValue
})
// Renders: [x] Dark mode  (or [ ] Dark mode)
```

Sizing: hugs content. Width is `[x] ` (4) + label length. Height is 1.

### Picker

A selection control for choosing from a list of options. Implicitly focusable (`.activate` interaction). Up/Down arrows cycle through options.

```swift
Picker("Theme", selection: theme, onChange: { newValue in
    theme = newValue
}) {
    PickerOption("Light", value: .light)
    PickerOption("Dark", value: .dark)
    PickerOption("System", value: .system)
}
// Renders: Theme: ◀ Dark ▶
```

Sizing: hugs content. Width accommodates the label, arrows, and the widest option. Height is 1 for inline style.

### TabView

A container that displays one child at a time, with a tab bar for switching. Left/Right arrows navigate between tabs when the tab bar is focused. Tab key moves focus into the active tab's content.

```swift
TabView(selection: $activeTab) {
    Tab("Chat", id: .chat) {
        ChatView()
    }
    Tab("Settings", id: .settings) {
        SettingsView()
    }
    Tab("Logs", id: .logs) {
        LogView()
    }
}
```

The tab bar renders as a single-row header with bracketed labels, status indicators, and selection highlighting. The tab bar is automatically a horizontal focus group — arrow keys switch tabs, Tab exits to the content below.

Sizing: greedy on both axes. The tab bar is fixed at 1 row; the rest is allocated to the active tab's content.

---

## Unicode and Display Width

Terminal UIs must correctly handle the full range of Unicode, including emoji, CJK characters, and complex grapheme clusters. Display width calculations are foundational — if they're wrong, every layout calculation is wrong.

### The Problem

A terminal cell is a fixed-width grid. Most characters occupy 1 cell, but some occupy 2 (CJK ideographs, emoji) and some occupy 0 (combining marks, zero-width joiners). Swift's `String.count` returns the number of grapheme clusters (user-perceived characters), but says nothing about display width.

```
"Hello"      → 5 characters, 5 columns
"你好"        → 2 characters, 4 columns (each CJK char is 2 wide)
"👋"          → 1 character,  2 columns
"👩‍👩‍👧‍👦"  → 1 character,  2 columns (7 scalars, 25 UTF-8 bytes!)
"café"       → 4 characters, 4 columns
```

### Swift's Character Is Our Friend

Swift's `Character` type represents an extended grapheme cluster — a sequence of Unicode scalars that together produce one user-perceived character. This means:

- `"🤦🏼‍♂️".count == 1` — Swift correctly sees this ZWJ sequence (5 scalars: face palm + skin tone + ZWJ + male sign + VS-16) as a single character
- `"👩‍👩‍👧‍👦".count == 1` — A family emoji (7 scalars, 4 people joined by ZWJ) is one character
- `"🇺🇸".count == 1` — Two regional indicator scalars form one flag character

So iterating a `String` by `Character` gives us the right units — one `Character` = one glyph on screen. The question is: how many terminal columns does each `Character` occupy?

### Display Width Detection

We determine terminal display width by inspecting the Unicode scalars within each `Character`:

```swift
extension Character {
    /// The number of terminal columns this character occupies (0, 1, or 2).
    var displayWidth: Int {
        let scalars = Array(unicodeScalars)

        // 1. Emoji with presentation — always 2 columns
        //    Use isEmojiPresentation (NOT isEmoji — isEmoji is true for digits and #)
        if scalars.contains(where: { $0.properties.isEmojiPresentation }) { return 2 }

        // 2. Variation Selector 16 (U+FE0F) promotes text-style emoji to wide
        //    e.g., "☺" is 1 wide, "☺️" (with VS-16) is 2 wide
        if scalars.contains(where: { $0.value == 0xFE0F }) { return 2 }

        // 3. ZWJ sequences (family emoji, profession emoji) — always 2 columns
        if scalars.contains(where: { $0.value == 0x200D }) { return 2 }

        // 4. Regional indicator pairs (flag emoji) — 2 columns
        if scalars.contains(where: { (0x1F1E6...0x1F1FF).contains($0.value) }) { return 2 }

        // 5. Skin tone modifiers — the base emoji already matched rule 1,
        //    but standalone skin tones are also 2 wide
        if scalars.contains(where: { (0x1F3FB...0x1F3FF).contains($0.value) }) { return 2 }

        // 6. Keycap combining sequences (1️⃣, 2️⃣, etc.)
        if scalars.contains(where: { $0.value == 0x20E3 }) { return 2 }

        // 7. CJK ranges — 2 columns
        if scalars.contains(where: { isCJK($0) }) { return 2 }

        // 8. Zero-width characters (combining marks, format chars)
        if scalars.allSatisfy({ isZeroWidth($0) }) { return 0 }

        // 9. Everything else — 1 column
        return 1
    }
}

extension String {
    /// Total terminal display width of this string.
    var displayWidth: Int {
        reduce(0) { $0 + $1.displayWidth }
    }
}
```

The CJK detection covers:
- Hangul Jamo (U+1100–U+115F), Hangul Syllables (U+AC00–U+D7AF)
- CJK Unified Ideographs and extensions (U+2E80–U+9FFF, U+20000–U+2FA1F)
- CJK Compatibility (U+F900–U+FAFF)
- Fullwidth Forms (U+FF01–U+FF60)

### Impact on the Framework

Display width affects nearly every component:

| Component | How it uses display width |
|-----------|--------------------------|
| `Text.sizeThatFits` | Width is `content.displayWidth`, not `content.count` |
| `Text` wrapping | Wrap at column width, not character count |
| `AttributedText` | Span width = sum of character display widths |
| `Buffer.write` | Advance cursor by display width per character |
| `Buffer` storage | Wide characters occupy two cells; the second is a continuation marker |
| `Screen.flush` | Cursor positioning must account for preceding wide characters |
| `TextField` | Cursor position counts display columns, not characters |
| `ScrollView` | Line width calculations use display width |

### Buffer Continuation Cells

When a wide character (width 2) is written to the buffer, it occupies two cells. The second cell is marked as a **continuation**:

```swift
struct Cell: Sendable, Hashable {
    var char: Character
    var style: Style
    var isContinuation: Bool  // true = second half of a wide character
}
```

Rules:
- Writing a wide character at column `c` sets `buffer[row, c]` to the character and `buffer[row, c+1]` to a continuation cell
- The renderer skips continuation cells (the terminal advances automatically after a wide character)
- If a narrow character overwrites a continuation cell, the preceding wide character must be blanked to prevent artifacts
- A wide character at the last column of a row should be replaced with a space (it can't straddle the edge)

---

## Keyboard Shortcuts

### KeyboardShortcut Modifier

Views can register keyboard shortcuts that trigger actions regardless of focus state. Shortcuts are matched before the focus system processes key events.

```swift
Button("Save") { save() }
    .keyboardShortcut("s", modifiers: .control)    // Ctrl+S

Button("Quit") { quit() }
    .keyboardShortcut(.cancelAction)                // Escape

Button("Submit") { submit() }
    .keyboardShortcut(.defaultAction)               // Return/Enter

Button("Next Tab") { nextTab() }
    .keyboardShortcut(.rightArrow, modifiers: .control) // Ctrl+Right
```

### Types

```swift
struct KeyEquivalent: Sendable, Hashable {
    let character: Character?
    let named: NamedKey?

    /// Character shortcut: .init("s") for Ctrl+S, etc.
    init(_ char: Character)

    /// Named keys
    enum NamedKey: Sendable, Hashable {
        case `return`, escape, tab, delete, space
        case upArrow, downArrow, leftArrow, rightArrow
        case home, end, pageUp, pageDown
    }
}

struct EventModifiers: OptionSet, Sendable, Hashable {
    static let control = EventModifiers(rawValue: 1 << 0)
    static let shift = EventModifiers(rawValue: 1 << 1)
    static let option = EventModifiers(rawValue: 1 << 2)  // Alt — terminal support varies
}

struct KeyboardShortcut: Sendable, Hashable {
    let key: KeyEquivalent
    let modifiers: EventModifiers

    /// Semantic shortcuts
    static let defaultAction = KeyboardShortcut(.init(.return))   // Enter
    static let cancelAction = KeyboardShortcut(.init(.escape))    // Escape
}
```

### Key Event Priority

When a key event arrives, it is processed in this order:

1. **Focused view's `onKeyPress`** — the focused view gets first chance to handle it
2. **`onKeyPress` propagation** — bubbles up through ancestors, stopping at `.handled`
3. **Keyboard shortcuts** — matched deepest-first, bubbling up the tree
4. **Focus navigation** — Tab/Shift-Tab move focus, arrows navigate within focus groups
5. **Default behavior** — unhandled events are discarded

---

## Command Groups

Commands provide a declarative way to define keyboard-driven actions that surface in the UI automatically. They are defined on the `App` type and are available globally.

### Defining Commands

```swift
@main
struct MyApp: App {
    var body: some View {
        ContentView()
    }

    var commands: some Commands {
        CommandGroup("File") {
            Button("Save", action: save)
                .keyboardShortcut("s", modifiers: .control)
            Button("Open", action: open)
                .keyboardShortcut("o", modifiers: .control)
            Button("Quit", action: quit)
                .keyboardShortcut("q", modifiers: .control)
        }
        CommandGroup("View") {
            Button("Toggle Log Level", action: cycleLogLevel)
                .keyboardShortcut("l", modifiers: .control)
        }
        CommandGroup("Navigation") {
            Button("Next Tab", action: nextTab)
                .keyboardShortcut(.tab)
            Button("Previous Tab", action: prevTab)
                .keyboardShortcut(.tab, modifiers: .shift)
        }
    }
}
```

### CommandBar

A built-in view that renders registered commands as a compact shortcut reference bar:

```swift
var body: some View {
    VStack {
        mainContent
        CommandBar()
    }
}
// Renders:  ^S Save  ^O Open  ^Q Quit  ^L Log Level  Tab/S-Tab Navigate
```

`CommandBar` reads from the app's command registry automatically. It can be filtered:

```swift
CommandBar(groups: ["File", "View"])  // only show these groups
```

Sizing: height 1, greedy width. Truncates gracefully if there are more commands than space.

### CommandPalette

A modal overlay that shows all commands in a filterable list, triggered by a keyboard shortcut:

```swift
.keyboardShortcut("p", modifiers: .control)  // Ctrl+P opens the palette
```

The palette displays command names, their keyboard shortcuts, and filters as the user types. Selecting a command executes its action and dismisses the palette. This is analogous to VS Code's command palette.

---

## Focus Groups

Stacks with multiple focusable children automatically become **focus groups** in their axis direction. This means:

- An `HStack` with 2+ focusable children: **Left/Right arrows** navigate between them
- A `VStack` with 2+ focusable children: **Up/Down arrows** navigate between them
- **Tab** always exits the focus group and moves to the next focusable area

This behavior is automatic — no annotation needed. To disable it, use `.focusGroup(.none)`.

```swift
// These three buttons are automatically navigable with Left/Right arrows
HStack {
    Button("Save") { ... }
    Button("Cancel") { ... }
    Button("Delete") { ... }
}

// Tab moves focus to the next group (e.g., a form below)
```

### Focus Sections

For non-stack containers or custom grouping, `.focusSection()` defines a boundary for directional navigation:

```swift
HStack {
    VStack {
        Button("Sidebar 1") { ... }
        Button("Sidebar 2") { ... }
    }
    .focusSection()

    VStack {
        mainContent
    }
    .focusSection()
}
// Right arrow from "Sidebar 1" jumps to the nearest focusable view
// in the right-hand focus section.
```

---

## App Protocol and Lifecycle

The `App` protocol is the entry point for a TerminalUI application. It owns terminal lifecycle management, the render loop, command registration, and signal handling.

```swift
@main
struct MyApp: App {
    var body: some View {
        ContentView()
    }

    var commands: some Commands {
        CommandGroup("File") {
            Button("Quit", action: { /* ... */ })
                .keyboardShortcut("q", modifiers: .control)
        }
    }
}
```

### What App Manages

**Terminal lifecycle:**
- Enters raw mode and alternate screen on launch
- Hides cursor
- Restores terminal state on exit (including after crashes via signal handlers)
- Handles SIGWINCH for terminal resize
- Handles SIGINT/SIGTERM for graceful shutdown

**Render loop:**
- Merges state changes, key events, resize events, and timer ticks into a unified event stream
- Re-evaluates the view tree and re-renders on state changes
- Drives the double-buffered differential flush cycle
- Configurable tick interval for animations (default 100ms)

**Command infrastructure:**
- Collects `CommandGroup` definitions from the `commands` property
- Registers keyboard shortcuts for global matching
- Provides `CommandBar` and `CommandPalette` views that read from the command registry

**Focus management:**
- Owns the `FocusStore` that tracks the current focus ring and active focus
- Routes key events through the focus system

### View Lifecycle Modifiers

```swift
.onAppear { }       // Called when this view first renders
.onDisappear { }    // Called when this view is removed from the tree
.task { }           // Launches async work tied to the view's lifetime;
                     // automatically cancelled when the view disappears
```

`.task {}` is particularly useful for data loading, polling, and subscriptions:

```swift
struct LiveDataView: View {
    @State var data: [Item] = []

    var body: some View {
        ScrollView {
            ForEach(data) { item in
                Text(item.name)
            }
        }
        .task {
            for await update in dataStream {
                data = update
            }
        }
    }
}
```

---

## Rendering Pipeline

The full rendering pipeline, executed every frame:

```
1. State Change
   ↓
2. View Tree Evaluation
   Evaluate `body` properties recursively to produce a tree of primitives.
   ↓
3. Layout Negotiation (recursive)
   Starting from the root, proposals flow down and sizes flow up via sizeThatFits.
   Stacks probe children multiple times (min, max, then concrete proposal).
   ↓
4. Rendering (top-down)
   Each primitive renders into its allocated Buffer region.
   ↓
5. Differential Flush
   Screen compares front and back buffers.
   Emits ANSI escape sequences only for changed cells.
   ↓
6. Terminal Output
   Raw bytes written to stdout.
```

### The Buffer System

The buffer, cell, region, screen, style, and terminal layers from the existing TUI implementation are carried forward largely unchanged. They are well-designed and battle-tested:

- **`Cell`** — One character with one `Style` (fg, bg, bold, dim, italic, underline, inverse, strikethrough). Includes an `isContinuation` flag for the second column of wide characters.
- **`Buffer`** — 2D grid of `Cell`s in row-major order. Provides write, fill, and line-drawing operations. All write operations use `Character.displayWidth` for correct cursor advancement.
- **`Region`** — A rectangular area (row, col, width, height) within a buffer. Supports subregion and inset operations.
- **`Screen`** — Double-buffered rendering. `clear()` resets the back buffer, views render into it, `flush()` diffs against the front buffer and emits only changes.
- **`Style`** — Full styling struct. Supports 16 basic colors, 256 palette, and 24-bit RGB. Generates differential ANSI sequences.
- **`Terminal`** — Static low-level control: raw mode, alternate screen, cursor visibility, size queries via `ioctl`.
- **`KeyReader`** — Reads raw bytes from stdin on a background thread, parses into `KeyEvent`s, exposes as `AsyncStream<KeyEvent>`.

### The Run Loop

```swift
actor RenderEngine {
    let screen: Screen
    let keyReader: KeyReader
    var focusStore: FocusStore

    func start(rootView: any View) async {
        Terminal.enableRawMode()
        Terminal.enterAlternateScreen()

        for await event in mergedEventStream {
            switch event {
            case .key(let key):
                // Route to focus system, then to focused view's handlers
                focusStore.handleKey(key)
            case .resize(let size):
                screen.resize(width: size.width, height: size.height)
            case .stateChange:
                // Re-evaluate and render
                let rootRegion = Region(row: 0, col: 0, width: screen.width, height: screen.height)
                screen.clear()
                render(rootView, into: &screen.back, region: rootRegion)
                screen.flush()
            case .tick:
                // Animation tick for spinners, etc.
                break
            }
        }
    }
}
```

---

## Type Summary

### Core Types

| Type | Kind | Purpose |
|------|------|---------|
| `View` | Protocol | Composite views with `associatedtype Body: View` and `var body: Body` |
| `PrimitiveView` | Protocol | Framework primitives with `sizeThatFits` and `render` |
| `SizeProposal` | Struct | Two-dimensional size proposal (`width: Int?`, `height: Int?`) |
| `Size2D` | Struct | Concrete two-dimensional size response |
| `Buffer` | Struct | 2D grid of `Cell`s for rendering |
| `Region` | Struct | Rectangular area within a buffer |
| `Cell` | Struct | Single character + style + continuation flag |
| `Style` | Struct | Visual attributes (colors, bold, dim, etc.) |
| `Style.Color` | Enum | 16 basic, 256 palette, 24-bit RGB |
| `ViewBuilder` | Result builder | Declarative view composition |
| `App` | Protocol | Application entry point — lifecycle, commands, render loop |
| `KeyEquivalent` | Struct | Named keys and character keys for shortcuts |
| `EventModifiers` | OptionSet | `.control`, `.shift`, `.option` |
| `KeyboardShortcut` | Struct | Key + modifiers combination |
| `CommandGroup` | Struct | Named group of command buttons |

### Layout Primitives

| Type | Category | Sizing |
|------|----------|--------|
| `VStack` | Container | Primary: sum of children + spacing. Cross: max of children. |
| `HStack` | Container | Primary: sum of children + spacing. Cross: max of children. |
| `ZStack` | Container | Max of all children on both axes. |
| `ScrollView` | Container | Greedy on scroll axis. Cross: max of children. |
| `Table` | Container | Greedy. Coordinates column widths across rows. |

### Content Primitives

| Type | Category | Sizing |
|------|----------|--------|
| `Text` | Hugging | Width: content `displayWidth` (wraps if proposed less). Height: line count. |
| `AttributedText` | Hugging | Width: sum of span display widths. Height: 1. |
| `Color` | Greedy | Fills proposed size. |
| `Canvas` | Greedy | Fills proposed size. Custom drawing. |
| `ProgressView` | Mixed | `.compact`: 1x1. `.bar`: greedy width, height 1. |

### Structural Primitives

| Type | Category | Sizing |
|------|----------|--------|
| `Spacer` | Greedy (primary axis) | Absorbs remaining space. Min: `minLength`. |
| `Divider` | Mixed | Greedy on primary axis. Fixed 1 on cross axis. |
| `EmptyView` | None | Zero on both axes. |
| `ForEach` | Transparent | Children participate in parent layout directly. |
| `Group` | Transparent | Children participate in parent layout directly. |

### Interactive Primitives

| Type | Focus | Activation |
|------|-------|------------|
| `Button` | `.activate` | Enter / Space |
| `TextField` | `.edit` | Captures key input |
| `Toggle` | `.activate` | Space |
| `Picker` | `.activate` | Up / Down arrows |
| `TabView` | Container | Left / Right arrows switch tabs |

### Modifier Wrappers (all `PrimitiveView`)

| Type | Modifier | Effect on sizing |
|------|----------|-----------------|
| `PaddedView` | `.padding()` | Adds insets to response, subtracts from proposal |
| `FrameView` | `.frame()` | Clamps or fixes proposal and response |
| `FlexFrameView` | `.frame(min:max:)` | Clamps with asymmetric rules |
| `FixedSizeView` | `.fixedSize()` | Replaces proposal with `nil` (ideal) |
| `BackgroundView` | `.background()` | Transparent — fills before rendering content |
| `OverlayView` | `.overlay { }` | Transparent — renders on top after content |
| `StyledView` | `.style()` etc. | Transparent — post-processes cell styles |
| `BorderedView` | `.border()` | Adds 2 to both axes (1 per side) |
| `HiddenView` | `.hidden()` | Transparent — preserves sizing, skips rendering |
| `PrioritizedView` | `.layoutPriority()` | Transparent — carries priority metadata |
| `ShortcutView` | `.keyboardShortcut()` | Transparent — registers shortcut in the key event system |

### Focus and Input Types

| Type | Purpose |
|------|---------|
| `FocusState<Value>` | Property wrapper for tracking focus |
| `FocusStore` | Engine-internal state tracking current focus and focus ring |
| `FocusInteractions` | Option set: `.edit`, `.activate` |
| `KeyPress` | Key event with `.handled` / `.ignored` result |
| `KeyPress.Result` | `.handled` or `.ignored` — controls event propagation |
| `KeyEquivalent` | Named keys (`.return`, `.escape`, `.upArrow`, etc.) and character keys |
| `EventModifiers` | Option set: `.control`, `.shift`, `.option` |
| `KeyboardShortcut` | Key + modifiers; includes `.defaultAction` (Enter) and `.cancelAction` (Escape) |
| `HorizontalAlignment` | `.leading`, `.center`, `.trailing` |
| `VerticalAlignment` | `.top`, `.center`, `.bottom` |
| `Alignment` | Combined horizontal + vertical alignment |
| `ProgressViewStyle` | `.compact` (single char) or `.bar(showPercent:)` |
| `LabelStyle` | `.automatic`, `.titleOnly`, `.hidden` — generic across labeled views |

---

## Example: Rebuilding StatusLine

**Before (current imperative implementation — 71 lines):**

```swift
public struct StatusLine: View {
    public let left: [TextSpan]
    public let right: [TextSpan]
    public let backgroundStyle: Style

    public var sizing: Sizing { .fixed(1) }

    public func render(into buffer: inout Buffer, region: Region) {
        buffer.fill(Region(...), style: backgroundStyle)
        var col = region.col
        for span in left {
            let merged = span.style.merged(over: backgroundStyle)
            for char in span.text {
                guard col < region.col + region.width else { break }
                buffer[region.row, col] = Cell(char: char, style: merged)
                col += 1
            }
        }
        let rightText = right.map(\.text).joined()
        let rightStart = region.col + region.width - rightText.count
        if rightStart > col {
            var rCol = rightStart
            for span in right {
                // ... more character-by-character rendering
            }
        }
    }
}
```

**After (declarative — 12 lines):**

```swift
struct StatusBar: View {
    let left: [TextSpan]
    let right: [TextSpan]

    var body: some View {
        HStack {
            AttributedText(left)
            Spacer()
            AttributedText(right)
        }
        .background(.brightBlack)
    }
}
```

The layout engine handles left/right alignment, spacing, and background fill automatically.

## Example: Rebuilding TabBar

**Before:** 90 lines of imperative character placement, manual bracket rendering, column tracking.

**After:**

```swift
struct TabBar: View {
    let tabs: [Tab]
    let selected: Int
    let animationTick: Int

    var body: some View {
        HStack(spacing: 0) {
            Text("─").dim()
            ForEach(Array(tabs.enumerated())) { index, tab in
                TabItem(tab: tab, isSelected: index == selected, tick: animationTick)
                Text("──").dim()
            }
            Spacer()  // fills remaining width
        }
    }
}

struct TabItem: View {
    let tab: Tab
    let isSelected: Bool
    let tick: Int

    var body: some View {
        HStack(spacing: 0) {
            Text("[").dim()
            if tab.hasNotification {
                Text("●").foregroundColor(.red).bold()
            }
            if tab.status == .active {
                ProgressView()  // compact indeterminate spinner
                Text(" ")
            }
            Text(tab.label)
                .style(isSelected ? Style(bold: true, inverse: true) : tabStyle)
            Text("]").dim()
        }
    }
}
```

## Example: A Login Form

```swift
struct LoginForm: View {
    enum Field: Hashable { case username, password, submit }

    @FocusState var focus: Field?
    var username: String = ""
    var password: String = ""
    var onLogin: (String, String) -> Void

    var body: some View {
        VStack(spacing: 1) {
            Text("Log In").bold()
            Divider.horizontal

            HStack {
                Text("Username:").frame(width: 12)
                TextField("enter username", text: username, onChange: { username = $0 })
                    .focused($focus, equals: .username)
            }

            HStack {
                Text("Password:").frame(width: 12)
                TextField("enter password", text: password, onChange: { password = $0 })
                    .focused($focus, equals: .password)
            }

            Spacer().frame(height: 1)

            Button("[ Log In ]") {
                onLogin(username, password)
            }
            .focused($focus, equals: .submit)
        }
        .padding(2)
        .border(.rounded)
        .defaultFocus($focus, .username)
    }
}
```

---

## Package Structure

This framework will be a standalone Swift package, separate from OperativeKit and Operator. Suggested name: **TerminalUI** (or **TUI** if brevity is preferred).

```
TerminalUI/
├── Package.swift
├── Sources/
│   └── TerminalUI/
│       ├── Core/
│       │   ├── View.swift              // View, PrimitiveView protocols
│       │   ├── ViewBuilder.swift       // @ViewBuilder result builder
│       │   ├── SizeProposal.swift      // SizeProposal, Size2D
│       │   ├── Alignment.swift         // HorizontalAlignment, VerticalAlignment, Alignment
│       │   └── DisplayWidth.swift      // Character.displayWidth, String.displayWidth
│       ├── Layout/
│       │   ├── VStack.swift
│       │   ├── HStack.swift
│       │   ├── ZStack.swift
│       │   ├── Spacer.swift
│       │   ├── ForEach.swift
│       │   ├── Group.swift
│       │   └── Table.swift
│       ├── Content/
│       │   ├── Text.swift              // Text, AttributedText, TextSpan
│       │   ├── Color.swift
│       │   ├── Canvas.swift
│       │   ├── Divider.swift
│       │   ├── EmptyView.swift
│       │   └── ProgressView.swift      // Unified spinner + progress bar
│       ├── Modifiers/
│       │   ├── PaddedView.swift
│       │   ├── FrameView.swift         // Fixed and flexible frame
│       │   ├── FixedSizeView.swift
│       │   ├── BackgroundView.swift
│       │   ├── OverlayView.swift
│       │   ├── StyledView.swift        // .style(), .bold(), .foregroundColor(), etc.
│       │   ├── BorderedView.swift
│       │   ├── HiddenView.swift
│       │   ├── PrioritizedView.swift   // .layoutPriority()
│       │   └── ShortcutView.swift      // .keyboardShortcut()
│       ├── Controls/
│       │   ├── Button.swift
│       │   ├── TextField.swift
│       │   ├── Toggle.swift
│       │   ├── Picker.swift
│       │   └── TabView.swift
│       ├── Focus/
│       │   ├── FocusState.swift
│       │   ├── FocusStore.swift
│       │   ├── FocusModifiers.swift    // .focused(), .focusable(), .defaultFocus()
│       │   ├── FocusGroup.swift        // Automatic stack focus groups
│       │   └── FocusSection.swift
│       ├── Commands/
│       │   ├── CommandGroup.swift      // Command definition and registry
│       │   ├── CommandBar.swift        // Shortcut bar view
│       │   └── CommandPalette.swift    // Filterable command overlay
│       ├── Input/
│       │   ├── KeyEquivalent.swift     // Named keys, character keys
│       │   ├── EventModifiers.swift    // .control, .shift, .option
│       │   └── KeyboardShortcut.swift  // Key + modifiers, .defaultAction, .cancelAction
│       ├── Rendering/
│       │   ├── Cell.swift              // Character + style + continuation flag
│       │   ├── Style.swift
│       │   ├── Buffer.swift            // Display-width-aware write operations
│       │   ├── Region.swift
│       │   ├── Screen.swift
│       │   └── RenderEngine.swift      // sizeThatFits/render dispatch, key event routing
│       ├── Terminal/
│       │   ├── Terminal.swift           // Raw mode, alternate screen, etc.
│       │   ├── KeyEvent.swift
│       │   └── KeyReader.swift
│       └── App/
│           ├── App.swift               // App protocol, lifecycle management
│           └── RunLoop.swift           // Event stream merging, render cycle
├── Tests/
│   └── TerminalUITests/
│       ├── Core/
│       │   └── DisplayWidthTests.swift // Emoji, CJK, combining marks, ZWJ sequences
│       ├── Layout/
│       │   ├── VStackTests.swift
│       │   ├── HStackTests.swift
│       │   ├── ZStackTests.swift
│       │   ├── SpacerTests.swift
│       │   └── FlexibilityTests.swift  // Flexibility calculation and ordering
│       ├── Content/
│       │   ├── TextSizingTests.swift   // Wrapping, truncation, ideal size, display width
│       │   ├── ProgressViewTests.swift // Spinner and bar variants
│       │   └── DividerTests.swift
│       ├── Modifiers/
│       │   ├── PaddingTests.swift
│       │   ├── FrameTests.swift
│       │   └── FixedSizeTests.swift
│       ├── Rendering/
│       │   ├── BufferTests.swift       // Wide character handling, continuation cells
│       │   └── CellTests.swift
│       └── Integration/
│           └── LayoutIntegrationTests.swift
└── Examples/
    └── Demo/
        └── Sources/
            └── DemoApp.swift           // Showcase app
```

The OK example app would depend on this package instead of containing TUI code directly.

---

## Migration Path

The existing OK TUI code provides a strong foundation. Key components that carry forward as-is:

- `Style`, `Style.Color` — unchanged
- `Region` — unchanged (subregion, inset)
- `Screen` — unchanged (double-buffered differential flush)
- `Terminal` — unchanged (raw mode, alternate screen, size queries)
- `KeyEvent`, `KeyReader` — unchanged

Components that are adapted:

| Component | Changes |
|-----------|---------|
| `Cell` | Adds `isContinuation: Bool` for wide character support |
| `Buffer` | All write operations updated to use `Character.displayWidth`; wide chars write continuation cells |

Components that are replaced:

| Old | New | Notes |
|-----|-----|-------|
| `Sizing` struct | `sizeThatFits` method | Sizing is now a function, not a property |
| `LayoutEngine.distribute()` | Stack algorithm inline | Flexibility-sorted greedy pass inside VStack/HStack |
| `View.sizing` property | `View.body` property | Composite views declare body, not sizing |
| `View.render()` method | `PrimitiveView.render()` | Only primitives implement render |
| `ViewGroup` | `ForEach` / `Group` | Layout-transparent structural types |
| `StatusLine` (imperative) | `StatusBar` (composite) | HStack + Spacer + background |
| `TabBar` (imperative) | `TabView` (primitive) | Built-in tab container with arrow navigation |
| `EventLog` (imperative wrapping) | `ScrollView` + `Text` (wrapping) | Text handles its own wrapping via sizeThatFits |
| `InputLine` (imperative) | `TextField` (primitive) | Built-in text editing with focus |
| `BrailleSpinner` / `AnimatedText` | `ProgressView` | Unified spinner + progress bar |
| `TerminalRunLoop` | `App` + `RunLoop` | Lifecycle, commands, focus, and event routing |
| Manual key handling in `OKStateStore` | Focus system + `onKeyPress` | Declarative key event routing |

---

## Open Design Questions

The following areas need further design work during implementation. They are listed in priority order — the first is the most architecturally significant.

### 1. State Management (Critical)

The examples in this document use `@State` and `@FocusState` property wrappers, but **we have not designed how reactive state works**. This is the biggest open question.

In SwiftUI, `@State` is backed by framework-managed persistent storage, keyed to each view's structural identity in the tree. When a `@State` value mutates, SwiftUI knows which subtree to re-evaluate. This requires:
- A view identity system (structural position or explicit `id`)
- Persistent storage that survives across re-renders
- Change tracking to trigger targeted re-evaluation

There are two viable approaches:

**Option A: External state model (simpler, recommended for v1).** Views are stateless pure functions of their inputs. All mutable state lives outside the view tree — in an actor, observable object, or similar external store. The app re-renders the entire tree when state changes, which is what the current OK example does with `OKStateStore`. `@FocusState` would be a special case managed by the rendering engine's `FocusStore`. There is no `@State` property wrapper. This sidesteps view identity entirely and is straightforward to implement. The performance cost of full re-renders is negligible for terminal UIs (the view tree is small and `Screen.flush` already diffs at the cell level).

**Option B: SwiftUI-like reactive state (ambitious).** `@State` with framework-managed storage, view identity tracking via structural position, and targeted re-renders. This is the "correct" long-term architecture but significantly harder to build. It requires a view identity system, a storage graph parallel to the view tree, and a diffing mechanism to detect which views need re-evaluation. Consider this for a future version once the layout system is proven.

Regardless of approach, `@FocusState` needs special treatment — it must be two-way (programmatic focus changes update the property; user Tab/arrow navigation updates the property) and it must integrate with the rendering engine's focus ring.

### 2. Default Stack Spacing

The stack algorithm subtracts spacing before distributing space, but this document doesn't specify the default. SwiftUI uses adaptive, platform-specific spacing (typically 8pt on iOS). **Recommendation: default to 0 for terminals.** Terminal UIs are space-constrained; implicit spacing would be surprising. Users can specify spacing explicitly: `VStack(spacing: 1) { ... }`.

### 3. ForEach Identity

`ForEach` needs an identity mechanism to correctly handle dynamic collections. SwiftUI supports two patterns:

```swift
ForEach(items) { item in ... }         // items conform to Identifiable
ForEach(items, id: \.name) { item in ... }  // explicit key path
```

For v1, identity is mainly needed for correctness (ensuring the right views map to the right data). For a future version with targeted re-renders (Option B above), identity becomes critical for efficient diffing. **Recommendation: require `Identifiable` or an explicit `id:` parameter from the start**, even if the rendering engine doesn't use it for diffing yet. This keeps the API stable.

### 4. Table Column Coordination

The `Table` primitive needs to coordinate column widths across all rows. The algorithm:
1. Collect column width preferences (fixed vs. flex)
2. Run the HStack layout algorithm once to determine column widths
3. Render each row using those shared widths

The tricky part: if column content varies in width across rows, the Table may need to measure all rows' content to determine the "natural" width of flex columns before distributing. This is a multi-pass algorithm (measure all rows → compute column widths → render all rows). Detail the exact algorithm during implementation, potentially drawing from the stack algorithm's flexibility-sorting approach applied per-column.

### 5. `some View` and `[any View]` Interaction

Composite views return `some View` from `body` (a concrete opaque type). Stacks store `[any View]` (existential array). This works in modern Swift — we verified it compiles and runs correctly (the concrete type is wrapped into the existential automatically). However, this means:
- The `@ViewBuilder` returns `[any View]`, erasing the concrete types of children
- `body` returns `some View` (preserving the concrete type of the composed tree)
- When the rendering engine calls `view.body` on `any View`, Swift's existential opening returns `any View`

This is all fine and tested, but the implementer should be aware that type information is lost at the `[any View]` boundary in stacks. This doesn't affect correctness but means we can't use generic specialization for performance within stack children. For terminal UI performance, this is irrelevant.

### 6. Overlay Sizing

The `.overlay {}` modifier is described but its `sizeThatFits` behavior needs clarification: the **primary view** determines the size. The overlay content is proposed the primary view's actual size and rendered on top, but does not affect the composite view's reported size. This mirrors `.background()` behavior — neither affects layout, they just add visual layers.

### 7. Testing Without a Terminal

Layout and sizing tests should be **pure** — no terminal needed. Create `Buffer` instances directly, render views into them, and assert cell contents. The existing OK test infrastructure already does this with mock buffers. The implementer should establish this pattern early and test all `sizeThatFits` responses and `render` output exhaustively. The `Screen`, `Terminal`, and `KeyReader` layers only need testing in integration/manual testing.

### 8. Reference Material

The following documents in this repository informed this design and should be consulted during implementation:

- `project/2026-02-28-swiftui-layout.md` — Detailed reference on SwiftUI's layout engine internals, including the exact stack algorithm, frame modifier clamping logic, and proposal semantics. **This is the primary implementation reference for the layout system.**
- `project/2026-02-28-tui-framework-vision.md` — This document.
- The existing TUI code in `Examples/OK/Sources/OKCore/TUI/` — Working implementations of Buffer, Screen, Cell, Style, Region, Terminal, KeyReader, and KeyEvent that can be carried forward with minor modifications.
