# Animation

Drive animated views with a frame counter that updates at ~30 fps.

## Overview

TextUI provides a lightweight animation system via the ``AnimationTick``
property wrapper and the ``View/animating(_:)`` modifier. Any view —
composite or primitive — can declare `@AnimationTick var tick` to receive
a frame counter, and apply `.animating()` to signal the run loop that the
animation timer should run.

### Using @AnimationTick

```swift
struct SpinnerView: View {
    @AnimationTick var tick

    var body: some View {
        let frames = ["⠋","⠙","⠹","⠸","⠼","⠴","⠦","⠧","⠇","⠏"]
        Text(frames[tick % frames.count])
            .animating()
    }
}
```

Reading `tick` is a pure operation — it returns the current frame count
without side effects. The `.animating()` modifier is what actually keeps
the timer running. This separation allows the run loop to know exactly
which regions are animating, enabling optimizations like skipping layout
re-measurement on animation-only frames.

### The .animating() Modifier

The ``View/animating(_:)`` modifier registers the view's render region
with the ``AnimationTracker``, which tells the run loop to start or
continue the ~30 fps timer. When no views have `.animating()` applied
(e.g., when an animated view is removed from the tree), the timer stops
automatically.

You can conditionally disable animation:

```swift
Text(frames[tick % frames.count])
    .animating(isVisible)
```

**Stable size contract**: Views with `.animating()` should maintain a
stable size across animation frames. This allows the run loop to skip
expensive layout re-measurement during animation-only renders, only
updating the content within the animated regions.

### ProgressView

``ProgressView`` is a composite view that uses `@AnimationTick` and
`@ViewBuilder` to compose ``Text``, ``Canvas``, and ``HStack`` children
depending on the style and label. It applies `.animating()` internally,
so callers don't need to add it:

```swift
// Indeterminate spinner (animates automatically)
ProgressView()
ProgressView("Loading...")

// Determinate progress bar
ProgressView(value: 0.42)
ProgressView("Uploading", value: bytesWritten, total: totalBytes)
```

### ProgressView Styles

Use ``ProgressViewStyle`` to control the visual appearance:

- **`.compact`** — A single-character indicator. Spinner for indeterminate,
  block character for determinate.
- **`.bar(showPercent:)`** — A horizontal bar. Animated stripe for
  indeterminate, filled blocks for determinate.

The default style is `.compact` for indeterminate and `.bar(showPercent: true)`
for determinate. Override with `.progressViewStyle()`:

```swift
ProgressView(value: 0.5)
    .progressViewStyle(.compact)
```

## Topics

### Animation

- ``AnimationTick``

### Progress

- ``ProgressView``
- ``ProgressViewStyle``
