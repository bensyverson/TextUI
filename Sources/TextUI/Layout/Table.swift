/// A multi-column data table with a header row and scrollable body.
///
/// Table renders a bold header, a horizontal divider, then scrollable rows.
/// Column widths are coordinated: fixed columns take their exact width,
/// and flex columns share the remaining space equally. Columns are separated
/// by `│` characters.
///
/// ```swift
/// Table(rows: data.map { [$0.name, $0.email, $0.role] }) {
///     Column.fixed("ID", width: 4)
///     Column.flex("Name")
///     Column.flex("Email")
/// }
/// ```
///
/// The table is focusable and supports keyboard scrolling of its body rows
/// using Up/Down/PageUp/PageDown/Home/End keys.
public struct Table: PrimitiveView {
    /// The row data — each row is an array of views matching the columns.
    let rows: [[any View]]

    /// The column definitions.
    let columns: [Column]

    /// Whether to show a scroll indicator when rows overflow.
    let showsIndicator: Bool

    /// Auto-generated key for focus registration and state persistence.
    let autoKey: String

    /// A column definition for a ``Table``.
    public struct Column: Sendable {
        /// The column header title.
        let title: String

        /// The column width type.
        let widthType: WidthType

        enum WidthType: Sendable {
            case fixed(Int)
            case flex
        }

        /// Creates a fixed-width column.
        ///
        /// - Parameters:
        ///   - title: The header text for this column.
        ///   - width: The exact column width in characters.
        public static func fixed(_ title: String, width: Int) -> Column {
            Column(title: title, widthType: .fixed(width))
        }

        /// Creates a flexible-width column that shares remaining space equally.
        ///
        /// - Parameter title: The header text for this column.
        public static func flex(_ title: String) -> Column {
            Column(title: title, widthType: .flex)
        }
    }

    /// Creates a table with the given rows and column definitions.
    ///
    /// - Parameters:
    ///   - rows: An array of rows, each containing views for each column.
    ///   - showsIndicator: Whether to show a scroll indicator. Defaults to `true`.
    ///   - fileID: Auto-captured file ID for stable identity.
    ///   - line: Auto-captured line number for stable identity.
    ///   - columns: A ``ColumnBuilder`` closure defining the columns.
    public init(
        rows: [[any View]],
        showsIndicator: Bool = true,
        fileID: String = #fileID,
        line: Int = #line,
        @ColumnBuilder columns: () -> [Column],
    ) {
        self.rows = rows
        self.columns = columns()
        self.showsIndicator = showsIndicator
        selection = nil
        autoKey = "\(fileID):\(line)"
    }

    /// Creates a table whose selected row is driven by the parent.
    ///
    /// The `selection` value determines which row is highlighted each frame.
    /// Pair with ``View/onSelectionChange(_:)`` to be notified when the
    /// user selects a row, so you can update your state.
    ///
    /// - Parameters:
    ///   - rows: An array of rows, each containing views for each column.
    ///   - selection: The index of the row to highlight.
    ///   - showsIndicator: Whether to show a scroll indicator. Defaults to `true`.
    ///   - fileID: Auto-captured file ID for stable identity.
    ///   - line: Auto-captured line number for stable identity.
    ///   - columns: A ``ColumnBuilder`` closure defining the columns.
    public init(
        rows: [[any View]],
        selection: Int,
        showsIndicator: Bool = true,
        fileID: String = #fileID,
        line: Int = #line,
        @ColumnBuilder columns: () -> [Column],
    ) {
        self.rows = rows
        self.columns = columns()
        self.showsIndicator = showsIndicator
        self.selection = selection
        autoKey = "\(fileID):\(line)"
    }

    /// Parent-driven selected row index, or `nil` for internal management.
    ///
    /// When non-nil, the Table uses this value as the selected row each frame.
    /// Pair with ``View/onSelectionChange(_:)`` for two-way synchronisation.
    let selection: Int?

    /// Persistent scroll and selection state for the table body.
    struct ScrollState: Sendable {
        var offset: Int = 0
        var selectedRow: Int?
    }

    // MARK: - Column Width Calculation

    /// Computes column widths for the given available width.
    func computeColumnWidths(availableWidth: Int) -> [Int] {
        guard !columns.isEmpty else { return [] }

        // Subtract separators (1 char between adjacent columns)
        let separatorWidth = columns.count - 1
        let contentWidth = max(0, availableWidth - separatorWidth)

        // Allocate fixed columns
        var fixedTotal = 0
        var flexCount = 0
        for col in columns {
            switch col.widthType {
            case let .fixed(w): fixedTotal += w
            case .flex: flexCount += 1
            }
        }

        let remainingForFlex = max(0, contentWidth - fixedTotal)
        let flexWidth = flexCount > 0 ? remainingForFlex / flexCount : 0
        let flexRemainder = flexCount > 0 ? remainingForFlex % flexCount : 0

        var widths: [Int] = []
        var flexAssigned = 0
        for col in columns {
            switch col.widthType {
            case let .fixed(w):
                widths.append(w)
            case .flex:
                flexAssigned += 1
                // Distribute remainder to first flex columns
                let extra = flexAssigned <= flexRemainder ? 1 : 0
                widths.append(flexWidth + extra)
            }
        }
        return widths
    }

    // MARK: - Sizing

    public func sizeThatFits(_ proposal: SizeProposal, context _: RenderContext) -> Size2D {
        // Greedy on both axes
        Size2D(
            width: proposal.width ?? 80,
            height: proposal.height ?? (rows.count + 2),
        )
    }

    // MARK: - Rendering

    public func render(into buffer: inout Buffer, region: Region, context: RenderContext) {
        guard !region.isEmpty, !columns.isEmpty else { return }

        let store = context.focusStore
        let indicatorWidth = showsIndicator && rows.count > max(0, region.height - 2) ? 1 : 0
        let tableWidth = region.width - indicatorWidth
        let columnWidths = computeColumnWidths(availableWidth: tableWidth)

        // Register as focusable (skip if FocusedView already registered us)
        let effectiveFocusID: Int?
        let isFocused: Bool

        if let env = context.focusEnvironment {
            effectiveFocusID = env.focusID
            isFocused = env.isFocused
        } else {
            let focusID = store?.register(
                interaction: .activate,
                region: region,
                sectionID: context.currentFocusSectionID,
                bindingKey: nil,
                autoKey: AnyHashable(autoKey),
            )
            effectiveFocusID = focusID
            isFocused = focusID.flatMap { store?.isFocused($0) } ?? false
        }

        // Render header row (bold, inverse when focused)
        renderHeaderRow(into: &buffer, region: region, columnWidths: columnWidths, isFocused: isFocused)

        // Render divider row
        guard region.height > 1 else { return }
        renderDividerRow(into: &buffer, region: region, columnWidths: columnWidths)

        // Body area
        guard region.height > 2 else { return }
        let bodyHeight = region.height - 2
        let bodyRegion = region.subregion(row: 2, col: 0, width: region.width, height: bodyHeight)

        // Scroll and selection state
        let maxOffset = max(0, rows.count - bodyHeight)
        var state = store?.controlState(forKey: autoKey, as: ScrollState.self) ?? ScrollState()
        state.offset = max(0, min(state.offset, maxOffset))
        if let selection {
            state.selectedRow = selection
        }
        store?.setControlState(state, forKey: autoKey)

        // Store the selection change handler for this Table (if any)
        let isParentDriven = selection != nil
        let selectionHandler = store?.currentTableSelectionHandler
        if let selectionHandler {
            store?.tableSelectionHandlers[AnyHashable(autoKey)] = selectionHandler
        }

        // Register tap handler for click-to-select
        if let id = effectiveFocusID {
            let capturedKey = autoKey
            let rowCount = rows.count
            store?.registerTapHandler(for: id) {
                [isParentDriven, selectionHandler] clickRow, _ in
                guard let store else { return }
                var state = store.controlState(forKey: capturedKey, as: ScrollState.self)
                    ?? ScrollState()
                let headerRows = 2
                let dataRowIndex = (clickRow - region.row - headerRows) + state.offset
                guard dataRowIndex >= 0, dataRowIndex < rowCount else { return }
                if !isParentDriven {
                    state.selectedRow = dataRowIndex
                    store.setControlState(state, forKey: capturedKey)
                }
                selectionHandler?(dataRowIndex)
            }
        }

        // Keyboard handler: Up/Down moves selection, Page/Home/End scrolls
        let inlineHandler: (KeyEvent) -> KeyEventResult = {
            [autoKey, rowCount = rows.count, isParentDriven, selectionHandler] key in
            guard let store else { return .ignored }
            var state = store.controlState(forKey: autoKey, as: ScrollState.self) ?? ScrollState()

            switch key {
            case .up:
                let current = state.selectedRow ?? 0
                let newRow = max(0, current - 1)
                if !isParentDriven {
                    state.selectedRow = newRow
                    // Auto-scroll to keep selection visible
                    if newRow < state.offset {
                        state.offset = newRow
                    }
                }
                selectionHandler?(newRow)
            case .down:
                let current = state.selectedRow ?? -1
                let newRow = min(rowCount - 1, current + 1)
                if !isParentDriven {
                    state.selectedRow = newRow
                    // Auto-scroll to keep selection visible
                    if newRow >= state.offset + bodyHeight {
                        state.offset = newRow - bodyHeight + 1
                    }
                }
                selectionHandler?(newRow)
            case .pageUp:
                state.offset -= bodyHeight
            case .pageDown:
                state.offset += bodyHeight
            case .home:
                state.offset = 0
                if !isParentDriven {
                    state.selectedRow = 0
                }
                selectionHandler?(0)
            case .end:
                state.offset = maxOffset
                if !isParentDriven {
                    state.selectedRow = rowCount - 1
                }
                selectionHandler?(rowCount - 1)
            default:
                return .ignored
            }
            state.offset = max(0, min(state.offset, maxOffset))
            store.setControlState(state, forKey: autoKey)
            return .handled
        }

        if isFocused, let id = effectiveFocusID {
            store?.registerInlineHandler(for: id, handler: inlineHandler)
        }

        // Render visible rows
        let scrollOffset = state.offset
        let selectedRow = state.selectedRow
        for rowIdx in 0 ..< min(bodyHeight, rows.count - scrollOffset) {
            let dataIdx = scrollOffset + rowIdx
            guard dataIdx < rows.count else { break }

            let isSelected = dataIdx == selectedRow
            renderDataRow(
                row: rows[dataIdx],
                into: &buffer,
                rowOffset: region.row + 2 + rowIdx,
                colStart: region.col,
                columnWidths: columnWidths,
                isSelected: isSelected,
                context: context,
            )
        }

        // Render scroll indicator
        if showsIndicator, rows.count > bodyHeight {
            renderScrollIndicator(
                into: &buffer,
                bodyRegion: bodyRegion,
                totalRows: rows.count,
                scrollOffset: scrollOffset,
            )
        }
    }

    // MARK: - Row Rendering

    private func renderHeaderRow(
        into buffer: inout Buffer,
        region: Region,
        columnWidths: [Int],
        isFocused: Bool = false,
    ) {
        let boldStyle: Style = isFocused ? Style(bold: true, underline: true) : Style(bold: true)
        var colOffset = region.col
        for (i, column) in columns.enumerated() {
            let width = columnWidths[i]
            // Write title truncated to column width
            let title = String(column.title.prefix(width))
            buffer.write(title, row: region.row, col: colOffset, style: boldStyle)
            colOffset += width
            if i < columns.count - 1 {
                buffer.write("│", row: region.row, col: colOffset, style: boldStyle)
                colOffset += 1
            }
        }
    }

    private func renderDividerRow(
        into buffer: inout Buffer,
        region: Region,
        columnWidths: [Int],
    ) {
        let dividerRow = region.row + 1
        var colOffset = region.col
        for (i, _) in columns.enumerated() {
            let width = columnWidths[i]
            buffer.horizontalLine(row: dividerRow, col: colOffset, length: width)
            colOffset += width
            if i < columns.count - 1 {
                buffer.write("┼", row: dividerRow, col: colOffset)
                colOffset += 1
            }
        }
    }

    private func renderDataRow(
        row: [any View],
        into buffer: inout Buffer,
        rowOffset: Int,
        colStart: Int,
        columnWidths: [Int],
        isSelected: Bool = false,
        context: RenderContext,
    ) {
        var colOffset = colStart
        for (colIdx, width) in columnWidths.enumerated() {
            if colIdx < row.count {
                let cellRegion = Region(row: rowOffset, col: colOffset, width: width, height: 1)
                if isSelected {
                    let styled = StyledView(content: row[colIdx], styleOverride: Style(inverse: true))
                    TextUI.render(styled, into: &buffer, region: cellRegion, context: context)
                } else {
                    TextUI.render(row[colIdx], into: &buffer, region: cellRegion, context: context)
                }
            }
            colOffset += width
            if colIdx < columns.count - 1 {
                let sepStyle: Style = isSelected ? Style(inverse: true) : .plain
                buffer.write("│", row: rowOffset, col: colOffset, style: sepStyle)
                colOffset += 1
            }
        }
    }

    private func renderScrollIndicator(
        into buffer: inout Buffer,
        bodyRegion: Region,
        totalRows: Int,
        scrollOffset: Int,
    ) {
        let indicatorCol = bodyRegion.col + bodyRegion.width - 1
        guard indicatorCol >= 0, indicatorCol < buffer.width else { return }

        let viewportHeight = bodyRegion.height

        // Draw track
        for r in 0 ..< viewportHeight {
            let row = bodyRegion.row + r
            if row >= 0, row < buffer.height {
                buffer.write("│", row: row, col: indicatorCol)
            }
        }

        // Compute thumb
        let thumbHeight = max(1, viewportHeight * viewportHeight / totalRows)
        let maxOffset = max(1, totalRows - viewportHeight)
        let thumbTop = scrollOffset * (viewportHeight - thumbHeight) / maxOffset

        for r in thumbTop ..< min(thumbTop + thumbHeight, viewportHeight) {
            let row = bodyRegion.row + r
            if row >= 0, row < buffer.height {
                buffer.write("█", row: row, col: indicatorCol)
            }
        }
    }
}

/// Result builder for constructing arrays of ``Table/Column``.
@resultBuilder
public enum ColumnBuilder {
    /// Builds a block of columns.
    public static func buildBlock(_ components: Table.Column...) -> [Table.Column] {
        Array(components)
    }

    /// Builds a column array from a `for` loop.
    public static func buildArray(_ components: [[Table.Column]]) -> [Table.Column] {
        components.flatMap(\.self)
    }
}
