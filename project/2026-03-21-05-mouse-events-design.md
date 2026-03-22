# Mouse Events Design

> This document captures the design for adding mouse event support to TextUI as an opt-in feature. Mouse support turns TextUI into a full text-rendered GUI, while preserving keyboard-only accessibility as a first-class path.

## Goals

1. **Left-click** to activate controls (buttons, toggles, pickers) and focus edit controls (text fields)
2. **Right-click** to open context menus via a `.contextMenu` modifier
3. **Scroll wheel** to scroll the focused view (ScrollView, List, Picker)
4. **Unified tap gesture** — keyboard activation (Enter/Space on a focused control) and mouse click are the same gesture, routed through `.onTapGesture`
5. **Opt-out at app level** via `.allowsMouseEvents(false)`, so end-users can disable mouse capture (e.g., via a CLI flag) and regain normal terminal text selection
6. **Defer hover and drag** to a future iteration

## Key Design Decisions

### 1. Tap = Click = Keyboard Activation

A "tap" is the unified concept for activating a control. It can originate from:
- A mouse left-click on the control's region
- An Enter or Space keypress when the control is focused

Both paths converge in the same handler. This means:
- `Button` internally uses `.onTapGesture` (or an equivalent internal mechanism) for its action
- Every tappable view is focusable — there are no mouse-only interactions
- Keyboard-only users have full access to every interaction

This is critical: **if a control is tappable, it must be reachable and activatable via keyboard.** We enforce this by requiring that anything with `.onTapGesture` is registered in the focus ring. In practice, this means wrapping tappable content in a `Button` if it isn't already a focusable control.

### 2. Click-to-Activate (Not Click-to-Focus)

Clicking a `Button` immediately fires its action — it does not require a first click to focus and a second click to activate. This matches GUI conventions.

For `.edit` controls like `TextField`, clicking focuses the field (placing the cursor) but does not "activate" in the same sense. This matches the existing `FocusInteraction` distinction:
- `.activate` controls: click fires the action immediately
- `.edit` controls: click focuses the control

### 3. All Tappable Views Must Be Focusable

We do **not** support `.onTapGesture` on non-focusable views (like bare `Text`). This prevents creating mouse-only interactions that are inaccessible in keyboard-only mode.

To make arbitrary content tappable, wrap it in a `Button`:

```swift
Button {
    showDetail = true
} label: {
    Text("Turtle Rock")
        .foregroundStyle(.blue)
}
.buttonStyle(.plain)  // No border, just the label
```

A `.plain` button is a zero-chrome wrapper — it renders its label content directly, adding only focusability and tap handling.

### 4. Scroll Routing: Focused, Not Hovered

Scroll wheel events are routed to the **focused** scrollable view, not the view under the mouse pointer. This keeps the event routing model simple (no positional hit-testing for scroll) and consistent with the keyboard-first design.

To scroll a different view, click it first to focus it, then scroll.

### 5. App-Level Mouse Opt-Out

Mouse tracking is **enabled by default**. Apps can disable it:

```swift
@main
struct MyApp: App {
    @Observed var settings = AppSettings()

    var body: some View {
        ContentView()
    }

    var commands: [CommandGroup] { [] }

    func configure(_ app: AppConfiguration) {
        app.allowsMouseEvents(settings.mouseEnabled)
    }
}
```

Or driven by a CLI flag:

```swift
app.allowsMouseEvents(!CommandLine.arguments.contains("--no-mouse"))
```

When mouse events are disabled:
- Terminal mouse tracking sequences are not sent
- The terminal behaves normally (text selection, copy/paste work as expected)
- All controls remain fully functional via keyboard

### 6. Terminal Text Selection Tradeoff

When mouse mode is active, the terminal captures all mouse events, which disables native text selection. Users can still select text using terminal-specific workarounds:
- **iTerm2**: Hold Option and click/drag
- **Terminal.app**: Hold Fn and click/drag
- **kitty**: Hold Shift and click/drag

The `.allowsMouseEvents(false)` escape hatch lets users who primarily need text selection disable mouse capture entirely.

## Terminal Protocol: SGR Extended Mouse Mode

We use **SGR extended mouse mode** (mode 1006) with **button-event tracking** (mode 1002). This is the modern standard supported by all major terminals (iTerm2, Terminal.app, kitty, Alacritty, Windows Terminal, xterm).

### Enable/Disable Sequences

```
Enable:  ESC[?1002h  (button-event tracking: press, release, drag)
         ESC[?1006h  (SGR extended format)

Disable: ESC[?1006l
         ESC[?1002l
```

These are sent during terminal setup/teardown in `Terminal.enableRawMode()` / `disableRawMode()` (conditional on mouse being enabled).

### Event Format

SGR mouse events are CSI sequences:

```
ESC [ < button ; column ; row M    (press / drag motion)
ESC [ < button ; column ; row m    (release)
```

- Coordinates are **1-based** (matching terminal convention)
- Button field encodes button identity + modifiers:

| Button Value | Meaning |
|---|---|
| 0 | Left button |
| 1 | Middle button |
| 2 | Right button |
| 32+ | Motion (add to button value for drag) |
| 64 | Scroll up |
| 65 | Scroll down |
| +4 | Shift held |
| +8 | Alt/Meta held |
| +16 | Ctrl held |

## Architecture

### New Types

#### `MouseEvent`

```swift
/// A mouse event received from the terminal.
public struct MouseEvent: Friendly {
    /// The kind of mouse event.
    public enum Kind: Friendly {
        case press
        case release
    }

    /// The mouse button involved.
    public enum Button: Friendly {
        case left
        case right
        case middle
        case scrollUp
        case scrollDown
    }

    /// The button that was pressed or released.
    public let button: Button

    /// The kind of event (press or release).
    public let kind: Kind

    /// The column where the event occurred (0-based, converted from 1-based terminal coordinates).
    public let column: Int

    /// The row where the event occurred (0-based, converted from 1-based terminal coordinates).
    public let row: Int

    /// Modifier keys held during the event.
    public let modifiers: EventModifiers
}
```

#### `TapTarget` (internal)

```swift
/// A region on screen that responds to tap gestures, registered during render.
struct TapTarget {
    let id: Int                    // Matches FocusEntry.id
    let region: Region
    let handler: () -> Void        // The tap action
}
```

This is stored alongside the focus ring. Since every tappable view is focusable, there's a 1:1 correspondence between tap targets and focus entries. The `TapTarget` adds the action closure that should fire on click.

### Event Flow

#### Parsing

The CSI parser in `KeyEvent.parseCSI()` is extended to detect the `<` prefix that distinguishes SGR mouse sequences from keyboard sequences:

```
ESC [ < ...    → mouse event
ESC [ ...      → keyboard event (existing path)
```

Mouse bytes are parsed into a `MouseEvent` and returned as a new case in the event stream.

#### RunLoop Integration

```swift
enum Event: Sendable {
    case key(KeyEvent)
    case mouse(MouseEvent)      // NEW
    case stateChanged
    case resize(Terminal.Size)
    case shutdown
}
```

The merged event stream gains a mouse source (which is really the same stdin stream — the KeyReader parses both key and mouse events).

#### Routing

```swift
// In RunLoop
func handleMouse(_ event: MouseEvent) {
    switch event.button {
    case .scrollUp, .scrollDown:
        handleScroll(event)
    case .left where event.kind == .press:
        handleLeftClick(event)
    case .right where event.kind == .press:
        handleRightClick(event)
    default:
        break  // Ignore release, middle click, drag (for now)
    }
}
```

**Left click routing:**
1. Hit-test `event.row, event.column` against focus ring entries (by `Region`)
2. If hit is an `.activate` control → focus it AND fire its tap action
3. If hit is an `.edit` control → focus it (place cursor at click position if applicable)
4. If no hit → do nothing (or dismiss any open overlay/palette)

**Right click routing:**
1. Hit-test against focus ring entries
2. If the hit control (or an ancestor) has a `.contextMenu` → show it
3. If no context menu → do nothing

**Scroll routing:**
1. Route to the currently focused view's scroll handler (if any)
2. No hit-testing needed — always goes to focused view

### Modifications to Existing Types

#### `Button` — Unified Tap Gesture

Button's inline handler currently handles Enter and Space directly. With mouse support, Button also needs to be a tap target. The change is:

1. Button continues to register in the focus ring with `.activate` interaction
2. Button registers a **tap target** with its action closure during render
3. The inline handler for Enter/Space remains (keyboard path)
4. Mouse left-click on the button's region triggers the tap target (mouse path)

Both paths call the same `action` closure. The key insight is that the focus ring already has the `Region` for hit-testing — we just need to associate actions with those regions.

Alternatively, we could refactor Button to use `.onTapGesture` internally, which would be the single source of truth for both keyboard and mouse activation. This is the cleaner approach:

```swift
// Conceptually, Button becomes:
content
    .focusable(.activate)
    .onTapGesture { action() }
```

Where `.onTapGesture` registers both the inline keyboard handler (Enter/Space → fire) and the mouse tap target.

#### `FocusStore` — Hit Testing

Add a method to find a focus entry by screen position:

```swift
func entry(at row: Int, column: Int) -> FocusEntry? {
    ring.last { $0.region.contains(row: row, column: column) }
}
```

We search in **reverse** ring order (`last`, not `first`) because the focus ring is populated during depth-first rendering — later entries correspond to views rendered on top. This naturally handles:

- **ZStack**: Later children render on top and register later in the ring
- **Overlays**: Registered after the main view tree, so they're at the end of the ring

Reverse search means a Picker dropdown or context menu overlay always wins the hit test over the controls beneath it. No special ZStack or overlay logic needed.

`Region` will also need a `contains(row:column:)` method added — it doesn't currently have one.

**Note on overlapping views:** Hit testing uses the focus entry's `Region`, which matches the control's laid-out size — not the parent container's size. This means a small Button in a large ZStack only has a small hit area. Non-focusable views (Text, Spacer, etc.) don't participate in hit testing at all, so they can't block clicks on controls beneath them. The one theoretical edge case — two overlapping focusable controls where the topmost has visual "holes" — is not handled (the topmost region always wins). This is an acceptable limitation; overlapping focusable controls is unusual.

#### `Terminal` — Mouse Mode Control

```swift
public static func enableMouseTracking() {
    write("\u{1B}[?1002h")  // Button-event tracking
    write("\u{1B}[?1006h")  // SGR extended format
}

public static func disableMouseTracking() {
    write("\u{1B}[?1006l")
    write("\u{1B}[?1002l")
}
```

Called conditionally during setup/teardown based on the app's mouse configuration.

#### `KeyReader` — Parse Mouse Events

The `KeyReader` already reads raw bytes and calls `KeyEvent.parse()`. We extend the CSI parser to detect `ESC [ <` and route to a `MouseEvent.parse()` path. The reader's output stream changes from `AsyncStream<KeyEvent>` to `AsyncStream<InputEvent>`:

```swift
enum InputEvent: Sendable {
    case key(KeyEvent)
    case mouse(MouseEvent)
}
```

### Context Menus

#### `.contextMenu` Modifier

```swift
extension View {
    public func contextMenu<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View
}
```

A context menu is triggered by right-click on the modified view's region. It renders as an overlay (using the existing `OverlayStore`) anchored near the click position:

```swift
Text("Turtle Rock")
    .contextMenu {
        Button("Add to Favorites") { addFavorite() }
        Button("Show in Maps") { showInMaps() }
    }
```

**Rendering:** Context menus render as a bordered vertical list of buttons, similar to Picker's dropdown overlay. Clicking outside the menu or pressing Escape dismisses it.

**Keyboard access:** Context menus are also accessible via a keyboard shortcut (Shift+F10 or a configurable key), ensuring keyboard-only users can access them.

**Implementation:** Context menus reuse the overlay infrastructure that Picker already uses. A `ContextMenuView` modifier stores its content builder, and on right-click (or keyboard trigger), pushes an overlay to `OverlayStore` anchored at the target's region.

## Implementation Plan

### Phase 1: Terminal & Parsing Foundation

1. Add `MouseEvent` type
2. Create `InputEvent` enum to wrap `KeyEvent` and `MouseEvent`
3. Extend CSI parser to detect and parse SGR mouse sequences
4. Update `KeyReader` to emit `InputEvent` instead of `KeyEvent`
5. Add `Terminal.enableMouseTracking()` / `disableMouseTracking()`
6. Add mouse enable/disable to terminal setup/teardown lifecycle
7. Add `.allowsMouseEvents()` app configuration

### Phase 2: Event Routing & Hit Testing

1. Add `.mouse(MouseEvent)` case to `RunLoop.Event`
2. Add `entry(at:)` hit-testing to `FocusStore`
3. Implement `handleMouse()` in RunLoop
4. Implement left-click → focus + activate routing
5. Implement scroll wheel → focused view routing

### Phase 3: Unified Tap Gesture

1. Add `.onTapGesture` modifier
2. Refactor `Button` to use `.onTapGesture` internally
3. Ensure Enter/Space keyboard activation routes through the same path
4. Add tap target registration to focus ring

### Phase 4: Context Menus

1. Add `.contextMenu` modifier
2. Implement context menu overlay rendering (reuse Picker overlay infrastructure)
3. Wire right-click → context menu display
4. Add keyboard shortcut for context menu access (Shift+F10)
5. Implement dismiss-on-click-outside and Escape

### Phase 5: Polish & Documentation

1. Update DocC documentation
2. Add mouse event documentation article
3. Update demo app to showcase mouse interactions
4. Test across terminals (iTerm2, Terminal.app, kitty, Alacritty)

## Open Questions (Deferred)

- **Hover effects** (`.onHover`, highlight on mouseover): Requires mode 1003 (any-event tracking), which is expensive. Deferred.
- **Drag gestures** (`.onDrag`, resizable split panes): Complex state management. Deferred.
- **Double-click**: Could map to a "select word" gesture in TextField. Deferred.
- **Mouse cursor shape**: Some terminals support changing the cursor shape (pointer vs text). Deferred.
- **Click position in TextField**: When clicking a TextField, place the cursor at the click column. Nice-to-have for Phase 2.
