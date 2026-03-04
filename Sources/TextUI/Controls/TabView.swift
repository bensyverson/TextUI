/// A container that switches between multiple content views using a tab bar.
///
/// TabView renders a tab bar at the top with content below. The tab bar
/// is focusable and responds to Left/Right arrow keys to switch tabs. The
/// selected tab's content fills the remaining space.
///
/// ```swift
/// TabView {
///     TabView.Tab("Home") {
///         Text("Welcome!")
///     }
///     TabView.Tab("Settings") {
///         Text("Preferences")
///     }
/// }
/// ```
///
/// ### Control Size
///
/// Use ``View/controlSize(_:)`` to choose between three density levels:
/// - **`.small`** — 1-line compact inline tab bar.
/// - **`.regular`** (default) — 2-line with labels embedded in a border row.
/// - **`.large`** — 3-line with full tab boxes.
///
/// ### Tab Divider
///
/// Use ``View/tabDividerStyle(_:)`` to control the horizontal rule:
/// - **`.none`** — No divider; tabs float above content.
/// - **`.bottom`** (default) — Rule below the tab bar.
/// - **`.middle`** — Rule through center of tab labels (`.large` only).
///
/// ### Tab Border
///
/// Use ``View/tabBorderStyle(_:)`` to draw a border around the content area,
/// merged with the divider. Ignored when the divider is `.none`.
///
/// ### Alignment
///
/// Pass `alignment:` to position the tab group within the region width.
///
/// ### Selected Tab Styling
///
/// - **Inactive tabs:** dim text and dim border characters.
/// - **Active (unfocused):** bold text and bold border characters.
/// - **Active (focused):** inverse styling.
public struct TabView: PrimitiveView {
    /// The tab definitions (label + content).
    let tabs: [Tab]

    /// Horizontal alignment of the tab group within the region.
    let alignment: HorizontalAlignment

    /// Auto-generated key for focus registration and state persistence.
    let autoKey: String

    /// A single tab within a ``TabView``.
    public struct Tab {
        /// The display label for this tab.
        let label: String

        /// The content view displayed when this tab is selected.
        let content: any View

        /// Creates a tab with a label and content.
        ///
        /// - Parameters:
        ///   - label: The text shown in the tab bar.
        ///   - content: A ``ViewBuilder`` closure producing the tab's content.
        public init(_ label: String, @ViewBuilder content: () -> ViewGroup) {
            self.label = label
            self.content = content()
        }
    }

    /// Creates a tab view with the given tabs.
    ///
    /// - Parameters:
    ///   - alignment: Horizontal alignment of the tab group (default: `.leading`).
    ///   - fileID: Auto-captured file ID for stable identity.
    ///   - line: Auto-captured line number for stable identity.
    ///   - content: A ``TabBuilder`` closure producing the tabs.
    public init(
        alignment: HorizontalAlignment = .leading,
        fileID: String = #fileID,
        line: Int = #line,
        @TabBuilder content: () -> [Tab],
    ) {
        tabs = content()
        self.alignment = alignment
        autoKey = "\(fileID):\(line)"
    }

    /// Persistent tab selection state.
    struct TabState: Sendable {
        var selectedIndex: Int = 0
        var tabCount: Int = 0
    }

    // MARK: - Sizing

    public func sizeThatFits(_ proposal: SizeProposal, context: RenderContext) -> Size2D {
        let controlSize = context.controlSize ?? .regular
        let dividerStyle = effectiveDividerStyle(controlSize: controlSize, context: context)
        let hasBorder = effectiveHasBorder(dividerStyle: dividerStyle, context: context)

        // Greedy on both axes
        let width = proposal.width ?? tabGroupWidth(controlSize: controlSize)
        let topChrome = topChromeRows(controlSize: controlSize, dividerStyle: dividerStyle)
        let bottomChrome = hasBorder ? 1 : 0
        let height = proposal.height ?? (topChrome + bottomChrome + 1)
        return Size2D(width: width, height: height)
    }

    /// The natural width of the tab group (the tab labels with their chrome).
    private func tabGroupWidth(controlSize: ControlSize) -> Int {
        guard !tabs.isEmpty else { return 2 }
        let labelWidths = tabs.reduce(0) { $0 + $1.label.displayWidth }

        switch controlSize {
        case .small:
            // " Tab1 │ Tab2 │ Tab3 "
            let padding = tabs.count * 2
            let separators = tabs.count - 1
            return labelWidths + padding + separators

        case .regular:
            // "╭─ Tab1 │ Tab2 ─╮"
            let padding = tabs.count * 2
            let separators = tabs.count - 1
            return labelWidths + padding + separators + 4 // ╭─ ... ─╮

        case .large:
            // "╭───────┬───────╮"
            // "│ Tab 1 │ Tab 2 │"
            // "╰───────┴───────╯"
            let padding = tabs.count * 2
            let separators = tabs.count - 1
            return labelWidths + padding + separators + 2 // │ ... │
        }
    }

    /// Number of rows consumed by top chrome (tab bar rows before content).
    private func topChromeRows(controlSize: ControlSize, dividerStyle _: TabDividerStyle) -> Int {
        switch controlSize {
        case .small:
            1
        case .regular:
            // Label row + divider/bottom row
            2
        case .large:
            3
        }
    }

    /// Resolves the effective divider style (`.middle` degrades to `.bottom` for non-`.large`).
    private func effectiveDividerStyle(controlSize: ControlSize, context: RenderContext) -> TabDividerStyle {
        let raw = context.tabDividerStyle ?? .bottom
        if raw == .middle, controlSize != .large {
            return .bottom
        }
        return raw
    }

    /// Whether content border is active (requires both a border style and a non-`.none` divider).
    private func effectiveHasBorder(dividerStyle: TabDividerStyle, context: RenderContext) -> Bool {
        context.tabBorderStyle != nil && dividerStyle != .none
    }

    // MARK: - Rendering

    public func render(into buffer: inout Buffer, region: Region, context: RenderContext) {
        guard !region.isEmpty, !tabs.isEmpty else { return }
        let store = context.focusStore
        let controlSize = context.controlSize ?? .regular
        let dividerStyle = effectiveDividerStyle(controlSize: controlSize, context: context)
        let hasBorder = effectiveHasBorder(dividerStyle: dividerStyle, context: context)
        let borderStyle = context.tabBorderStyle ?? .rounded

        // Read selected tab
        var state = store?.controlState(forKey: autoKey, as: TabState.self) ?? TabState()
        state.selectedIndex = max(0, min(state.selectedIndex, tabs.count - 1))
        state.tabCount = tabs.count
        store?.setControlState(state, forKey: autoKey)
        store?.tabViewKeys.append(AnyHashable(autoKey))
        let selectedIndex = state.selectedIndex

        // Register tab bar as focusable (skip if FocusedView already registered us)
        let topChrome = topChromeRows(controlSize: controlSize, dividerStyle: dividerStyle)
        let tabBarRegion = region.subregion(row: 0, col: 0, width: region.width, height: min(topChrome, region.height))
        let effectiveFocusID: Int?
        let isFocused: Bool

        if let env = context.focusEnvironment {
            effectiveFocusID = env.focusID
            isFocused = env.isFocused
        } else {
            let focusID = store?.register(
                interaction: .activate,
                region: tabBarRegion,
                sectionID: context.currentFocusSectionID,
                bindingKey: nil,
                autoKey: AnyHashable(autoKey),
            )
            effectiveFocusID = focusID
            isFocused = focusID.flatMap { store?.isFocused($0) } ?? false
        }

        // Register inline handler for Left/Right tab switching
        if isFocused, let id = effectiveFocusID {
            store?.registerInlineHandler(for: id) { [autoKey, tabCount = tabs.count] key in
                guard let store else { return .ignored }
                var state = store.controlState(forKey: autoKey, as: TabState.self) ?? TabState()
                switch key {
                case .left:
                    state.selectedIndex = (state.selectedIndex - 1 + tabCount) % tabCount
                    store.setControlState(state, forKey: autoKey)
                    return .handled
                case .right:
                    state.selectedIndex = (state.selectedIndex + 1) % tabCount
                    store.setControlState(state, forKey: autoKey)
                    return .handled
                default:
                    return .ignored
                }
            }
        }

        // Tab box corner style inherits from tabBorderStyle, defaulting to .rounded
        let tabBoxStyle = context.tabBorderStyle ?? .rounded

        // Compute tab group offset based on alignment
        let groupWidth = tabGroupWidth(controlSize: controlSize)
        let tabOffset = alignmentOffset(groupWidth: groupWidth, regionWidth: region.width)

        // Render tab chrome
        switch controlSize {
        case .small:
            renderSmallTabBar(
                into: &buffer, region: region,
                selectedIndex: selectedIndex, isFocused: isFocused,
                dividerStyle: dividerStyle, hasBorder: hasBorder,
                borderStyle: borderStyle, tabOffset: tabOffset,
            )
        case .regular:
            renderRegularTabBar(
                into: &buffer, region: region,
                selectedIndex: selectedIndex, isFocused: isFocused,
                dividerStyle: dividerStyle, hasBorder: hasBorder,
                borderStyle: borderStyle, tabBoxStyle: tabBoxStyle,
                tabOffset: tabOffset,
            )
        case .large:
            renderLargeTabBar(
                into: &buffer, region: region,
                selectedIndex: selectedIndex, isFocused: isFocused,
                dividerStyle: dividerStyle, hasBorder: hasBorder,
                borderStyle: borderStyle, tabBoxStyle: tabBoxStyle,
                tabOffset: tabOffset,
            )
        }

        // Render content area
        let contentStartRow = topChrome
        guard region.height > contentStartRow else { return }

        let contentCol: Int
        let contentWidth: Int
        let contentHeight: Int

        if hasBorder {
            // Content inside border: left/right borders reduce width by 2
            contentCol = 1
            contentWidth = region.width - 2
            // -1 for the bottom border row
            contentHeight = region.height - contentStartRow - 1
        } else {
            contentCol = 0
            contentWidth = region.width
            contentHeight = region.height - contentStartRow
        }

        guard contentWidth > 0, contentHeight > 0 else { return }
        let contentRegion = region.subregion(
            row: contentStartRow, col: contentCol,
            width: contentWidth, height: contentHeight,
        )

        // Render left/right/bottom borders for content if applicable
        if hasBorder {
            let lastCol = region.col + region.width - 1
            let lastRow = region.row + region.height - 1

            // Left and right vertical borders (from content start to last row - 1)
            let borderStartRow = region.row + contentStartRow
            for r in borderStartRow ..< lastRow {
                buffer[r, region.col] = Cell(char: borderStyle.vertical)
                buffer[r, lastCol] = Cell(char: borderStyle.vertical)
            }

            // Bottom border row
            buffer[lastRow, region.col] = Cell(char: borderStyle.bottomLeft)
            buffer[lastRow, lastCol] = Cell(char: borderStyle.bottomRight)
            buffer.horizontalLine(
                row: lastRow, col: region.col + 1,
                length: region.width - 2, char: borderStyle.horizontal,
            )
        }

        // Create focus section for content
        var contentContext = context
        if let store {
            contentContext.currentFocusSectionID = store.nextSection()
        }

        TextUI.render(tabs[selectedIndex].content, into: &buffer, region: contentRegion, context: contentContext)
    }

    // MARK: - Alignment

    /// Computes the horizontal offset for the tab group based on alignment.
    private func alignmentOffset(groupWidth: Int, regionWidth: Int) -> Int {
        let available = max(0, regionWidth - groupWidth)
        switch alignment {
        case .leading:
            return 0
        case .center:
            return available / 2
        case .trailing:
            return available
        }
    }

    // MARK: - Tab Styling

    /// Returns the style for a tab label.
    private func tabLabelStyle(isSelected: Bool, isFocused: Bool) -> Style {
        if isSelected, isFocused {
            Style(inverse: true)
        } else if isSelected {
            Style(bold: true)
        } else {
            Style(dim: true)
        }
    }

    /// Returns the style for tab chrome (borders/corners) around a tab.
    private func tabChromeStyle(isSelected: Bool, isFocused: Bool) -> Style {
        if isSelected, isFocused {
            Style(inverse: true)
        } else if isSelected {
            Style(bold: true)
        } else {
            Style(dim: true)
        }
    }

    // MARK: - Small Tab Bar (1-line)

    /// Renders a 1-line compact tab bar.
    ///
    /// **`.none` divider, leading:**
    /// ```
    ///  Tab1 │ Tab2 │ Tab3
    /// ```
    ///
    /// **`.bottom` divider, leading:**
    /// ```
    /// │ Tab1 │ Tab2 │ Tab3 ─────────
    /// ```
    ///
    /// **`.bottom` divider, center:**
    /// ```
    /// ──────── Tab1 │ Tab2 │ Tab3 ──
    /// ```
    private func renderSmallTabBar(
        into buffer: inout Buffer,
        region: Region,
        selectedIndex: Int,
        isFocused: Bool,
        dividerStyle: TabDividerStyle,
        hasBorder: Bool,
        borderStyle: BorderedView.BorderStyle,
        tabOffset: Int,
    ) {
        let row = region.row

        if dividerStyle == .none {
            // No divider: just render tab labels with separators
            var col = region.col + tabOffset
            for (i, tab) in tabs.enumerated() {
                let style = tabLabelStyle(isSelected: i == selectedIndex, isFocused: isFocused)
                col += buffer.write(" ", row: row, col: col, style: style)
                col += buffer.write(tab.label, row: row, col: col, style: style)
                col += buffer.write(" ", row: row, col: col, style: style)
                if i < tabs.count - 1 {
                    let sepStyle = tabChromeStyle(isSelected: false, isFocused: false)
                    col += buffer.write("│", row: row, col: col, style: sepStyle)
                }
            }
        } else {
            // Divider present: tab labels sit on a horizontal line
            let groupWidth = tabGroupWidth(controlSize: .small)
            let tabStart = region.col + tabOffset

            if hasBorder {
                // Border wraps the content — draw border top row
                let lastCol = region.col + region.width - 1

                // Fill the entire row with horizontal line first
                buffer[row, region.col] = Cell(char: borderStyle.topLeft)
                buffer[row, lastCol] = Cell(char: borderStyle.topRight)
                buffer.horizontalLine(
                    row: row, col: region.col + 1,
                    length: region.width - 2, char: borderStyle.horizontal,
                )

                // Overwrite with tab labels
                var col = tabStart
                for (i, tab) in tabs.enumerated() {
                    let style = tabLabelStyle(isSelected: i == selectedIndex, isFocused: isFocused)
                    col += buffer.write(" ", row: row, col: col, style: style)
                    col += buffer.write(tab.label, row: row, col: col, style: style)
                    col += buffer.write(" ", row: row, col: col, style: style)
                    if i < tabs.count - 1 {
                        let sepStyle = tabChromeStyle(isSelected: false, isFocused: false)
                        col += buffer.write("│", row: row, col: col, style: sepStyle)
                    }
                }
            } else {
                // No border — leading separator + tabs + trailing line
                let tabEnd = tabStart + groupWidth

                // Draw leading horizontal line (before tabs)
                if tabStart > region.col {
                    buffer.horizontalLine(
                        row: row, col: region.col,
                        length: tabStart - region.col, char: "─",
                    )
                }

                // Render tab labels with leading separator
                var col = tabStart
                col += buffer.write("│", row: row, col: col)
                for (i, tab) in tabs.enumerated() {
                    let style = tabLabelStyle(isSelected: i == selectedIndex, isFocused: isFocused)
                    col += buffer.write(" ", row: row, col: col, style: style)
                    col += buffer.write(tab.label, row: row, col: col, style: style)
                    col += buffer.write(" ", row: row, col: col, style: style)
                    if i < tabs.count - 1 {
                        let sepStyle = tabChromeStyle(isSelected: false, isFocused: false)
                        col += buffer.write("│", row: row, col: col, style: sepStyle)
                    }
                }

                // Draw trailing horizontal line (after tabs)
                let lastCol = region.col + region.width
                if col < lastCol {
                    buffer.horizontalLine(
                        row: row, col: col,
                        length: lastCol - col, char: "─",
                    )
                }
                _ = tabEnd // suppress unused warning
            }
        }
    }

    // MARK: - Regular Tab Bar (2-line)

    /// Renders a 2-line tab bar with labels embedded in a border row.
    ///
    /// **Row 0:** `╭─ Tab1 │ Tab2 ─╮`
    /// **Row 1 (`.bottom` divider):** `┴────────────────┴───────────`
    private func renderRegularTabBar(
        into buffer: inout Buffer,
        region: Region,
        selectedIndex: Int,
        isFocused: Bool,
        dividerStyle: TabDividerStyle,
        hasBorder: Bool,
        borderStyle: BorderedView.BorderStyle,
        tabBoxStyle: BorderedView.BorderStyle,
        tabOffset: Int,
    ) {
        let row0 = region.row
        let groupWidth = tabGroupWidth(controlSize: .regular)
        let tabStart = region.col + tabOffset

        // Row 0: Tab label row — ╭─ Tab1 │ Tab2 ─╮
        var col = tabStart
        let chromeStyle: Style = .plain // tab box chrome is always plain

        col += buffer.write(String(tabBoxStyle.topLeft), row: row0, col: col, style: chromeStyle)
        col += buffer.write("─", row: row0, col: col, style: chromeStyle)

        for (i, tab) in tabs.enumerated() {
            let style = tabLabelStyle(isSelected: i == selectedIndex, isFocused: isFocused)
            col += buffer.write(" ", row: row0, col: col, style: style)
            col += buffer.write(tab.label, row: row0, col: col, style: style)
            col += buffer.write(" ", row: row0, col: col, style: style)
            if i < tabs.count - 1 {
                let sepStyle = tabChromeStyle(isSelected: false, isFocused: false)
                col += buffer.write("│", row: row0, col: col, style: sepStyle)
            }
        }

        col += buffer.write("─", row: row0, col: col, style: chromeStyle)
        col += buffer.write(String(tabBoxStyle.topRight), row: row0, col: col, style: chromeStyle)

        if dividerStyle == .none {
            // No divider — just close the box on the bottom
            let row1 = row0 + 1
            guard row1 < region.row + region.height else { return }

            // Bottom of the tab box
            let boxStart = tabStart
            let boxEnd = tabStart + groupWidth
            buffer[row1, boxStart] = Cell(char: tabBoxStyle.bottomLeft)
            buffer[row1, boxEnd - 1] = Cell(char: tabBoxStyle.bottomRight)
            buffer.horizontalLine(
                row: row1, col: boxStart + 1,
                length: groupWidth - 2, char: tabBoxStyle.horizontal,
            )
        } else {
            // Divider row — ┴───────────────────┴───────────
            let row1 = row0 + 1
            guard row1 < region.row + region.height else { return }

            let boxStart = tabStart
            let boxEnd = tabStart + groupWidth

            if hasBorder {
                // Content border: ╭────────┴───────────────────┴────────────╮
                let lastCol = region.col + region.width - 1
                buffer[row1, region.col] = Cell(char: borderStyle.topLeft)
                buffer[row1, lastCol] = Cell(char: borderStyle.topRight)
                buffer.horizontalLine(
                    row: row1, col: region.col + 1,
                    length: region.width - 2, char: borderStyle.horizontal,
                )
                // Place ┴ joins where tab box edges meet divider
                buffer[row1, boxStart] = Cell(char: borderStyle.teeUp)
                buffer[row1, boxEnd - 1] = Cell(char: borderStyle.teeUp)
            } else {
                // No border — just a line with ┴ at tab box edges
                buffer.horizontalLine(
                    row: row1, col: region.col,
                    length: region.width, char: "─",
                )
                buffer[row1, boxStart] = Cell(char: "┴")
                buffer[row1, boxEnd - 1] = Cell(char: "┴")
            }
        }
    }

    // MARK: - Large Tab Bar (3-line)

    /// Renders a 3-line tab bar with full tab boxes.
    ///
    /// **Row 0:** `╭───────┬───────╮`
    /// **Row 1:** `│ Tab 1 │ Tab 2 │`
    /// **Row 2:** depends on divider style
    private func renderLargeTabBar(
        into buffer: inout Buffer,
        region: Region,
        selectedIndex: Int,
        isFocused: Bool,
        dividerStyle: TabDividerStyle,
        hasBorder: Bool,
        borderStyle: BorderedView.BorderStyle,
        tabBoxStyle: BorderedView.BorderStyle,
        tabOffset: Int,
    ) {
        let row0 = region.row
        let row1 = row0 + 1
        let row2 = row0 + 2
        let groupWidth = tabGroupWidth(controlSize: .large)
        let tabStart = region.col + tabOffset

        guard row2 < region.row + region.height else { return }

        // Row 0: Top of tab boxes — ╭───────┬───────╮
        var col = tabStart
        col += buffer.write(String(tabBoxStyle.topLeft), row: row0, col: col)

        for (i, tab) in tabs.enumerated() {
            let cellWidth = tab.label.displayWidth + 2 // space + label + space
            buffer.horizontalLine(row: row0, col: col, length: cellWidth, char: tabBoxStyle.horizontal)
            col += cellWidth
            if i < tabs.count - 1 {
                col += buffer.write(String(tabBoxStyle.teeDown), row: row0, col: col)
            }
        }

        col += buffer.write(String(tabBoxStyle.topRight), row: row0, col: col)

        // Row 1: Labels — │ Tab 1 │ Tab 2 │
        col = tabStart
        col += buffer.write("│", row: row1, col: col)

        for (i, tab) in tabs.enumerated() {
            let style = tabLabelStyle(isSelected: i == selectedIndex, isFocused: isFocused)
            col += buffer.write(" ", row: row1, col: col, style: style)
            col += buffer.write(tab.label, row: row1, col: col, style: style)
            col += buffer.write(" ", row: row1, col: col, style: style)
            if i < tabs.count - 1 {
                let sepStyle = tabChromeStyle(isSelected: false, isFocused: false)
                col += buffer.write("│", row: row1, col: col, style: sepStyle)
            }
        }

        col += buffer.write("│", row: row1, col: col)

        // Row 2: Bottom/divider row — depends on divider style
        switch dividerStyle {
        case .none:
            // Just close the boxes — ╰───────┴───────╯
            col = tabStart
            col += buffer.write(String(tabBoxStyle.bottomLeft), row: row2, col: col)

            for (i, tab) in tabs.enumerated() {
                let cellWidth = tab.label.displayWidth + 2
                buffer.horizontalLine(row: row2, col: col, length: cellWidth, char: tabBoxStyle.horizontal)
                col += cellWidth
                if i < tabs.count - 1 {
                    col += buffer.write(String(tabBoxStyle.teeUp), row: row2, col: col)
                }
            }

            col += buffer.write(String(tabBoxStyle.bottomRight), row: row2, col: col)

        case .bottom:
            // Bottom divider — tab box bottom merges with horizontal line
            let tabEnd = tabStart + groupWidth

            if hasBorder {
                // ╭───────────┴───────┴───────┴──────────╮
                let lastCol = region.col + region.width - 1
                buffer[row2, region.col] = Cell(char: borderStyle.topLeft)
                buffer[row2, lastCol] = Cell(char: borderStyle.topRight)
                buffer.horizontalLine(
                    row: row2, col: region.col + 1,
                    length: region.width - 2, char: borderStyle.horizontal,
                )
            } else {
                // ┴───────┴───────┴───────┴──────────────
                buffer.horizontalLine(
                    row: row2, col: region.col,
                    length: region.width, char: "─",
                )
            }

            // Place ┴ joins at each tab box vertical position
            col = tabStart
            buffer[row2, col] = Cell(char: "┴")
            for (i, tab) in tabs.enumerated() {
                let cellWidth = tab.label.displayWidth + 2
                col += cellWidth
                if i < tabs.count - 1 {
                    buffer[row2, col] = Cell(char: "┴")
                    col += 1
                }
            }
            buffer[row2, tabEnd - 1] = Cell(char: "┴")

        case .middle:
            // Middle divider — ┤ and ├ at tab edges
            let tabEnd = tabStart + groupWidth

            if hasBorder {
                // ╭───────────┤ Tab 1 │ Tab 2 ├──────────╮
                let lastCol = region.col + region.width - 1
                buffer[row2, region.col] = Cell(char: borderStyle.topLeft)
                buffer[row2, lastCol] = Cell(char: borderStyle.topRight)
                buffer.horizontalLine(
                    row: row2, col: region.col + 1,
                    length: region.width - 2, char: borderStyle.horizontal,
                )
            } else {
                // ────────────┤ Tab 1 │ Tab 2 ├──────────
                buffer.horizontalLine(
                    row: row2, col: region.col,
                    length: region.width, char: "─",
                )
            }

            // Place ┤ at left edge and ├ at right edge of tab group
            buffer[row2, tabStart] = Cell(char: "┤")
            buffer[row2, tabEnd - 1] = Cell(char: "├")

            // Close tab boxes below — ╰───────┴───────╯
            // Actually for .middle, the tab boxes continue below too
            // The bottom of tab boxes goes on row 2 as well, but only the
            // inner separators and corners, not the horizontal line
            col = tabStart
            col += 1 // skip the ┤
            for (i, tab) in tabs.enumerated() {
                let cellWidth = tab.label.displayWidth + 2
                buffer.horizontalLine(row: row2, col: col, length: cellWidth, char: tabBoxStyle.horizontal)
                col += cellWidth
                if i < tabs.count - 1 {
                    buffer[row2, col] = Cell(char: tabBoxStyle.teeUp)
                    col += 1
                }
            }
            // Don't overwrite the ├ at the end
        }
    }
}

/// Result builder for constructing arrays of ``TabView/Tab``.
@resultBuilder
public enum TabBuilder {
    /// Builds a block of tabs.
    public static func buildBlock(_ components: TabView.Tab...) -> [TabView.Tab] {
        Array(components)
    }

    /// Builds a tab array from a `for` loop.
    public static func buildArray(_ components: [[TabView.Tab]]) -> [TabView.Tab] {
        components.flatMap(\.self)
    }
}
