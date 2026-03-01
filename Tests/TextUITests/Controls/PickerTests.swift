import Testing
@testable import TextUI

/// Thread-safe mutable value for use in `@Sendable` test closures.
private final class Box<T: Sendable>: @unchecked Sendable {
    var value: T
    init(_ value: T) {
        self.value = value
    }
}

@Suite("Picker")
struct PickerTests {
    let options = ["Red", "Green", "Blue"]

    @Test("Sizing accommodates label + arrows + widest option")
    func sizing() {
        let picker = Picker("Color", selection: 0, options: options) { _ in }
        let size = sizeThatFits(picker, proposal: SizeProposal(width: 80, height: 10))
        // "Color" (5) + ": " (2) + "< " (2) + "Green" (5, widest) + " >" (2) = 16
        #expect(size == Size2D(width: 16, height: 1))
    }

    @Test("Renders current option with arrows")
    func rendering() {
        let picker = Picker("Color", selection: 1, options: options) { _ in }
        var buffer = Buffer(width: 30, height: 1)
        let region = Region(row: 0, col: 0, width: 30, height: 1)
        render(picker, into: &buffer, region: region)

        // Read the rendered text
        var rendered = ""
        for c in 0 ..< 30 {
            let cell = buffer[0, c]
            if !cell.isContinuation {
                rendered.append(cell.char)
            }
        }
        let trimmed = rendered.trimmingCharacters(in: .whitespaces)
        #expect(trimmed.contains("Color"))
        #expect(trimmed.contains("Green"))
        #expect(trimmed.contains("<"))
        #expect(trimmed.contains(">"))
    }

    @Test("Left/Right cycles selection via onChange")
    func arrowCyclesSelection() {
        let store = FocusStore()
        var ctx = RenderContext()
        ctx.focusStore = store

        let received = Box(0)
        let picker = Picker("Color", selection: 0, options: options) { newIndex in
            received.value = newIndex
        }

        var buffer = Buffer(width: 30, height: 1)
        let region = Region(row: 0, col: 0, width: 30, height: 1)

        render(picker, into: &buffer, region: region, context: ctx)
        store.applyDefaultFocus()
        store.beginFrame()
        render(picker, into: &buffer, region: region, context: ctx)

        // Right: 0 → 1
        var result = store.routeKeyEvent(.right)
        #expect(result == .handled)
        #expect(received.value == 1)

        // Left wraps: 0 → 2 (re-render with selection=0)
        store.beginFrame()
        let picker2 = Picker("Color", selection: 0, options: options) { newIndex in
            received.value = newIndex
        }
        render(picker2, into: &buffer, region: region, context: ctx)
        result = store.routeKeyEvent(.left)
        #expect(result == .handled)
        #expect(received.value == 2)
    }

    @Test("Space opens dropdown and Enter selects")
    func dropdownViaSpace() {
        let store = FocusStore()
        var ctx = RenderContext()
        ctx.focusStore = store

        let received = Box(0)
        let picker = Picker("Color", selection: 0, options: options) { newIndex in
            received.value = newIndex
        }

        var buffer = Buffer(width: 30, height: 5)
        let region = Region(row: 0, col: 0, width: 30, height: 5)

        render(picker, into: &buffer, region: region, context: ctx)
        store.applyDefaultFocus()
        store.beginFrame()
        render(picker, into: &buffer, region: region, context: ctx)

        // Space opens dropdown
        var result = store.routeKeyEvent(.character(" "))
        #expect(result == .handled)

        // Re-render with dropdown open
        store.beginFrame()
        render(picker, into: &buffer, region: region, context: ctx)

        // Down moves to "Green" (index 1)
        result = store.routeKeyEvent(.down)
        #expect(result == .handled)

        // Enter selects
        store.beginFrame()
        render(picker, into: &buffer, region: region, context: ctx)
        result = store.routeKeyEvent(.enter)
        #expect(result == .handled)
        #expect(received.value == 1)
    }

    @Test("Escape closes dropdown without changing selection")
    func dropdownEscapeCancels() {
        let store = FocusStore()
        var ctx = RenderContext()
        ctx.focusStore = store

        let received = Box(-1)
        let picker = Picker("Color", selection: 0, options: options) { newIndex in
            received.value = newIndex
        }

        var buffer = Buffer(width: 30, height: 5)
        let region = Region(row: 0, col: 0, width: 30, height: 5)

        render(picker, into: &buffer, region: region, context: ctx)
        store.applyDefaultFocus()
        store.beginFrame()
        render(picker, into: &buffer, region: region, context: ctx)

        // Enter opens dropdown
        store.routeKeyEvent(.enter)
        store.beginFrame()
        render(picker, into: &buffer, region: region, context: ctx)

        // Escape closes without selecting
        let result = store.routeKeyEvent(.escape)
        #expect(result == .handled)
        #expect(received.value == -1) // onChange never called
    }

    @Test("Dropdown renders via deferred overlay")
    func dropdownUsesOverlay() {
        let store = FocusStore()
        let overlayStore = OverlayStore()
        var ctx = RenderContext()
        ctx.focusStore = store
        ctx.overlayStore = overlayStore

        let picker = Picker("Color", selection: 0, options: options) { _ in }

        var buffer = Buffer(width: 30, height: 6)
        let region = Region(row: 0, col: 0, width: 30, height: 6)

        render(picker, into: &buffer, region: region, context: ctx)
        store.applyDefaultFocus()
        store.beginFrame()
        overlayStore.beginFrame()
        render(picker, into: &buffer, region: region, context: ctx)

        // Open dropdown
        _ = store.routeKeyEvent(.character(" "))
        store.beginFrame()
        overlayStore.beginFrame()
        render(picker, into: &buffer, region: region, context: ctx)

        // Overlay should have been registered
        #expect(overlayStore.overlays.count == 1)

        // Execute overlay into buffer
        for overlay in overlayStore.overlays {
            overlay.render(&buffer, region)
        }

        // Row 1 should have dropdown content (first option "Red" highlighted)
        // "▸ Red" starts at col 0, row 1
        #expect(buffer[1, 0].char == "▸")
        #expect(buffer[1, 2].char == "R")
        #expect(buffer[1, 3].char == "e")
        #expect(buffer[1, 4].char == "d")
    }

    @Test("Dropdown flips above when near bottom edge")
    func dropdownFlipsAbove() {
        let store = FocusStore()
        let overlayStore = OverlayStore()
        var ctx = RenderContext()
        ctx.focusStore = store
        ctx.overlayStore = overlayStore

        let picker = Picker("Color", selection: 0, options: options) { _ in }

        // Place picker at bottom of a small buffer (row 4 of 6 rows)
        // Only 1 row below, 4 rows above — should flip above
        var buffer = Buffer(width: 30, height: 6)
        let pickerRegion = Region(row: 4, col: 0, width: 30, height: 1)
        let fullRegion = Region(row: 0, col: 0, width: 30, height: 6)

        render(picker, into: &buffer, region: pickerRegion, context: ctx)
        store.applyDefaultFocus()
        store.beginFrame()
        overlayStore.beginFrame()
        render(picker, into: &buffer, region: pickerRegion, context: ctx)

        // Open dropdown
        _ = store.routeKeyEvent(.character(" "))
        store.beginFrame()
        overlayStore.beginFrame()
        render(picker, into: &buffer, region: pickerRegion, context: ctx)

        #expect(overlayStore.overlays.count == 1)

        // Execute overlay with full region
        for overlay in overlayStore.overlays {
            overlay.render(&buffer, fullRegion)
        }

        // With 3 options and picker at row 4, only 1 row below (row 5).
        // 4 rows above (rows 0-3). Should flip above: rows 1, 2, 3.
        #expect(buffer[1, 2].char == "R") // Red
        #expect(buffer[2, 2].char == "G") // Green
        #expect(buffer[3, 2].char == "B") // Blue
    }

    @Test("Enter cycles to next option in normal mode")
    func enterCycles() {
        let store = FocusStore()
        var ctx = RenderContext()
        ctx.focusStore = store

        let received = Box(0)
        let picker = Picker("Color", selection: 0, options: options) { newIndex in
            received.value = newIndex
        }

        var buffer = Buffer(width: 30, height: 1)
        let region = Region(row: 0, col: 0, width: 30, height: 1)

        render(picker, into: &buffer, region: region, context: ctx)
        store.applyDefaultFocus()
        store.beginFrame()
        render(picker, into: &buffer, region: region, context: ctx)

        // Enter opens dropdown (sets highlighted to current selection 0)
        let result = store.routeKeyEvent(.enter)
        #expect(result == .handled)
    }
}
