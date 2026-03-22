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
@Suite("Table Click")
struct TableClickTests {
    let testRows: [[any View]] = [
        [Text("Alice"), Text("alice@ex.com")],
        [Text("Bob"), Text("bob@ex.com")],
        [Text("Carol"), Text("carol@ex.com")],
        [Text("Dave"), Text("dave@ex.com")],
    ]

    private func makeTable(
        rows: [[any View]]? = nil,
        selection: Int? = nil,
    ) -> Table {
        let data = rows ?? testRows
        if let selection {
            return Table(rows: data, selection: selection, fileID: "test", line: 1) {
                Table.Column.flex("Name")
                Table.Column.flex("Email")
            }
        } else {
            return Table(rows: data, fileID: "test", line: 1) {
                Table.Column.flex("Name")
                Table.Column.flex("Email")
            }
        }
    }

    // MARK: - Click to Select

    @Test("Clicking a data row sets selectedRow")
    func clickDataRow() throws {
        let store = FocusStore()
        var ctx = RenderContext()
        ctx.focusStore = store

        let table = makeTable()
        var buffer = Buffer(width: 30, height: 10)
        let region = Region(row: 0, col: 0, width: 30, height: 10)

        render(table, into: &buffer, region: region, context: ctx)
        store.applyDefaultFocus()
        store.beginFrame()
        render(table, into: &buffer, region: region, context: ctx)

        // Row layout: row 0 = header, row 1 = divider, row 2 = Alice, row 3 = Bob, etc.
        let entry = try #require(store.entry(at: 2, column: 0))
        let tap = store.tapHandler(for: entry.id)
        #expect(tap != nil)

        // Click on row 3 (Bob, data index 1)
        tap?(3, 5)

        let state = store.controlState(forKey: "test:1", as: Table.ScrollState.self)
        #expect(state?.selectedRow == 1)
    }

    @Test("Clicking header row does not select")
    func clickHeaderIgnored() throws {
        let store = FocusStore()
        var ctx = RenderContext()
        ctx.focusStore = store

        let table = makeTable()
        var buffer = Buffer(width: 30, height: 10)
        let region = Region(row: 0, col: 0, width: 30, height: 10)

        render(table, into: &buffer, region: region, context: ctx)
        store.applyDefaultFocus()
        store.beginFrame()
        render(table, into: &buffer, region: region, context: ctx)

        let entry = try #require(store.entry(at: 0, column: 0))
        let tap = store.tapHandler(for: entry.id)

        // Click on header row (row 0)
        tap?(0, 5)

        let state = store.controlState(forKey: "test:1", as: Table.ScrollState.self)
        #expect(state?.selectedRow == nil)
    }

    @Test("Click with scroll offset correctly maps to data index")
    func clickWithScrollOffset() throws {
        let store = FocusStore()
        var ctx = RenderContext()
        ctx.focusStore = store

        // 4 rows, body height = 2 (height 4 - header - divider)
        let table = makeTable()
        var buffer = Buffer(width: 30, height: 4)
        let region = Region(row: 0, col: 0, width: 30, height: 4)

        render(table, into: &buffer, region: region, context: ctx)
        store.applyDefaultFocus()

        // Set scroll offset to 2 (Carol, Dave visible)
        var scrollState = Table.ScrollState()
        scrollState.offset = 2
        store.setControlState(scrollState, forKey: "test:1")

        store.beginFrame()
        render(table, into: &buffer, region: region, context: ctx)

        let entry = try #require(store.entry(at: 2, column: 0))
        let tap = store.tapHandler(for: entry.id)

        // Click on first visible data row (row 2 = Carol, data index 2)
        tap?(2, 5)

        let state = store.controlState(forKey: "test:1", as: Table.ScrollState.self)
        #expect(state?.selectedRow == 2)
    }

    // MARK: - Selection Highlight

    @Test("Selected row renders with inverse style")
    func selectedRowHighlight() {
        let store = FocusStore()
        var ctx = RenderContext()
        ctx.focusStore = store

        let table = makeTable(selection: 1)
        var buffer = Buffer(width: 30, height: 10)
        let region = Region(row: 0, col: 0, width: 30, height: 10)

        render(table, into: &buffer, region: region, context: ctx)
        store.applyDefaultFocus()
        store.beginFrame()
        render(table, into: &buffer, region: region, context: ctx)

        // Bob is at data index 1, rendered at screen row 3
        #expect(buffer[3, 0].style.inverse)
        // Alice (row 2) should not be inverse
        #expect(!buffer[2, 0].style.inverse)
    }

    // MARK: - Selection Change Handler

    @Test("onSelectionChange fires with correct index on click")
    func selectionChangeHandler() throws {
        let store = FocusStore()
        var ctx = RenderContext()
        ctx.focusStore = store

        let received = Box(-1)
        let handler: (Int) -> Void = { received.value = $0 }
        store.pushTableSelectionHandler(handler)

        let table = makeTable(selection: 0)
        var buffer = Buffer(width: 30, height: 10)
        let region = Region(row: 0, col: 0, width: 30, height: 10)

        render(table, into: &buffer, region: region, context: ctx)
        store.applyDefaultFocus()
        store.beginFrame()
        store.pushTableSelectionHandler(handler)
        render(table, into: &buffer, region: region, context: ctx)

        let entry = try #require(store.entry(at: 2, column: 0))
        let tap = store.tapHandler(for: entry.id)

        // Click Bob (row 3, data index 1)
        tap?(3, 5)

        #expect(received.value == 1)
    }

    // MARK: - Keyboard Selection

    @Test("Down arrow moves selection")
    func keyboardDownMovesSelection() {
        let store = FocusStore()
        var ctx = RenderContext()
        ctx.focusStore = store

        let table = makeTable()
        var buffer = Buffer(width: 30, height: 10)
        let region = Region(row: 0, col: 0, width: 30, height: 10)

        render(table, into: &buffer, region: region, context: ctx)
        store.applyDefaultFocus()
        store.beginFrame()
        render(table, into: &buffer, region: region, context: ctx)

        // Press Down to select first row
        let result = store.routeKeyEvent(.down)
        #expect(result == .handled)

        let state = store.controlState(forKey: "test:1", as: Table.ScrollState.self)
        #expect(state?.selectedRow == 0)
    }

    @Test("Up arrow moves selection up")
    func keyboardUpMovesSelection() {
        let store = FocusStore()
        var ctx = RenderContext()
        ctx.focusStore = store

        let table = makeTable()
        var buffer = Buffer(width: 30, height: 10)
        let region = Region(row: 0, col: 0, width: 30, height: 10)

        render(table, into: &buffer, region: region, context: ctx)
        store.applyDefaultFocus()

        // Set selection to row 2
        var scrollState = Table.ScrollState()
        scrollState.selectedRow = 2
        store.setControlState(scrollState, forKey: "test:1")

        store.beginFrame()
        render(table, into: &buffer, region: region, context: ctx)

        let result = store.routeKeyEvent(.up)
        #expect(result == .handled)

        let state = store.controlState(forKey: "test:1", as: Table.ScrollState.self)
        #expect(state?.selectedRow == 1)
    }
}
