import Testing
@testable import TextUI

@MainActor
@Suite("TabView Styles")
struct TabViewStyleTests {
    // MARK: - Helper

    /// Renders a TabView with the given modifiers and returns the buffer.
    private func renderTabView(
        alignment: HorizontalAlignment = .leading,
        controlSize: ControlSize? = nil,
        dividerStyle: TabDividerStyle? = nil,
        tabBorderStyle: BorderedView.BorderStyle? = nil,
        width: Int = 40,
        height: Int = 10,
    ) -> Buffer {
        let tabView = TabView(alignment: alignment) {
            TabView.Tab("Tab1") { Text("Tab1") }
            TabView.Tab("Tab2") { Text("Tab2") }
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

    /// Extracts a row from the buffer as a string.
    private func rowString(_ buffer: Buffer, row: Int) -> String {
        var result = ""
        for col in 0 ..< buffer.width {
            let cell = buffer[row, col]
            if cell.isContinuation { continue }
            result.append(cell.char)
        }
        // Trim trailing spaces
        while result.hasSuffix(" ") {
            result.removeLast()
        }
        return result
    }

    // MARK: - Small Size

    @Test("Small size with .none divider renders 1-line tabs")
    func smallNoneDivider() {
        let buffer = renderTabView(
            controlSize: .small,
            dividerStyle: TabDividerStyle.none,
        )

        // Row 0: " Tab1 │ Tab2 "
        let row0 = rowString(buffer, row: 0)
        #expect(row0.contains("Tab1"))
        #expect(row0.contains("│"))
        #expect(row0.contains("Tab2"))

        // Content starts on row 1
        #expect(buffer[1, 0].char == "T") // "Tab1" content
    }

    @Test("Small size with .bottom divider renders tabs on horizontal line")
    func smallBottomDivider() {
        let buffer = renderTabView(
            controlSize: .small,
            dividerStyle: .bottom,
        )

        // Row 0 should contain tabs and horizontal lines
        let row0 = rowString(buffer, row: 0)
        #expect(row0.contains("Tab1"))
        #expect(row0.contains("─"))

        // Content starts on row 1
        #expect(buffer[1, 0].char == "T")
    }

    @Test("Small size with center alignment centers tabs")
    func smallCenterAlignment() {
        let buffer = renderTabView(
            alignment: .center,
            controlSize: .small,
            dividerStyle: TabDividerStyle.none,
        )

        // Tabs should not start at col 0
        // Tab group width for .small: " Tab1 │ Tab2 " = 15
        // Region width = 40, offset = (40 - 15) / 2 = 12
        let row0 = rowString(buffer, row: 0)
        #expect(row0.hasPrefix("            "))
    }

    @Test("Small .middle degrades to .bottom")
    func smallMiddleDegradesToBottom() {
        let bufferMiddle = renderTabView(
            controlSize: .small,
            dividerStyle: .middle,
        )
        let bufferBottom = renderTabView(
            controlSize: .small,
            dividerStyle: .bottom,
        )

        // Both should produce the same output
        let row0Middle = rowString(bufferMiddle, row: 0)
        let row0Bottom = rowString(bufferBottom, row: 0)
        #expect(row0Middle == row0Bottom)
    }

    // MARK: - Regular Size

    @Test("Regular size with .bottom divider renders 2-line tab bar")
    func regularBottomDivider() {
        let buffer = renderTabView(
            controlSize: .regular,
            dividerStyle: .bottom,
        )

        // Row 0: "╭─ Tab1 │ Tab2 ─╮"
        #expect(buffer[0, 0].char == "╭")
        let row0 = rowString(buffer, row: 0)
        #expect(row0.contains("Tab1"))
        #expect(row0.hasSuffix("╮"))

        // Row 1: divider with ┴ at edges
        #expect(buffer[1, 0].char == "┴")
        #expect(buffer[1, 5].char == "─")

        // Content on row 2
        #expect(buffer[2, 0].char == "T")
    }

    @Test("Regular size with .none divider renders closed tab box")
    func regularNoneDivider() {
        let buffer = renderTabView(
            controlSize: .regular,
            dividerStyle: TabDividerStyle.none,
        )

        // Row 0: "╭─ Tab1 │ Tab2 ─╮"
        #expect(buffer[0, 0].char == "╭")

        // Row 1: "╰────────────────╯" (closed bottom)
        #expect(buffer[1, 0].char == "╰")
        let row1 = rowString(buffer, row: 1)
        #expect(row1.hasSuffix("╯"))

        // Content on row 2 (after 2-row chrome: label + bottom)
        #expect(buffer[2, 0].char == "T")
    }

    @Test("Regular size with center alignment offsets tab group")
    func regularCenterAlignment() {
        let buffer = renderTabView(
            alignment: .center,
            controlSize: .regular,
            dividerStyle: .bottom,
        )

        // Tab group width for .regular: 4 (╭─ ... ─╮) + labels
        // "╭─ Tab1 │ Tab2 ─╮" = 18 chars
        // Offset = (40 - 18) / 2 = 11
        // First char of tab box should be at col 11
        #expect(buffer[0, 11].char == "╭")
    }

    @Test("Regular .middle degrades to .bottom")
    func regularMiddleDegradesToBottom() {
        let bufferMiddle = renderTabView(
            controlSize: .regular,
            dividerStyle: .middle,
        )
        let bufferBottom = renderTabView(
            controlSize: .regular,
            dividerStyle: .bottom,
        )

        let row0Middle = rowString(bufferMiddle, row: 0)
        let row0Bottom = rowString(bufferBottom, row: 0)
        #expect(row0Middle == row0Bottom)

        let row1Middle = rowString(bufferMiddle, row: 1)
        let row1Bottom = rowString(bufferBottom, row: 1)
        #expect(row1Middle == row1Bottom)
    }

    // MARK: - Large Size

    @Test("Large size with .none divider renders 3-line closed tab boxes")
    func largeNoneDivider() {
        let buffer = renderTabView(
            controlSize: .large,
            dividerStyle: TabDividerStyle.none,
        )

        // Row 0: "╭──────┬──────╮"
        #expect(buffer[0, 0].char == "╭")
        let row0 = rowString(buffer, row: 0)
        #expect(row0.contains("┬"))

        // Row 1: "│ Tab1 │ Tab2 │"
        #expect(buffer[1, 0].char == "│")
        let row1 = rowString(buffer, row: 1)
        #expect(row1.contains("Tab1"))

        // Row 2: "╰──────┴──────╯"
        #expect(buffer[2, 0].char == "╰")
        let row2 = rowString(buffer, row: 2)
        #expect(row2.contains("┴"))

        // Content on row 3
        #expect(buffer[3, 0].char == "T")
    }

    @Test("Large size with .bottom divider has horizontal rule on row 2")
    func largeBottomDivider() {
        let buffer = renderTabView(
            controlSize: .large,
            dividerStyle: .bottom,
        )

        // Row 0: top of tab boxes
        #expect(buffer[0, 0].char == "╭")

        // Row 1: labels
        #expect(buffer[1, 0].char == "│")

        // Row 2: divider with ┴ at tab edges
        #expect(buffer[2, 0].char == "┴")
        // Should have ─ in the line
        let row2 = rowString(buffer, row: 2)
        #expect(row2.contains("─"))

        // Content on row 3
        #expect(buffer[3, 0].char == "T")
    }

    @Test("Large size with .middle divider has horizontal rule on row 1")
    func largeMiddleDivider() {
        let buffer = renderTabView(
            controlSize: .large,
            dividerStyle: .middle,
        )

        // Row 1: horizontal rule through labels
        // With leading alignment, left tab edge has no line to the left → │
        #expect(buffer[1, 0].char == "│")

        // Right tab edge has line to the right → ├
        let groupWidth = 15 // "│ Tab1 │ Tab2 │" = 15
        #expect(buffer[1, groupWidth - 1].char == "├")

        // Horizontal line continues after tabs
        #expect(buffer[1, groupWidth].char == "─")

        // Row 2: closed tab box bottom
        #expect(buffer[2, 0].char == "╰")

        // Content on row 3
        #expect(buffer[3, 0].char == "T")
    }

    @Test("Large size with .middle divider + center alignment has ┤ and ├")
    func largeMiddleDividerCenter() {
        let buffer = renderTabView(
            alignment: .center,
            controlSize: .large,
            dividerStyle: .middle,
        )

        // Tab group is centered; horizontal line extends on both sides
        let groupWidth = 15
        let tabStart = (40 - groupWidth) / 2

        // ┤ at left tab edge (horizontal line to the left)
        #expect(buffer[1, tabStart].char == "┤")

        // ├ at right tab edge (horizontal line to the right)
        #expect(buffer[1, tabStart + groupWidth - 1].char == "├")

        // Horizontal line on both sides
        #expect(buffer[1, 0].char == "─")
        #expect(buffer[1, 39].char == "─")
    }

    @Test("Large size with center alignment offsets all three rows")
    func largeCenterAlignment() {
        let buffer = renderTabView(
            alignment: .center,
            controlSize: .large,
            dividerStyle: TabDividerStyle.none,
        )

        // Tab group width for .large: │ Tab1 │ Tab2 │ = 15
        // Offset = (40 - 15) / 2 = 12
        #expect(buffer[0, 12].char == "╭")
        #expect(buffer[1, 12].char == "│")
        #expect(buffer[2, 12].char == "╰")
    }

    // MARK: - Square Border Style

    @Test("Square tab border style uses square corners")
    func squareTabBorderStyle() {
        let buffer = renderTabView(
            controlSize: .large,
            dividerStyle: TabDividerStyle.none,
            tabBorderStyle: .square,
        )

        // Row 0: "┌──────┬──────┐"
        #expect(buffer[0, 0].char == "┌")
        let row0 = rowString(buffer, row: 0)
        #expect(row0.hasSuffix("┐"))

        // Row 2: "└──────┴──────┘"
        #expect(buffer[2, 0].char == "└")
        let row2 = rowString(buffer, row: 2)
        #expect(row2.hasSuffix("┘"))
    }

    // MARK: - Alignment

    @Test("Trailing alignment positions tabs at the right edge")
    func trailingAlignment() {
        let buffer = renderTabView(
            alignment: .trailing,
            controlSize: .small,
            dividerStyle: TabDividerStyle.none,
            width: 30,
        )

        // Tab group width for .small: " Tab1 │ Tab2 " = 15
        // Offset = 30 - 15 = 15
        // Tab labels should end near col 30
        let row0 = rowString(buffer, row: 0)
        #expect(row0.count <= 30)
        // First 15 cols should be spaces
        for col in 0 ..< 15 {
            #expect(buffer[0, col].char == " ")
        }
    }
}
