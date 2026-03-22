import Testing
@testable import TextUI

@MainActor
@Suite("TabView Click")
struct TabViewClickTests {
    // MARK: - Helpers

    /// Creates a focused TabView with two tabs and returns (store, focusEntryID).
    private func setupFocusedTabView(
        selection: Int? = nil,
        controlSize: ControlSize = .regular,
        width: Int = 40,
        height: Int = 10,
    ) -> (FocusStore, Int) {
        let store = FocusStore()
        var ctx = RenderContext()
        ctx.focusStore = store
        ctx.controlSize = controlSize

        let view = if let selection {
            TabView(selection: selection, fileID: "test", line: 1) {
                TabView.Tab("Home") { Text("A") }
                TabView.Tab("Settings") { Text("B") }
            }
        } else {
            TabView(fileID: "test", line: 1) {
                TabView.Tab("Home") { Text("A") }
                TabView.Tab("Settings") { Text("B") }
            }
        }

        var buffer = Buffer(width: width, height: height)
        let region = Region(row: 0, col: 0, width: width, height: height)

        // First render + focus + re-render to register handlers
        render(view, into: &buffer, region: region, context: ctx)
        store.applyDefaultFocus()
        store.beginFrame()
        render(view, into: &buffer, region: region, context: ctx)

        let entry = store.entry(at: 0, column: 0)!
        return (store, entry.id)
    }

    // MARK: - Basic Click

    @Test("Clicking first tab selects tab 0")
    func clickFirstTab() {
        let (store, entryID) = setupFocusedTabView()
        // Regular layout: "╭─ Home │ Settings ─╮"
        // " Home " starts at col 2 (after ╭─), label "H" at col 3
        let tap = store.tapHandler(for: entryID)
        #expect(tap != nil)

        // Click on "H" of "Home" at col 3
        tap?(0, 3)

        let state = store.controlState(forKey: "test:1", as: TabView.TabState.self)
        #expect(state?.selectedIndex == 0)
    }

    @Test("Clicking second tab selects tab 1")
    func clickSecondTab() {
        let (store, entryID) = setupFocusedTabView()
        // Regular layout: "╭─ Home │ Settings ─╮"
        // " Home " = cols 2..7, "│" = col 8, " Settings " = cols 9..19
        let tap = store.tapHandler(for: entryID)
        #expect(tap != nil)

        // Click on "S" of "Settings" at col 10
        tap?(0, 10)

        let state = store.controlState(forKey: "test:1", as: TabView.TabState.self)
        #expect(state?.selectedIndex == 1)
    }

    @Test("Clicking separator does not change selection")
    func clickSeparator() {
        let (store, entryID) = setupFocusedTabView()
        // Set initial selection to 0
        var state = TabView.TabState()
        state.selectedIndex = 0
        state.tabCount = 2
        store.setControlState(state, forKey: "test:1")

        let tap = store.tapHandler(for: entryID)

        // Click on the │ separator at col 8
        tap?(0, 8)

        let updated = store.controlState(forKey: "test:1", as: TabView.TabState.self)
        #expect(updated?.selectedIndex == 0) // unchanged
    }

    // MARK: - Parent-Driven Selection

    @Test("Parent-driven mode fires selectionHandler but does not mutate state")
    func parentDrivenClick() throws {
        let store = FocusStore()
        var ctx = RenderContext()
        ctx.focusStore = store

        let receivedIndex = Box(0)
        let handler: (Int) -> Void = { receivedIndex.value = $0 }
        store.pushTabSelectionHandler(handler)

        let view = TabView(selection: 0, fileID: "test", line: 1) {
            TabView.Tab("Home") { Text("A") }
            TabView.Tab("Settings") { Text("B") }
        }

        var buffer = Buffer(width: 40, height: 10)
        let region = Region(row: 0, col: 0, width: 40, height: 10)

        render(view, into: &buffer, region: region, context: ctx)
        store.applyDefaultFocus()
        store.beginFrame()
        store.pushTabSelectionHandler(handler)
        render(view, into: &buffer, region: region, context: ctx)

        let entry = try #require(store.entry(at: 0, column: 0))
        let tap = store.tapHandler(for: entry.id)

        // Click on Settings tab (col 10)
        tap?(0, 10)

        // Handler should have been called with index 1
        #expect(receivedIndex.value == 1)
        // But internal state should still be 0 (parent-driven)
        let state = store.controlState(forKey: "test:1", as: TabView.TabState.self)
        #expect(state?.selectedIndex == 0)
    }

    // MARK: - Control Sizes

    @Test("Small control size tab click works")
    func smallSizeClick() {
        let (store, entryID) = setupFocusedTabView(controlSize: .small)
        // Small .bottom (default) no-border: "│ Home │ Settings ─────..."
        // Leading │ at col 0, " Home " = cols 1..6, │ at col 7, " Settings " = cols 8..18
        let tap = store.tapHandler(for: entryID)
        #expect(tap != nil)

        // Click on "S" of "Settings" at col 9
        tap?(0, 9)

        let state = store.controlState(forKey: "test:1", as: TabView.TabState.self)
        #expect(state?.selectedIndex == 1)
    }

    @Test("Large control size tab click works")
    func largeSizeClick() {
        let (store, entryID) = setupFocusedTabView(controlSize: .large)
        // Large: Row 0 = "╭──────┬──────────╮"
        //        Row 1 = "│ Home │ Settings │"
        // Tab bar region covers rows 0-2. Labels are on row 1.
        // Leading │ at col 0, " Home " = cols 1..6, │ at col 7, " Settings " = cols 8..18
        let tap = store.tapHandler(for: entryID)
        #expect(tap != nil)

        // Click on row 1, "S" of "Settings" at col 9
        tap?(1, 9)

        let state = store.controlState(forKey: "test:1", as: TabView.TabState.self)
        #expect(state?.selectedIndex == 1)
    }
}

/// Mutable box for test closures.
private final class Box<T: Sendable> {
    var value: T
    init(_ value: T) {
        self.value = value
    }
}
