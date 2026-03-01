/// A command palette overlay that displays filterable command entries.
///
/// `CommandPalette` renders as a centered bordered overlay on top of the
/// existing content. It shows a filter text input and a scrollable list
/// of matching commands with their keyboard shortcuts.
///
/// This view is not placed in the user's view tree — it is rendered
/// directly by ``RunLoop`` after the root view when the palette is visible.
///
/// ```
/// ╭──── Command Palette ──────────────╮
/// │ > search text█                    │
/// ├───────────────────────────────────┤
/// │   Save                       ^S  │
/// │ ▸ Open                       ^O  │
/// │   Copy                       ^C  │
/// ╰───────────────────────────────────╯
/// ```
struct CommandPalette: PrimitiveView, Sendable {
    func sizeThatFits(_ proposal: SizeProposal, context _: RenderContext) -> Size2D {
        let w = proposal.width ?? 0
        let h = proposal.height ?? 0
        return Size2D(width: w, height: h)
    }

    func render(into buffer: inout Buffer, region: Region, context: RenderContext) {
        guard let registry = context.commandRegistry else { return }
        guard region.width >= 20, region.height >= 5 else { return }

        let entries = registry.filteredEntries
        let paletteWidth = min(50, region.width - 4)
        let maxVisibleEntries = min(10, region.height - 6)
        let visibleCount = min(entries.count, maxVisibleEntries)

        // Height: top border + filter + separator + entries + bottom border
        let paletteHeight = 3 + max(visibleCount, 1) + 1

        // Center the palette
        let startCol = region.col + (region.width - paletteWidth) / 2
        let startRow = region.row + (region.height - paletteHeight) / 2

        let innerWidth = paletteWidth - 2 // Excluding left/right borders

        let style = BorderedView.BorderStyle.rounded

        // Fill background
        let bgRegion = Region(
            row: startRow,
            col: startCol,
            width: paletteWidth,
            height: paletteHeight,
        )
        buffer.fill(bgRegion, char: " ")

        // Top border with centered title
        let title = " Command Palette "
        let titleStart = (innerWidth - title.count) / 2
        buffer[startRow, startCol] = Cell(char: style.topLeft)
        buffer.horizontalLine(
            row: startRow, col: startCol + 1,
            length: innerWidth, char: style.horizontal,
        )
        buffer[startRow, startCol + paletteWidth - 1] = Cell(char: style.topRight)
        // Overlay title
        if titleStart > 0 {
            buffer.write(title, row: startRow, col: startCol + 1 + titleStart)
        }

        // Bottom border
        let bottomRow = startRow + paletteHeight - 1
        buffer[bottomRow, startCol] = Cell(char: style.bottomLeft)
        buffer.horizontalLine(
            row: bottomRow, col: startCol + 1,
            length: innerWidth, char: style.horizontal,
        )
        buffer[bottomRow, startCol + paletteWidth - 1] = Cell(char: style.bottomRight)

        // Left and right borders for all interior rows
        for r in (startRow + 1) ..< bottomRow {
            buffer[r, startCol] = Cell(char: style.vertical)
            buffer[r, startCol + paletteWidth - 1] = Cell(char: style.vertical)
        }

        // Filter line: │ > filterText█ │
        let filterRow = startRow + 1
        let filterPrefix = "> "
        let cursorChar: Character = "█"
        buffer.write(filterPrefix, row: filterRow, col: startCol + 2)
        let filterTextCol = startCol + 2 + filterPrefix.count
        if !registry.filterText.isEmpty {
            buffer.write(registry.filterText, row: filterRow, col: filterTextCol)
        }
        let cursorCol = filterTextCol + registry.filterText.count
        if cursorCol < startCol + paletteWidth - 1 {
            buffer[filterRow, cursorCol] = Cell(char: cursorChar)
        }

        // Separator: ├───────────────────┤
        let sepRow = startRow + 2
        buffer[sepRow, startCol] = Cell(char: "├")
        buffer.horizontalLine(
            row: sepRow, col: startCol + 1,
            length: innerWidth, char: style.horizontal,
        )
        buffer[sepRow, startCol + paletteWidth - 1] = Cell(char: "┤")

        // Entries
        let selectedIndex = registry.selectedIndex
        let entryStartRow = startRow + 3

        if entries.isEmpty {
            // Show "No matches" centered
            let noMatch = "No matches"
            let nmCol = startCol + 1 + (innerWidth - noMatch.count) / 2
            buffer.write(noMatch, row: entryStartRow, col: nmCol, style: Style(dim: true))
        } else {
            // Calculate scroll offset to keep selection visible
            let scrollOffset: Int = if selectedIndex < maxVisibleEntries {
                0
            } else {
                selectedIndex - maxVisibleEntries + 1
            }

            for i in 0 ..< visibleCount {
                let entryIndex = scrollOffset + i
                guard entryIndex < entries.count else { break }
                let entry = entries[entryIndex]
                let row = entryStartRow + i
                let isSelected = entryIndex == selectedIndex

                let entryStyle = isSelected ? Style(inverse: true) : .plain

                // Fill entire row with style for selected entry
                if isSelected {
                    let rowRegion = Region(
                        row: row, col: startCol + 1,
                        width: innerWidth, height: 1,
                    )
                    buffer.fill(rowRegion, char: " ", style: entryStyle)
                }

                // Selection indicator
                let indicator: String = isSelected ? " ▸ " : "   "
                buffer.write(indicator, row: row, col: startCol + 1, style: entryStyle)

                // Entry name
                let nameCol = startCol + 4
                let maxNameWidth: Int
                if let shortcut = entry.shortcut {
                    // Reserve space for shortcut + padding
                    let shortcutWidth = shortcut.displayString.count + 2
                    maxNameWidth = innerWidth - 3 - shortcutWidth
                    // Shortcut right-aligned, dim (or inverse if selected)
                    let shortcutStr = shortcut.displayString
                    let shortcutCol = startCol + paletteWidth - 2 - shortcutStr.count
                    let shortcutStyle = isSelected
                        ? Style(inverse: true)
                        : Style(dim: true)
                    buffer.write(shortcutStr, row: row, col: shortcutCol, style: shortcutStyle)
                } else {
                    maxNameWidth = innerWidth - 3
                }

                let displayName: String = if entry.name.count > maxNameWidth, maxNameWidth > 0 {
                    String(entry.name.prefix(maxNameWidth))
                } else {
                    entry.name
                }
                buffer.write(displayName, row: row, col: nameCol, style: entryStyle)
            }
        }
    }
}
