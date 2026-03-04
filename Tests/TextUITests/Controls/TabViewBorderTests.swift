import Testing
@testable import TextUI

@MainActor
@Suite("TabView Borders")
struct TabViewBorderTests {
    // MARK: - Helper

    private func renderTabView(
        singleTab: Bool = false,
        alignment: HorizontalAlignment = .leading,
        controlSize: ControlSize? = nil,
        dividerStyle: TabDividerStyle? = nil,
        tabBorderStyle: BorderedView.BorderStyle? = nil,
        width: Int = 40,
        height: Int = 10,
    ) -> Buffer {
        let tabView = if singleTab {
            TabView(alignment: alignment) {
                TabView.Tab("A") { Text("A") }
            }
        } else {
            TabView(alignment: alignment) {
                TabView.Tab("Tab1") { Text("Tab1") }
                TabView.Tab("Tab2") { Text("Tab2") }
            }
        }

        var ctx = RenderContext()
        if let controlSize {
            ctx.controlSize = controlSize
        }
        if let dividerStyle {
            ctx.tabDividerStyle = dividerStyle
        }
        if let tabBorderStyle {
            ctx.tabBorderStyle = tabBorderStyle
        }

        var buffer = Buffer(width: width, height: height)
        let region = Region(row: 0, col: 0, width: width, height: height)
        render(tabView, into: &buffer, region: region, context: ctx)
        return buffer
    }

    private func rowString(_ buffer: Buffer, row: Int) -> String {
        var result = ""
        for col in 0 ..< buffer.width {
            let cell = buffer[row, col]
            if cell.isContinuation { continue }
            result.append(cell.char)
        }
        while result.hasSuffix(" ") {
            result.removeLast()
        }
        return result
    }

    // MARK: - Border ignored with .none divider

    @Test("Tab border style is ignored when divider is .none")
    func borderIgnoredWithNoneDivider() {
        let withBorder = renderTabView(
            controlSize: .regular,
            dividerStyle: TabDividerStyle.none,
            tabBorderStyle: .rounded,
        )
        let withoutBorder = renderTabView(
            controlSize: .regular,
            dividerStyle: TabDividerStyle.none,
        )

        // Both should produce the same chrome
        let row0With = rowString(withBorder, row: 0)
        let row0Without = rowString(withoutBorder, row: 0)
        #expect(row0With == row0Without)
    }

    // MARK: - Small + Border

    @Test("Small size with .bottom divider and border draws border top row")
    func smallBottomBorder() {
        let buffer = renderTabView(
            alignment: .center,
            controlSize: .small,
            dividerStyle: .bottom,
            tabBorderStyle: .rounded,
        )

        // Row 0: border top with tabs embedded
        // "╭─────── Tab1 │ Tab2 ────────╮"
        #expect(buffer[0, 0].char == "╭")
        #expect(buffer[0, 39].char == "╮")
        let row0 = rowString(buffer, row: 0)
        #expect(row0.contains("Tab1"))
        #expect(row0.contains("─"))

        // Content inside border (col 1 to width-2)
        // Row 1 should have │ at edges
        #expect(buffer[1, 0].char == "│")
        #expect(buffer[1, 39].char == "│")

        // Bottom border
        let lastRow = 9
        #expect(buffer[lastRow, 0].char == "╰")
        #expect(buffer[lastRow, 39].char == "╯")
    }

    // MARK: - Regular + Border

    @Test("Regular size with .bottom divider and border draws merged border")
    func regularBottomBorder() {
        let buffer = renderTabView(
            alignment: .center,
            controlSize: .regular,
            dividerStyle: .bottom,
            tabBorderStyle: .rounded,
        )

        // Row 0: tab label row (offset for center)
        let row0 = rowString(buffer, row: 0)
        #expect(row0.contains("╭"))
        #expect(row0.contains("Tab1"))

        // Row 1: content border top merged with tab bottom
        // "╭────────┴───────────────────┴────────────╮"
        #expect(buffer[1, 0].char == "╭")
        #expect(buffer[1, 39].char == "╮")
        let row1 = rowString(buffer, row: 1)
        #expect(row1.contains("┴"))

        // Content inside border
        #expect(buffer[2, 0].char == "│")
        #expect(buffer[2, 39].char == "│")

        // Bottom border
        let lastRow = 9
        #expect(buffer[lastRow, 0].char == "╰")
        #expect(buffer[lastRow, 39].char == "╯")
    }

    // MARK: - Large + Border

    @Test("Large size with .bottom divider and border draws merged border")
    func largeBottomBorder() {
        let buffer = renderTabView(
            alignment: .center,
            controlSize: .large,
            dividerStyle: .bottom,
            tabBorderStyle: .rounded,
        )

        // Row 0: top of tab boxes (offset for center)
        let row0 = rowString(buffer, row: 0)
        #expect(row0.contains("╭"))
        #expect(row0.contains("┬"))

        // Row 1: labels
        let row1 = rowString(buffer, row: 1)
        #expect(row1.contains("Tab1"))

        // Row 2: content border top merged with tab bottom
        #expect(buffer[2, 0].char == "╭")
        #expect(buffer[2, 39].char == "╮")
        let row2 = rowString(buffer, row: 2)
        #expect(row2.contains("┴"))

        // Content inside border
        #expect(buffer[3, 0].char == "│")
        #expect(buffer[3, 39].char == "│")

        // Bottom border
        let lastRow = 9
        #expect(buffer[lastRow, 0].char == "╰")
        #expect(buffer[lastRow, 39].char == "╯")
    }

    @Test("Large size with .middle divider and border draws ┤/├ joins")
    func largeMiddleBorder() {
        let buffer = renderTabView(
            alignment: .center,
            controlSize: .large,
            dividerStyle: .middle,
            tabBorderStyle: .rounded,
        )

        // Row 2: border top with ┤ and ├ at tab edges
        #expect(buffer[2, 0].char == "╭")
        #expect(buffer[2, 39].char == "╮")
        let row2 = rowString(buffer, row: 2)
        #expect(row2.contains("┤"))
        #expect(row2.contains("├"))

        // Content inside border — tab boxes continue as internal decoration
        // Row 3 has │ at edges for border
        #expect(buffer[3, 0].char == "│")
        #expect(buffer[3, 39].char == "│")
    }

    // MARK: - Square Border

    @Test("Square tab border style uses square corners for content border")
    func squareBorderStyle() {
        let buffer = renderTabView(
            controlSize: .regular,
            dividerStyle: .bottom,
            tabBorderStyle: .square,
        )

        // Row 1: content border top with square corners
        // Tab boxes also use square corners
        #expect(buffer[0, 0].char == "┌") // tab box uses square
        let row1 = rowString(buffer, row: 1)
        // ┴ joins should still be present
        #expect(row1.contains("┴"))
    }

    // MARK: - Content Region

    @Test("Content with border is inset by 1 on each side")
    func contentInsetWithBorder() {
        let buffer = renderTabView(
            singleTab: true,
            controlSize: .small,
            dividerStyle: .bottom,
            tabBorderStyle: .rounded,
            width: 20,
            height: 5,
        )

        // Content text "A" should be at col 1 (inset by border), not col 0
        // Row 1 is the content row (after 1-line small chrome)
        #expect(buffer[1, 0].char == "│") // left border
        #expect(buffer[1, 1].char == "A") // content
        #expect(buffer[1, 19].char == "│") // right border
    }

    @Test("Content without border starts at col 0")
    func contentNotInsetWithoutBorder() {
        let buffer = renderTabView(
            singleTab: true,
            controlSize: .small,
            dividerStyle: .bottom,
            width: 20,
            height: 5,
        )

        // Content on row 1, col 0
        #expect(buffer[1, 0].char == "A")
    }
}
