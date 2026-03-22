import Testing
@testable import TextUI

/// Mutable value for use in test closures.
private final class Box<T: Sendable> {
    var value: T
    init(_ value: T) {
        self.value = value
    }
}

@MainActor
@Suite("Picker Click")
struct PickerClickTests {
    let options = ["Red", "Green", "Blue"]

    // MARK: - Main Control Click

    @Test("Clicking the main Picker control toggles dropdown open")
    func clickOpensDropdown() throws {
        let store = FocusStore()
        var ctx = RenderContext()
        ctx.focusStore = store

        let picker = Picker("Color", selection: 0, options: options, fileID: "test", line: 1) { _ in }

        var buffer = Buffer(width: 30, height: 10)
        let region = Region(row: 0, col: 0, width: 30, height: 1)

        render(picker, into: &buffer, region: region, context: ctx)
        store.applyDefaultFocus()
        store.beginFrame()
        render(picker, into: &buffer, region: region, context: ctx)

        let entry = try #require(store.entry(at: 0, column: 0))
        let tap = store.tapHandler(for: entry.id)
        #expect(tap != nil)

        // Click to open
        tap?(0, 0)

        let state = store.controlState(forKey: AnyHashable("test:1"), as: Picker.PickerState.self)
        #expect(state?.isDropdownOpen == true)
    }

    @Test("Clicking main control when dropdown is open closes it")
    func clickClosesDropdown() throws {
        let store = FocusStore()
        var ctx = RenderContext()
        ctx.focusStore = store

        let picker = Picker("Color", selection: 0, options: options, fileID: "test", line: 1) { _ in }

        var buffer = Buffer(width: 30, height: 10)
        let region = Region(row: 0, col: 0, width: 30, height: 1)

        render(picker, into: &buffer, region: region, context: ctx)
        store.applyDefaultFocus()

        // Open dropdown first
        var state = Picker.PickerState()
        state.isDropdownOpen = true
        state.highlightedIndex = 0
        store.setControlState(state, forKey: AnyHashable("test:1"))

        store.beginFrame()
        render(picker, into: &buffer, region: region, context: ctx)

        // Click on the main control (row 0) should close
        let entry = try #require(store.entry(at: 0, column: 0))
        let tap = store.tapHandler(for: entry.id)
        tap?(0, 0)

        let updated = store.controlState(forKey: AnyHashable("test:1"), as: Picker.PickerState.self)
        #expect(updated?.isDropdownOpen == false)
    }

    // MARK: - Dropdown Option Click

    @Test("Clicking a dropdown option selects it and closes dropdown")
    func clickOptionSelects() throws {
        let store = FocusStore()
        var ctx = RenderContext()
        ctx.focusStore = store
        ctx.overlayStore = OverlayStore()

        let received = Box(-1)
        let picker = Picker("Color", selection: 0, options: options, fileID: "test", line: 1) {
            received.value = $0
        }

        var buffer = Buffer(width: 30, height: 10)
        let region = Region(row: 0, col: 0, width: 30, height: 1)

        render(picker, into: &buffer, region: region, context: ctx)
        store.applyDefaultFocus()

        // Open dropdown
        var state = Picker.PickerState()
        state.isDropdownOpen = true
        state.highlightedIndex = 0
        store.setControlState(state, forKey: AnyHashable("test:1"))

        store.beginFrame()
        render(picker, into: &buffer, region: region, context: ctx)

        // Dropdown renders below at row 1 (picker at row 0).
        // Border box: row 1 = top border, row 2 = first option, row 3 = second, row 4 = third
        // Look for a focus entry at the dropdown area (row 2 = first option "Red")
        let dropdownEntry = store.entry(at: 2, column: 2)
        #expect(dropdownEntry != nil)

        let tap = try store.tapHandler(for: #require(dropdownEntry?.id))
        #expect(tap != nil)

        // Click on third option "Blue" at row 4, col 2
        tap?(4, 2)

        #expect(received.value == 2) // Blue is index 2
        let updated = store.controlState(forKey: AnyHashable("test:1"), as: Picker.PickerState.self)
        #expect(updated?.isDropdownOpen == false)
    }

    @Test("Clicking outside dropdown options closes dropdown")
    func clickOutsideOptionsCloses() throws {
        let store = FocusStore()
        var ctx = RenderContext()
        ctx.focusStore = store
        ctx.overlayStore = OverlayStore()

        let received = Box(-1)
        let picker = Picker("Color", selection: 0, options: options, fileID: "test", line: 1) {
            received.value = $0
        }

        var buffer = Buffer(width: 30, height: 10)
        let region = Region(row: 0, col: 0, width: 30, height: 1)

        render(picker, into: &buffer, region: region, context: ctx)
        store.applyDefaultFocus()

        // Open dropdown
        var state = Picker.PickerState()
        state.isDropdownOpen = true
        state.highlightedIndex = 0
        store.setControlState(state, forKey: AnyHashable("test:1"))

        store.beginFrame()
        render(picker, into: &buffer, region: region, context: ctx)

        // Click on the border row (row 1 = top border) — should close but not select
        let dropdownEntry = store.entry(at: 2, column: 2)
        #expect(dropdownEntry != nil)
        let tap = try store.tapHandler(for: #require(dropdownEntry?.id))

        // Click on the top border row (row 1)
        tap?(1, 2)

        // Should not have called onChange
        #expect(received.value == -1)
        // Should have closed the dropdown
        let updated = store.controlState(forKey: AnyHashable("test:1"), as: Picker.PickerState.self)
        #expect(updated?.isDropdownOpen == false)
    }
}
