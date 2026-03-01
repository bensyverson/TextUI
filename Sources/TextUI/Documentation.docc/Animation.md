# Animation

Drive animated views with a frame counter that updates at ~30 fps.

## Overview

TextUI provides a lightweight animation system via the ``AnimationTick``
property wrapper. Any view — composite or primitive — can declare
`@AnimationTick var tick` to receive a frame counter. The run loop
automatically starts and stops a 33ms timer based on whether any view
reads the tick value during rendering.

### Using @AnimationTick

```swift
struct SpinnerView: View {
    @AnimationTick var tick

    var body: some View {
        let frames = ["⠋","⠙","⠹","⠸","⠼","⠴","⠦","⠧","⠇","⠏"]
        Text(frames[tick % frames.count])
    }
}
```

The animation timer starts when a view reads `tick` during rendering and
stops automatically when no views need animation (for example, when a
spinner is removed from the view tree).

### ProgressView

``ProgressView`` is a built-in view that uses `@AnimationTick` internally
to drive spinner and bar animations:

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
