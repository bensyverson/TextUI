import Testing
@testable import TextUI

@Suite("Table")
struct TableTests {
    // MARK: - Column Width Calculation

    @Test("Fixed column widths are exact")
    func fixedColumnWidths() {
        let table = Table(rows: []) {
            Table.Column.fixed("ID", width: 4)
            Table.Column.fixed("Name", width: 10)
        }
        let widths = table.computeColumnWidths(availableWidth: 20)
        // 20 - 1 separator = 19 content; fixed: 4 + 10 = 14
        #expect(widths == [4, 10])
    }

    @Test("Flex columns share remaining space equally")
    func flexColumnWidths() {
        let table = Table(rows: []) {
            Table.Column.flex("A")
            Table.Column.flex("B")
        }
        let widths = table.computeColumnWidths(availableWidth: 21)
        // 21 - 1 separator = 20; 20 / 2 = 10 each
        #expect(widths == [10, 10])
    }

    @Test("Mixed fixed and flex columns")
    func mixedColumnWidths() {
        let table = Table(rows: []) {
            Table.Column.fixed("ID", width: 4)
            Table.Column.flex("Name")
            Table.Column.flex("Email")
        }
        let widths = table.computeColumnWidths(availableWidth: 30)
        // 30 - 2 separators = 28; fixed: 4; remaining: 24; 24/2 = 12 each
        #expect(widths == [4, 12, 12])
    }

    @Test("Flex columns distribute remainder to first columns")
    func flexRemainderDistribution() {
        let table = Table(rows: []) {
            Table.Column.flex("A")
            Table.Column.flex("B")
            Table.Column.flex("C")
        }
        let widths = table.computeColumnWidths(availableWidth: 22)
        // 22 - 2 separators = 20; 20/3 = 6 r 2; first 2 get 7, last gets 6
        #expect(widths == [7, 7, 6])
    }

    // MARK: - Sizing

    @Test("Table is greedy on both axes")
    func sizingGreedy() {
        let table = Table(rows: [[Text("A")]]) {
            Table.Column.flex("Col")
        }
        let size = sizeThatFits(table, proposal: SizeProposal(width: 40, height: 20))
        #expect(size.width == 40)
        #expect(size.height == 20)
    }

    // MARK: - Header Rendering

    @Test("Header row renders bold column titles")
    func headerRendering() {
        let table = Table(rows: [], showsIndicator: false) {
            Table.Column.fixed("ID", width: 4)
            Table.Column.fixed("Name", width: 6)
        }
        var buffer = Buffer(width: 20, height: 3)
        let region = Region(row: 0, col: 0, width: 20, height: 3)
        render(table, into: &buffer, region: region)

        // "ID" in bold at col 0
        #expect(buffer[0, 0].char == "I")
        #expect(buffer[0, 1].char == "D")
        #expect(buffer[0, 0].style.bold)

        // Separator at col 4
        #expect(buffer[0, 4].char == "│")

        // "Name" at col 5
        #expect(buffer[0, 5].char == "N")
        #expect(buffer[0, 8].char == "e")
    }

    @Test("Divider row renders with correct characters")
    func dividerRendering() {
        let table = Table(rows: [], showsIndicator: false) {
            Table.Column.fixed("A", width: 3)
            Table.Column.fixed("B", width: 3)
        }
        var buffer = Buffer(width: 10, height: 3)
        let region = Region(row: 0, col: 0, width: 10, height: 3)
        render(table, into: &buffer, region: region)

        // Divider on row 1
        #expect(buffer[1, 0].char == "─")
        #expect(buffer[1, 1].char == "─")
        #expect(buffer[1, 2].char == "─")
        #expect(buffer[1, 3].char == "┼") // intersection
        #expect(buffer[1, 4].char == "─")
    }

    // MARK: - Row Rendering

    @Test("Data rows render with coordinated column widths")
    func dataRowRendering() {
        let table = Table(
            rows: [
                [Text("1"), Text("Alice")],
                [Text("2"), Text("Bob")],
            ],
            showsIndicator: false,
        ) {
            Table.Column.fixed("ID", width: 3)
            Table.Column.fixed("Name", width: 6)
        }
        var buffer = Buffer(width: 15, height: 5)
        let region = Region(row: 0, col: 0, width: 15, height: 5)
        render(table, into: &buffer, region: region)

        // Row 2 (first data row): "1" at col 0, "│" at col 3, "Alice" at col 4
        #expect(buffer[2, 0].char == "1")
        #expect(buffer[2, 3].char == "│")
        #expect(buffer[2, 4].char == "A")

        // Row 3 (second data row): "2" at col 0, "Bob" at col 4
        #expect(buffer[3, 0].char == "2")
        #expect(buffer[3, 4].char == "B")
    }

    // MARK: - Scrolling

    @Test("Table scrolls body rows with keyboard")
    func tableScrolling() {
        let store = FocusStore()
        var ctx = RenderContext()
        ctx.focusStore = store

        let table = Table(
            rows: (0 ..< 10).map { [Text("Row\($0)")] },
            showsIndicator: false,
        ) {
            Table.Column.flex("Data")
        }

        // Viewport: height 5 = 2 header + 3 body rows
        var buffer = Buffer(width: 20, height: 5)
        let region = Region(row: 0, col: 0, width: 20, height: 5)

        render(table, into: &buffer, region: region, context: ctx)
        store.applyDefaultFocus()
        store.beginFrame()
        render(table, into: &buffer, region: region, context: ctx)

        // Scroll down
        _ = store.routeKeyEvent(.down)

        store.beginFrame()
        buffer = Buffer(width: 20, height: 5)
        render(table, into: &buffer, region: region, context: ctx)

        // First body row should now be Row1 (at buffer row 2)
        #expect(buffer[2, 3].char == "1")
    }

    // MARK: - Edge Cases

    @Test("Empty table renders header and divider only")
    func emptyTable() {
        let table = Table(rows: [], showsIndicator: false) {
            Table.Column.fixed("Col", width: 5)
        }
        var buffer = Buffer(width: 10, height: 5)
        let region = Region(row: 0, col: 0, width: 10, height: 5)
        render(table, into: &buffer, region: region)

        // Header present
        #expect(buffer[0, 0].char == "C")
        // Divider present
        #expect(buffer[1, 0].char == "─")
        // No data rows
        #expect(buffer[2, 0].char == " ")
    }

    @Test("Single column table has no separators")
    func singleColumn() {
        let table = Table(
            rows: [[Text("Hello")]],
            showsIndicator: false,
        ) {
            Table.Column.flex("Data")
        }
        var buffer = Buffer(width: 10, height: 5)
        let region = Region(row: 0, col: 0, width: 10, height: 5)
        render(table, into: &buffer, region: region)

        // Header: "Data"
        #expect(buffer[0, 0].char == "D")
        // No separator character anywhere on row 0
        let row0chars = (0 ..< 10).map { buffer[0, $0].char }
        #expect(!row0chars.contains("│"))

        // Data row: "Hello"
        #expect(buffer[2, 0].char == "H")
    }

    // MARK: - Focus

    @Test("Table registers in focus ring")
    func focusRegistration() {
        let store = FocusStore()
        var ctx = RenderContext()
        ctx.focusStore = store

        let table = Table(rows: [[Text("A")]]) {
            Table.Column.flex("Col")
        }
        var buffer = Buffer(width: 20, height: 5)
        let region = Region(row: 0, col: 0, width: 20, height: 5)
        render(table, into: &buffer, region: region, context: ctx)

        #expect(store.ring.count >= 1)
        #expect(store.ring[0].interaction == .activate)
    }

    // MARK: - Scroll Indicator

    @Test("Scroll indicator shown when rows overflow body")
    func scrollIndicatorPresent() {
        let table = Table(
            rows: (0 ..< 10).map { [Text("Row\($0)")] },
            showsIndicator: true,
        ) {
            Table.Column.flex("Data")
        }
        var buffer = Buffer(width: 20, height: 5)
        let region = Region(row: 0, col: 0, width: 20, height: 5)
        render(table, into: &buffer, region: region)

        // Indicator on right edge of body area (row 2+)
        let col19chars = (2 ..< 5).map { buffer[$0, 19].char }
        let hasIndicator = col19chars.contains("█") || col19chars.contains("│")
        #expect(hasIndicator)
    }
}
