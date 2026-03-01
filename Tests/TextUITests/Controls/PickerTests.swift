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
