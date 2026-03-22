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

    /// Parent-driven selected tab index, or `nil` for internal management.
    ///
    /// When non-nil, the TabView uses this value as the selected tab index
    /// each frame. Pair with ``View/onSelectionChange(_:)`` for two-way
    /// synchronisation.
    let selection: Int?

    /// A single tab within a ``TabView``.
    public struct Tab {
        /// The display label for this tab.
        let label: String

        /// An optional custom view to render as the tab label.
        ///
        /// When provided, this view is rendered into the label region instead
        /// of the plain `label` string. Use this for status indicators, spinners,
        /// colored badges, or any rich content in the tab bar.
        let customLabel: (any View)?

        /// The content view displayed when this tab is selected.
        let content: any View

        /// Creates a tab with a string label and content.
        ///
        /// - Parameters:
        ///   - label: The text shown in the tab bar.
        ///   - content: A ``ViewBuilder`` closure producing the tab's content.
        public init(_ label: String, @ViewBuilder content: () -> ViewGroup) {
            self.label = label
            customLabel = nil
            self.content = content()
        }

        /// Creates a tab with a custom label view and content.
        ///
        /// The custom label replaces the plain string in the tab bar, allowing
        /// rich content like spinners, colored text, or status indicators.
        /// The `label` string is still used for width measurement in the tab
        /// bar layout — it should match the expected display width of the
        /// custom view.
        ///
        /// ```swift
        /// TabView.Tab("⠹ PM") {
        ///     HStack {
        ///         Text("⠹ ").animating()
        ///         Text("PM")
        ///     }
        /// } content: {
        ///     MyTabContent()
        /// }
        /// ```
        ///
        /// - Parameters:
        ///   - label: A string used for width measurement in the tab bar layout.
        ///   - customLabel: A ``ViewBuilder`` closure producing the label view.
        ///   - content: A ``ViewBuilder`` closure producing the tab's content.
        public init(
            _ label: String,
            @ViewBuilder customLabel: () -> ViewGroup,
            @ViewBuilder content: () -> ViewGroup,
        ) {
            self.label = label
            self.customLabel = customLabel()
            self.content = content()
        }
    }

    /// Creates a tab view with the given tabs.
    ///
    /// The TabView manages its own selected tab internally.
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
        selection = nil
        autoKey = "\(fileID):\(line)"
    }

    /// Creates a tab view whose selected tab is driven by the parent.
    ///
    /// The `selection` value determines which tab is displayed each frame.
    /// Pair with ``View/onSelectionChange(_:)`` to be notified when the
    /// user switches tabs, so you can update your state:
    ///
    /// ```swift
    /// TabView(selection: state.selectedTab) {
    ///     TabView.Tab("Home") { HomeView() }
    ///     TabView.Tab("Settings") { SettingsView() }
    /// }
    /// .onSelectionChange { state.selectedTab = $0 }
    /// ```
    ///
    /// - Parameters:
    ///   - selection: The index of the tab to display.
    ///   - alignment: Horizontal alignment of the tab group (default: `.leading`).
    ///   - fileID: Auto-captured file ID for stable identity.
    ///   - line: Auto-captured line number for stable identity.
    ///   - content: A ``TabBuilder`` closure producing the tabs.
    public init(
        selection: Int,
        alignment: HorizontalAlignment = .leading,
        fileID: String = #fileID,
        line: Int = #line,
        @TabBuilder content: () -> [Tab],
    ) {
        tabs = content()
        self.alignment = alignment
        self.selection = selection
        autoKey = "\(fileID):\(line)"
    }

    // MARK: - Tab Label Rendering

    /// Renders a tab's label into the buffer at the given position.
    ///
    /// For string-only labels, uses `buffer.write` with the given style.
    /// For custom label views, renders the view into a 1-row region.
    /// Returns the number of columns consumed.
    @discardableResult
    private func renderTabLabel(
        _ tab: Tab,
        into buffer: inout Buffer,
        row: Int,
        col: Int,
        style: Style,
        context: RenderContext,
    ) -> Int {
        let width = tab.label.displayWidth
        if let view = tab.customLabel {
            let region = Region(row: row, col: col, width: width, height: 1)
            let styled = StyledView(content: view, styleOverride: style)
            TextUI.render(styled, into: &buffer, region: region, context: context)
            return width
        }
        return buffer.write(tab.label, row: row, col: col, style: style)
    }

    /// Persistent tab selection state.
    struct TabState: Sendable {
        var selectedIndex: Int = 0
        var tabCount: Int = 0
        /// Whether the parent drives the selected index via ``TabView/selection``.
        var isParentDriven: Bool = false
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
        if let selection {
            state.selectedIndex = selection
        }
        state.selectedIndex = max(0, min(state.selectedIndex, tabs.count - 1))
        state.tabCount = tabs.count
        state.isParentDriven = selection != nil
        store?.setControlState(state, forKey: autoKey)
        store?.tabViewKeys.append(AnyHashable(autoKey))
        let selectedIndex = state.selectedIndex

        // Store the selection change handler for this TabView (if any)
        let selectionHandler = store?.currentTabSelectionHandler
        if let selectionHandler {
            store?.tabSelectionHandlers[AnyHashable(autoKey)] = selectionHandler
        }

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
        let isParentDriven = selection != nil
        if isFocused, let id = effectiveFocusID {
            store?.registerInlineHandler(for: id) { [autoKey, tabCount = tabs.count, selectionHandler] key in
                guard let store else { return .ignored }
                var state = store.controlState(forKey: autoKey, as: TabState.self) ?? TabState()
                let newIndex: Int
                switch key {
                case .left:
                    newIndex = (state.selectedIndex - 1 + tabCount) % tabCount
                case .right:
                    newIndex = (state.selectedIndex + 1) % tabCount
                default:
                    return .ignored
                }
                if !isParentDriven {
                    state.selectedIndex = newIndex
                    store.setControlState(state, forKey: autoKey)
                }
                selectionHandler?(newIndex)
                return .handled
            }
        }

        // Tab box corner style inherits from tabBorderStyle, defaulting to .rounded
        let tabBoxStyle = context.tabBorderStyle ?? .rounded

        // Compute tab group offset based on alignment
        let groupWidth = tabGroupWidth(controlSize: controlSize)
        let tabOffset = alignmentOffset(groupWidth: groupWidth, regionWidth: region.width)

        // Register tap handler for click-on-tab
        if let id = effectiveFocusID {
            let capturedKey = autoKey
            let capturedTabs = tabs
            store?.registerTapHandler(for: id) {
                [isParentDriven, selectionHandler, controlSize, dividerStyle, hasBorder]
                _, clickColumn in
                let ranges = TabView.tabClickRanges(
                    tabs: capturedTabs,
                    controlSize: controlSize,
                    tabOffset: tabOffset,
                    regionCol: region.col,
                    dividerStyle: dividerStyle,
                    hasBorder: hasBorder,
                )
                guard let tappedIndex = ranges.firstIndex(where: {
                    clickColumn >= $0.start && clickColumn < $0.end
                }) else { return }

                guard let store else { return }
                if !isParentDriven {
                    var state = store.controlState(forKey: capturedKey, as: TabState.self)
                        ?? TabState()
                    state.selectedIndex = tappedIndex
                    store.setControlState(state, forKey: capturedKey)
                }
                selectionHandler?(tappedIndex)
            }
        }

        // Render tab chrome
        switch controlSize {
        case .small:
            renderSmallTabBar(
                into: &buffer, region: region,
                selectedIndex: selectedIndex, isFocused: isFocused,
                dividerStyle: dividerStyle, hasBorder: hasBorder,
                borderStyle: borderStyle, tabOffset: tabOffset,
                context: context,
            )
        case .regular:
            renderRegularTabBar(
                into: &buffer, region: region,
                selectedIndex: selectedIndex, isFocused: isFocused,
                dividerStyle: dividerStyle, hasBorder: hasBorder,
                borderStyle: borderStyle, tabBoxStyle: tabBoxStyle,
                tabOffset: tabOffset, context: context,
            )
        case .large:
            renderLargeTabBar(
                into: &buffer, region: region,
                selectedIndex: selectedIndex, isFocused: isFocused,
                dividerStyle: dividerStyle, hasBorder: hasBorder,
                borderStyle: borderStyle, tabBoxStyle: tabBoxStyle,
                tabOffset: tabOffset, context: context,
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

    // MARK: - Tab Click Ranges

    /// Computes the clickable column range for each tab label (including padding).
    ///
    /// Returns absolute column positions as `(start, end)` half-open intervals.
    /// The prefix before the first label varies by control size and styling:
    /// - **Small, `.none` divider or border:** 0
    /// - **Small, `.bottom` divider, no border:** 1 (leading `│`)
    /// - **Regular:** 2 (leading `╭─`)
    /// - **Large:** 1 (leading `│`)
    static func tabClickRanges(
        tabs: [Tab],
        controlSize: ControlSize,
        tabOffset: Int,
        regionCol: Int,
        dividerStyle: TabDividerStyle,
        hasBorder: Bool,
    ) -> [(start: Int, end: Int)] {
        let prefix: Int = switch controlSize {
        case .small:
            (dividerStyle != .none && !hasBorder) ? 1 : 0
        case .regular:
            2
        case .large:
            1
        }

        var col = regionCol + tabOffset + prefix
        var ranges: [(start: Int, end: Int)] = []
        for (i, tab) in tabs.enumerated() {
            let width = tab.label.displayWidth + 2 // space + label + space
            ranges.append((start: col, end: col + width))
            col += width
            if i < tabs.count - 1 {
                col += 1 // separator │
            }
        }
        return ranges
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
        context: RenderContext,
    ) {
        let row = region.row

        if dividerStyle == .none {
            // No divider: just render tab labels with separators
            var col = region.col + tabOffset
            for (i, tab) in tabs.enumerated() {
                let style = tabLabelStyle(isSelected: i == selectedIndex, isFocused: isFocused)
                col += buffer.write(" ", row: row, col: col, style: style)
                col += renderTabLabel(tab, into: &buffer, row: row, col: col, style: style, context: context)
                col += buffer.write(" ", row: row, col: col, style: style)
                if i < tabs.count - 1 {
                    col += buffer.write("│", row: row, col: col)
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
                    col += renderTabLabel(tab, into: &buffer, row: row, col: col, style: style, context: context)
                    col += buffer.write(" ", row: row, col: col, style: style)
                    if i < tabs.count - 1 {
                        col += buffer.write("│", row: row, col: col)
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
                    col += renderTabLabel(tab, into: &buffer, row: row, col: col, style: style, context: context)
                    col += buffer.write(" ", row: row, col: col, style: style)
                    if i < tabs.count - 1 {
                        col += buffer.write("│", row: row, col: col)
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
        context: RenderContext,
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
            col += renderTabLabel(tab, into: &buffer, row: row0, col: col, style: style, context: context)
            col += buffer.write(" ", row: row0, col: col, style: style)
            if i < tabs.count - 1 {
                col += buffer.write("│", row: row0, col: col)
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
                // Place ┴ joins where tab box edges meet divider.
                // When a tab edge coincides with a border edge, use ├/┤ instead.
                buffer[row1, boxStart] = Cell(char: boxStart == region.col ? "├" : "┴")
                buffer[row1, boxEnd - 1] = Cell(char: boxEnd - 1 == lastCol ? "┤" : "┴")
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
        context: RenderContext,
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

        // Row 1 and Row 2 depend on divider style.
        //
        // For .none and .bottom:
        //   Row 1 = labels:  │ Tab 1 │ Tab 2 │
        //   Row 2 = .none closes boxes, .bottom draws divider
        //
        // For .middle:
        //   Row 1 = horizontal rule through labels:  ────┤ Tab 1 │ Tab 2 ├────
        //   Row 2 = close boxes:  ╰───────┴───────╯

        if dividerStyle == .middle {
            // Row 1: Horizontal rule with labels embedded
            renderLargeMiddleRow(
                into: &buffer, row: row1,
                region: region, tabStart: tabStart, groupWidth: groupWidth,
                selectedIndex: selectedIndex, isFocused: isFocused,
                hasBorder: hasBorder, borderStyle: borderStyle,
                context: context,
            )

            // Row 2: Close tab boxes + optional border verticals
            renderLargeTabBoxBottom(
                into: &buffer, row: row2,
                region: region, tabStart: tabStart,
                tabBoxStyle: tabBoxStyle, hasBorder: hasBorder, borderStyle: borderStyle,
            )
        } else {
            // Row 1: Labels — │ Tab 1 │ Tab 2 │
            col = tabStart
            col += buffer.write("│", row: row1, col: col)

            for (i, tab) in tabs.enumerated() {
                let style = tabLabelStyle(isSelected: i == selectedIndex, isFocused: isFocused)
                col += buffer.write(" ", row: row1, col: col, style: style)
                col += renderTabLabel(tab, into: &buffer, row: row1, col: col, style: style, context: context)
                col += buffer.write(" ", row: row1, col: col, style: style)
                if i < tabs.count - 1 {
                    col += buffer.write("│", row: row1, col: col)
                }
            }

            col += buffer.write("│", row: row1, col: col)

            // Row 2
            if dividerStyle == .none {
                // Close boxes — ╰───────┴───────╯
                renderLargeTabBoxBottom(
                    into: &buffer, row: row2,
                    region: region, tabStart: tabStart,
                    tabBoxStyle: tabBoxStyle, hasBorder: false, borderStyle: borderStyle,
                )
            } else {
                // .bottom divider — horizontal line with ┴ at tab verticals
                renderLargeBottomDivider(
                    into: &buffer, row: row2,
                    region: region, tabStart: tabStart, groupWidth: groupWidth,
                    hasBorder: hasBorder, borderStyle: borderStyle,
                )
            }
        }
    }

    // MARK: - Large Tab Bar Helpers

    /// Draws the `.bottom` divider row for large tab bars.
    ///
    /// Produces a horizontal line with `┴` at each tab vertical position.
    /// When a border is active, the line becomes the border top row with
    /// `├` where the tab left edge overlaps the border left edge.
    private func renderLargeBottomDivider(
        into buffer: inout Buffer,
        row: Int,
        region: Region,
        tabStart: Int,
        groupWidth: Int,
        hasBorder: Bool,
        borderStyle: BorderedView.BorderStyle,
    ) {
        let lastCol = region.col + region.width - 1

        // Fill with horizontal line
        buffer.horizontalLine(
            row: row, col: region.col,
            length: region.width, char: "─",
        )

        if hasBorder {
            buffer[row, region.col] = Cell(char: borderStyle.topLeft)
            buffer[row, lastCol] = Cell(char: borderStyle.topRight)
        }

        // Place ┴ at each tab vertical position
        var col = tabStart
        buffer[row, col] = Cell(char: "┴")
        col += 1
        for (i, tab) in tabs.enumerated() {
            col += tab.label.displayWidth + 2
            if i < tabs.count - 1 {
                buffer[row, col] = Cell(char: "┴")
                col += 1
            }
        }
        buffer[row, col] = Cell(char: "┴")

        // Fix overlaps: when tab edge coincides with border edge,
        // use ├/┤ (vertical continues both up and down, horizontal extends inward)
        if hasBorder, tabStart == region.col {
            buffer[row, region.col] = Cell(char: "├")
        }
        if hasBorder, tabStart + groupWidth - 1 == lastCol {
            buffer[row, lastCol] = Cell(char: "┤")
        }
    }

    /// Draws the `.middle` divider on the label row for large tab bars.
    ///
    /// The horizontal rule extends left and right of the tab group. Tab
    /// labels are written over it. `┤` marks the left tab edge and `├`
    /// marks the right tab edge (where the rule meets the tab box vertical).
    private func renderLargeMiddleRow(
        into buffer: inout Buffer,
        row: Int,
        region: Region,
        tabStart: Int,
        groupWidth: Int,
        selectedIndex: Int,
        isFocused: Bool,
        hasBorder: Bool,
        borderStyle: BorderedView.BorderStyle,
        context: RenderContext,
    ) {
        let lastCol = region.col + region.width - 1
        let tabEnd = tabStart + groupWidth

        // Fill the entire row with horizontal line
        buffer.horizontalLine(
            row: row, col: region.col,
            length: region.width, char: "─",
        )

        if hasBorder {
            buffer[row, region.col] = Cell(char: borderStyle.topLeft)
            buffer[row, lastCol] = Cell(char: borderStyle.topRight)
        }

        // Write tab labels over the line
        var col = tabStart

        // Left edge join: ┤ if there's horizontal line to the left, otherwise │
        if tabStart > region.col {
            col += buffer.write("┤", row: row, col: col)
        } else {
            col += buffer.write("│", row: row, col: col)
        }

        for (i, tab) in tabs.enumerated() {
            let style = tabLabelStyle(isSelected: i == selectedIndex, isFocused: isFocused)
            col += buffer.write(" ", row: row, col: col, style: style)
            col += renderTabLabel(tab, into: &buffer, row: row, col: col, style: style, context: context)
            col += buffer.write(" ", row: row, col: col, style: style)
            if i < tabs.count - 1 {
                col += buffer.write("│", row: row, col: col)
            }
        }

        // Right edge join: ├ if there's horizontal line to the right, otherwise │
        if tabEnd - 1 < lastCol {
            col += buffer.write("├", row: row, col: col)
        } else {
            col += buffer.write("│", row: row, col: col)
        }
    }

    /// Draws the closed bottom of tab boxes (╰───┴───╯).
    ///
    /// Used by `.none` divider and as row 2 for `.middle` divider.
    /// When `hasBorder` is true, also draws border verticals at the region edges.
    private func renderLargeTabBoxBottom(
        into buffer: inout Buffer,
        row: Int,
        region: Region,
        tabStart: Int,
        tabBoxStyle: BorderedView.BorderStyle,
        hasBorder: Bool,
        borderStyle: BorderedView.BorderStyle,
    ) {
        var col = tabStart
        col += buffer.write(String(tabBoxStyle.bottomLeft), row: row, col: col)

        for (i, tab) in tabs.enumerated() {
            let cellWidth = tab.label.displayWidth + 2
            buffer.horizontalLine(row: row, col: col, length: cellWidth, char: tabBoxStyle.horizontal)
            col += cellWidth
            if i < tabs.count - 1 {
                col += buffer.write(String(tabBoxStyle.teeUp), row: row, col: col)
            }
        }

        col += buffer.write(String(tabBoxStyle.bottomRight), row: row, col: col)

        // Border verticals on the sides
        if hasBorder {
            let lastCol = region.col + region.width - 1
            buffer[row, region.col] = Cell(char: borderStyle.vertical)
            buffer[row, lastCol] = Cell(char: borderStyle.vertical)
        }
    }
}

/// Result builder for constructing arrays of ``TabView/Tab``.
@resultBuilder
public enum TabBuilder {
    /// The component type used throughout the builder.
    public static func buildExpression(_ expression: TabView.Tab) -> [TabView.Tab] {
        [expression]
    }

    /// Combines components from a builder block.
    public static func buildBlock(_ components: [TabView.Tab]...) -> [TabView.Tab] {
        components.flatMap(\.self)
    }

    /// Builds a tab array from a `for` loop.
    public static func buildArray(_ components: [[TabView.Tab]]) -> [TabView.Tab] {
        components.flatMap(\.self)
    }

    /// Supports `if` conditions.
    public static func buildOptional(_ component: [TabView.Tab]?) -> [TabView.Tab] {
        component ?? []
    }

    /// Supports `if/else` — first branch.
    public static func buildEither(first component: [TabView.Tab]) -> [TabView.Tab] {
        component
    }

    /// Supports `if/else` — second branch.
    public static func buildEither(second component: [TabView.Tab]) -> [TabView.Tab] {
        component
    }
}
