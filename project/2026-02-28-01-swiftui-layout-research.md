# SwiftUI's layout engine: a complete reimplementation reference

**SwiftUI's layout system is a three-phase, tree-recursive negotiation** where parents propose sizes, children choose their own sizes (non-negotiably), and parents then position children. Unlike constraint-based systems like Auto Layout, SwiftUI uses a single-pass greedy allocation algorithm with no backtracking. This document captures the exact rules, formulas, and edge cases with enough precision to reimplement the engine in another framework.

The system rests on one inviolable principle: **a child always chooses its own size, and the parent must respect that choice**. The parent's only powers are what size to propose and where to place the child afterward. This creates a clean, predictable contract at every node in the view tree.

---

## The three-phase negotiation and ProposedViewSize semantics

Every layout interaction in SwiftUI follows three steps, executed recursively from the root of the view tree:

**Phase 1 — Parent proposes a size to the child (top-down).** The root view receives the screen size minus safe area insets as its initial proposal (e.g., **390×763** on iPhone 13 Pro). Each parent then proposes a `ProposedViewSize` to each child. This proposal is a suggestion, not a constraint. Parents may call `sizeThatFits` on a child multiple times with different proposals to probe the child's flexibility before committing.

**Phase 2 — Child responds with its chosen size (bottom-up).** The child returns a concrete `CGSize`. It may accept the proposal exactly, partially use it, ignore it, or even exceed it. This response is final — the parent cannot override it.

**Phase 3 — Parent positions the child (top-down).** The parent places each child within its own coordinate space, typically using an alignment anchor. SwiftUI then rounds all final positions and sizes to the nearest pixel boundary for crisp rendering.

### ProposedViewSize: the four modes per dimension

`ProposedViewSize` has two `Optional<CGFloat>` fields (`width` and `height`), each operating independently in one of four modes:

| Value | Name | Meaning | Child should return |
|-------|------|---------|-------------------|
| Concrete (e.g. `200.0`) | Explicit | "I'm offering exactly this much space" | Size appropriate for that offer |
| `0.0` | Minimized | "What is your minimum size?" | Minimum size in that dimension |
| `.infinity` | Maximized | "What is your maximum size?" | Maximum size in that dimension |
| `nil` | Unspecified | "What is your ideal size?" | Ideal (intrinsic) size |

Three predefined constants exist: `ProposedViewSize.zero` is `(0, 0)`, `.infinity` is `(.infinity, .infinity)`, and `.unspecified` is `(nil, nil)`. Proposals can mix modes across dimensions — for example, `(width: 300, height: nil)` means "I'm offering 300pt wide; tell me your ideal height at that width."

**The critical distinction between `nil` and `.infinity`**: `nil` asks for the ideal/intrinsic size (what `fixedSize()` does internally). `.infinity` asks for the maximum size. For **Text**, both return the same single-line unwrapped size since text doesn't grow beyond its content. For **shapes and Color**, `nil` returns **10×10** (the platform default fallback) while `.infinity` returns **∞×∞**. This difference is why `Color.red.fixedSize()` renders as a tiny 10×10 square.

The helper method `replacingUnspecifiedDimensions(by: CGSize = CGSize(width: 10, height: 10))` converts `nil` values to a provided default, which is how the 10×10 fallback propagates.

---

## How built-in views respond to proposals

Every built-in view falls into one of three categories: **expanding** (greedy — fills proposed space), **hugging** (shrinks to content), or **neutral** (inherits behavior from children).

### Expanding (greedy) views

**Rectangle, Ellipse, Capsule, RoundedRectangle** accept the proposed size exactly. Proposed `(200, 100)` → reports `(200, 100)`. Proposed `nil` → reports **10×10** (ideal). Proposed `.infinity` → reports **∞×∞**. Proposed `0` → reports **0×0**.

**Circle** is the exception among shapes: it always reports a **square** size equal to `min(proposedWidth, proposedHeight)`. Proposed `(200, 100)` → reports `(100, 100)`.

**Color** behaves identically to Rectangle for layout purposes — fully greedy, ideal size 10×10.

**Spacer** expands along its containing stack's axis. Its behavior depends on the parent's `stackOrientation`:

| Context | Min size | Ideal size | Max size |
|---------|----------|-----------|----------|
| HStack (horizontal) | 8×0 | 8×0 | ∞×0 |
| VStack (vertical) | 0×8 | 0×8 | 0×∞ |
| No stack / ZStack | 8×8 | 8×8 | ∞×∞ |

The **8pt** minimum is the default when `minLength` is nil. `Spacer(minLength: 0)` allows it to collapse completely. Spacers have extremely high flexibility (∞ − 8 ≈ ∞), so in stacks they receive space **last** after less-flexible views are satisfied.

**GeometryReader** accepts the full proposed size (greedy). It proposes that same size to its children and places them at the **top-leading** origin (unlike most SwiftUI views which default to center). Its ideal size is **10×10**, which causes problems inside ScrollView (which proposes `nil` in the scroll axis).

**Resizable Image** (after `.resizable()`) accepts the proposed size. With `.aspectRatio(contentMode: .fit)` it fits within the proposal maintaining ratio; with `.fill` it may exceed the proposal in one dimension.

### Hugging views

**Text** is the prototypical hugging view. When proposed a concrete width narrower than its single-line width, it wraps at word boundaries and grows taller. When proposed a width wider than needed, it does **not** expand — it returns only the width required. When proposed `nil` or `.infinity`, it returns its single-line unwrapped bounding box. When proposed `0`, it returns **0×0**.

**Non-resizable Image** ignores all proposals entirely and always reports its intrinsic point size (asset pixels ÷ scale factor). An 80×80pt image reports 80×80 whether proposed 40×40 or 400×400.

**Divider** is mixed: it expands along the containing stack's primary axis but hugs at the system hairline width (~0.5–1pt) on the perpendicular axis.

### Neutral views

**HStack, VStack, ZStack, Group, ForEach**, and custom `View` structs are neutral — their size is determined entirely by their children. A VStack containing only Text views hugs content; a VStack containing one Color expands. Group and ForEach are **layout-transparent** — they are skipped in the layout tree and their children connect directly to the nearest layout-capable ancestor.

---

## The stack layout algorithm: HStack and VStack

HStack and VStack use the **same algorithm** with axes swapped. It is a sequential greedy allocation — not a constraint solver.

### Step 1: Calculate and subtract spacing

If `spacing` is explicitly set (e.g., `HStack(spacing: 10)`), that value is used uniformly between every adjacent pair. If `spacing` is `nil` (the default), SwiftUI uses **adaptive spacing** — a per-pair value computed from the types of adjacent views following platform HIG conventions. This spacing varies by view type and platform (iOS vs macOS vs watchOS). The total spacing is subtracted from the available space, yielding **remaining distributable space**.

### Step 2: Group by layout priority, then sort by flexibility

Children are first grouped by `layoutPriority` in **descending** order (highest priority first, default is `0.0`). Within each priority group, children are sorted by **flexibility in ascending order** (least flexible first).

**Flexibility** is computed by probing each child twice: `flexibility = sizeThatFits(.infinity).width − sizeThatFits(0).width` along the stack axis. A non-resizable Image returns the same size for both proposals → flexibility = 0. A Text returns wrapped-minimum vs. unwrapped → moderate flexibility. A Rectangle or Spacer returns 0 vs. ∞ → very high flexibility.

### Step 3: Iterative space distribution

```
remainingSpace = availableSpace − totalSpacing
remainingCount = numberOfChildren

for each child (processed in priority-then-flexibility order):
    equalShare = remainingSpace / remainingCount
    childSize = child.sizeThatFits(equalShare)
    remainingSpace -= childSize
    remainingCount -= 1
```

Because **least-flexible** children are processed first, they claim exactly what they need (often less than their equal share). The surplus cascades to more-flexible children. If a child claims more than its share, subsequent children get reduced proposals. The stack never forcibly compresses a child below what it reports.

### Step 4: Cross-axis alignment and final sizing

Children are placed sequentially along the primary axis with computed spacing. On the cross axis, each child is aligned according to the stack's `alignment` parameter (default `.center`). **The stack's own size** equals the sum of all children's primary-axis sizes plus total spacing on the primary axis, and the maximum of all children's sizes on the cross axis.

### ZStack algorithm

ZStack is fundamentally different: it proposes the **same size** (its parent's proposal) to **all children independently**. Children's sizes don't affect each other. The ZStack's own size equals the **union of all children's frames** after alignment. Layout priority in ZStack affects only the **container's reported size** — only children with the highest priority contribute to the ZStack's bounds, though all children are still rendered.

---

## Layout priority and fixedSize

### `.layoutPriority(_: Double)`

Default value is **0.0**. Accepts any `Double` including negative and fractional values. In HStack/VStack, it **overrides the flexibility-based ordering**:

1. Children are grouped by priority (descending — highest first)
2. The highest-priority group gets the full remaining space offered first using the standard flexibility sub-algorithm
3. After that group is sized, remaining space passes to the next-lower priority group
4. This repeats until all groups are processed

A view with `layoutPriority(1)` gets "first pick" of space regardless of flexibility. **Negative priorities** (e.g., `-1`) cause those views to receive space last, after all default-priority views. Additionally, stacks treat greedy views (shapes, spacers) and non-greedy views (text, framed views) in separate buckets — a Text at priority −100 can still appear while a Rectangle at priority 0 gets nothing, because non-greedy views are satisfied at their intrinsic size before greedy views compete for remaining space.

### `.fixedSize(horizontal:vertical:)`

This modifier works by **replacing the parent's proposal with `nil`** (unspecified) in the specified axes, causing the child to render at its ideal size:

```swift
func sizeThatFits(proposal: ProposedViewSize) -> CGSize {
    let w = horizontal ? nil : proposal.width
    let h = vertical ? nil : proposal.height
    return child.sizeThatFits(ProposedViewSize(width: w, height: h))
}
```

`fixedSize()` with no parameters applies to both axes. `fixedSize(horizontal: false, vertical: true)` is the common pattern for preventing vertical truncation in stacks — Text wraps at the proposed width but grows as tall as needed. Unlike `layoutPriority`, `fixedSize` can cause views to **overflow their parent bounds** since it ignores the proposal entirely.

---

## The frame modifier: exact clamping logic

SwiftUI has two distinct frame modifiers that are different types internally.

### Fixed frame: `.frame(width:height:alignment:)`

Implemented as `_FrameLayout`. Per dimension: if the value is specified, the frame **proposes that exact value** to the child AND **reports that exact value** to the parent, regardless of what the child reports. If the value is `nil`, the frame is transparent on that dimension — the parent's proposal passes through to the child and the child's response passes through to the parent. Children may overflow the frame bounds.

### Flexible frame: `.frame(minWidth:idealWidth:maxWidth:minHeight:idealHeight:maxHeight:alignment:)`

Implemented as `_FlexFrameLayout`. The clamping logic per dimension (using width as the example) follows these exact rules:

```
if idealWidth != nil AND proposedWidth == nil:
    result = idealWidth                          // Ideal overrides unspecified proposal

else if minWidth == nil AND maxWidth == nil:
    result = childContentSize                    // No constraints → pass through

else if minWidth != nil AND maxWidth != nil:
    result = clamp(minWidth, proposedWidth ?? childContentSize, maxWidth)
    // BOTH set → clamps the PROPOSED size (not content size)

else if only minWidth != nil:
    result = max(childContentSize, minWidth)     // Floor on content size

else if only maxWidth != nil:
    result = min(proposedWidth ?? childContentSize, maxWidth)
    // Ceiling on proposed size
```

**The critical asymmetry**: when both min and max are set, the **proposed size** is clamped. When only min is set, the **content size** is clamped. When only max is set, the **proposed size** is clamped. This produces subtle behavioral differences.

The frame proposes its computed size to the child and reports that same computed size to the parent. When min > max, SwiftUI logs "Contradictory frame constraints specified" and behavior is undefined.

**`.frame(maxWidth: .infinity)` vs `.frame(minWidth: 0, maxWidth: .infinity)`**: The first reports `max(contentSize, proposedWidth)` — it won't shrink below the child's natural size. The second unconditionally clamps between 0 and ∞, which always equals the proposed width regardless of content. Use `minWidth: 0, maxWidth: .infinity` for true "fill width" behavior.

---

## GeometryReader, padding, overlay, and background

### GeometryReader

GeometryReader is greedy: it reports the parent's proposed size as its own size. It proposes that same size to its children. Children are placed at the **top-leading origin** (not centered). Its ideal size is 10×10. `GeometryProxy` provides `size`, `safeAreaInsets`, and `frame(in:)` for coordinate space conversion.

**Best practice**: use GeometryReader inside `.background` or `.overlay` to read geometry without affecting layout. Inside ScrollView, GeometryReader collapses to 10pt in the scroll axis because ScrollView proposes `nil`.

### Padding

Padding **subtracts** from the proposal before forwarding to the child and **adds** back to the child's reported size. With `.padding(10)` on all edges: parent proposes 100×100 → padding proposes 80×80 to child → child reports 74×68 → padding reports 94×88 to parent. Default padding is approximately **16pt** per side on iOS (platform-dependent). When the parent proposes `nil`, padding passes `nil` through unchanged to the child, then adds its insets to the child's ideal size response.

### Overlay and background

**Neither modifier affects the primary view's layout.** The primary view receives the parent's proposal and reports its size normally. The secondary (overlay/background) view is then proposed **the primary view's reported size**. The composite view's reported size equals the primary view's size exclusively. This is why `.background` and `.overlay` are safe places for GeometryReader — they read the primary view's actual size without influencing it.

---

## Alignment and custom alignment guides

### How alignment works in stacks

VStack takes a `HorizontalAlignment` parameter (default `.center`) controlling cross-axis positioning. HStack takes a `VerticalAlignment` parameter. Built-in horizontal alignments: `.leading`, `.center`, `.trailing`. Built-in vertical alignments: `.top`, `.center`, `.bottom`, **`.firstTextBaseline`**, **`.lastTextBaseline`**. Baseline alignments fall back to `.bottom` for non-text views.

In ZStack, the `Alignment` parameter (combining both axes) positions all children relative to each other. The alignment point of each child is computed and all children's alignment points are made coincident.

### Custom alignment guides

The `.alignmentGuide(_:computeValue:)` modifier takes a closure receiving `ViewDimensions` (which provides `width`, `height`, and subscript access to any alignment guide's implicit or explicit value) and returns a `CGFloat` offset. **Only guides matching the container's alignment parameter take effect** — non-matching guides are ignored during layout.

Alignment guides propagate through the hierarchy: if a child lacks an explicit guide, SwiftUI queries its descendants. Custom alignment IDs are created via `AlignmentID` protocol with a `defaultValue(in:)` method.

---

## The Layout protocol (iOS 16+)

The `Layout` protocol requires two methods:

**`sizeThatFits(proposal:subviews:cache:) → CGSize`** returns the container's size given a proposal and its subviews. SwiftUI calls this multiple times with `.zero`, `.unspecified`, `.infinity`, and the actual proposal to probe flexibility. Returned values should be **monotonically consistent**: size for `.zero` ≤ `.unspecified` ≤ `.infinity`.

**`placeSubviews(in bounds:proposal:subviews:cache:)`** positions each subview. The `bounds` rectangle's origin **may not be (0,0)** — always use `bounds.minX`/`bounds.minY`. Each subview is placed via `subview.place(at:anchor:proposal:)`. Unplaced subviews default to centered in bounds.

### LayoutSubview proxy

Each subview proxy provides: `sizeThatFits(_:)` to query the subview's size for any proposal, `dimensions(in:)` for alignment guide access, `spacing` for platform-appropriate spacing preferences, `priority` for the subview's layout priority, and subscript access to custom `LayoutValueKey` values.

### Cache mechanism

`makeCache(subviews:)` creates initial cache data (called once). `updateCache(_:subviews:)` is called when subviews change. The cache shares computed data between `sizeThatFits` and `placeSubviews` to avoid redundant calculations across the multiple probing calls. Default cache type is `Void`.

### Layout properties

The `layoutProperties` static property returns `LayoutProperties` with `stackOrientation: Axis?` — this tells Spacer which axis to expand on. Set to `.horizontal` for HStack-like layouts, `.vertical` for VStack-like layouts.

---

## Safe area insets and the full layout pass sequence

### Safe area propagation

The root view receives a proposal of **screen size minus safe area insets**. Safe area insets flow down through the hierarchy — nested views receive insets only for the portion of their bounds that overlaps unsafe regions. `.ignoresSafeArea()` causes a view to **extend into the unsafe region** only when it touches the safe area edge; it has no effect otherwise. Three region types exist: `.container` (device chrome), `.keyboard` (soft keyboard), and `.all`. ScrollView and List fill the full screen but inset content within the safe area — content scrolls behind unsafe areas.

### The complete layout pass sequence

1. **View tree evaluation**: SwiftUI evaluates `body` properties and diffs the structural view tree
2. **Negotiation phase (recursive)**: Starting from root, proposals flow down and sizes flow up via `sizeThatFits`. Parents may probe children multiple times with `(0, 0)`, `(nil, nil)`, `(.infinity, .infinity)`, and the actual proposal
3. **Placement phase (top-down)**: Parents assign positions via `placeSubviews`. All coordinates are rounded to nearest device pixel
4. **Rendering**: The positioned, sized views are drawn to screen

Modifiers form a **chain of nested layout containers** — each modifier wraps its content in a new layout node. `Text("Hi").padding(10).frame(width: 200)` creates three nodes: `_FrameLayout` → `_PaddingLayout` → `Text`. Proposals cascade inward through this chain, sizes cascade outward, and positions cascade inward again. Layout-neutral views (custom `View` structs, `Group`, `ForEach`) are transparent in this chain — their children connect directly to the nearest layout-capable ancestor.

## Conclusion

The engine's power comes from its simplicity: a single recursive protocol where every node independently decides its own size. The key implementation details are the **flexibility-sorted greedy allocation** in stacks, the **four proposal modes** (concrete, zero, infinity, nil) that let containers probe children's size ranges, and the strict rule that **children own their size**. The frame modifier's asymmetric clamping logic (proposed size when both bounds are set, content size when only min is set) and the distinction between `nil` proposals (ideal/intrinsic size) and `.infinity` proposals (maximum size) are the most common sources of unexpected behavior. For reimplementation, the stack algorithm is the most complex piece — but it is fundamentally a single sequential pass over flexibility-sorted children, not a constraint solver, which makes it tractable to port to any framework.