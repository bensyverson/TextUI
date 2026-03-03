/// A focusable picker that cycles through a list of options.
///
/// Picker renders as `Label: < Option >` and responds to Left/Right
/// arrow keys, Space, or Enter when focused. Pressing Space or Enter
/// opens a dropdown overlay where Up/Down selects an option and Enter
/// confirms.
///
/// ```swift
/// Picker("Color", selection: settings.colorIndex, options: colors) { newIndex in
///     settings.colorIndex = newIndex
/// }
/// ```
///
/// The `options` array provides display strings. The `selection` is an
/// index into this array.
public struct Picker: PrimitiveView {
    let label: String
    let selection: Int
    let options: [String]
    let onChange: (Int) -> Void
    let autoKey: AnyHashable

    /// Persistent dropdown state for the picker.
    struct PickerState: Sendable {
        var isDropdownOpen: Bool = false
        var highlightedIndex: Int = 0
    }

    /// Creates a picker with a label and option list.
    ///
    /// - Parameters:
    ///   - label: The text displayed before the arrows.
    ///   - selection: The index of the currently selected option.
    ///   - options: The display strings for each option.
    ///   - fileID: The source file identifier (used for automatic focus keys).
    ///   - line: The source line number (used for automatic focus keys).
    ///   - onChange: Called with the new selection index when changed.
    public init(
        _ label: String,
        selection: Int,
        options: [String],
        fileID: String = #fileID,
        line: Int = #line,
        onChange: @escaping (Int) -> Void,
    ) {
        self.label = label
        self.selection = selection
        self.options = options
        self.onChange = onChange
        autoKey = AnyHashable("\(fileID):\(line)")
    }

    /// The width of the widest option string.
    private var maxOptionWidth: Int {
        options.map(\.displayWidth).max() ?? 0
    }

    public func sizeThatFits(_ proposal: SizeProposal, context _: RenderContext) -> Size2D {
        // "Label: < Option >"
        // label + ": " + "< " + maxOption + " >"
        let width = label.displayWidth + 2 + 2 + maxOptionWidth + 2
        return Size2D(width: min(width, proposal.width ?? .max), height: 1)
    }

    public func render(into buffer: inout Buffer, region: Region, context: RenderContext) {
        guard region.height >= 1, !options.isEmpty else { return }

        // When disabled, render label and current option only — no focus registration
        if context.isDisabled == true {
            let clampedSelection = min(max(selection, 0), options.count - 1)
            let currentOption = options[clampedSelection]
            var col = region.col
            col += buffer.write(label, row: region.row, col: col, style: .plain)
            col += buffer.write(": ", row: region.row, col: col, style: .plain)
            col += buffer.write("< ", row: region.row, col: col, style: .plain)
            col += buffer.write(currentOption, row: region.row, col: col, style: .plain)
            _ = buffer.write(" >", row: region.row, col: col, style: .plain)
            return
        }

        // Register in focus ring (skip if FocusedView already registered us)
        let store = context.focusStore
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
                autoKey: autoKey,
            )
            effectiveFocusID = focusID
            isFocused = focusID.flatMap { store?.isFocused($0) } ?? false
        }

        // Read dropdown state
        let pickerState = store?.controlState(forKey: autoKey, as: PickerState.self)
            ?? PickerState()
        let isDropdownOpen = pickerState.isDropdownOpen

        // Register inline handler when focused
        if isFocused, let id = effectiveFocusID {
            let capturedKey = autoKey
            store?.registerInlineHandler(for: id) { [selection, options, onChange] key in
                guard let store else { return .ignored }
                var state = store.controlState(forKey: capturedKey, as: PickerState.self)
                    ?? PickerState()

                if state.isDropdownOpen {
                    // Dropdown mode: intercept all navigation keys
                    switch key {
                    case .up:
                        state.highlightedIndex = (state.highlightedIndex - 1 + options.count) % options.count
                        store.setControlState(state, forKey: capturedKey)
                        return .handled
                    case .down:
                        state.highlightedIndex = (state.highlightedIndex + 1) % options.count
                        store.setControlState(state, forKey: capturedKey)
                        return .handled
                    case .enter:
                        onChange(state.highlightedIndex)
                        state.isDropdownOpen = false
                        store.setControlState(state, forKey: capturedKey)
                        return .handled
                    case .escape:
                        state.isDropdownOpen = false
                        store.setControlState(state, forKey: capturedKey)
                        return .handled
                    default:
                        return .handled // Swallow all other keys while dropdown is open
                    }
                } else {
                    // Normal mode
                    switch key {
                    case .left:
                        let newIndex = (selection - 1 + options.count) % options.count
                        onChange(newIndex)
                        return .handled
                    case .right:
                        let newIndex = (selection + 1) % options.count
                        onChange(newIndex)
                        return .handled
                    case .enter, .character(" "):
                        state.isDropdownOpen = true
                        state.highlightedIndex = selection
                        store.setControlState(state, forKey: capturedKey)
                        return .handled
                    default:
                        return .ignored
                    }
                }
            }
        }

        let clampedSelection = min(max(selection, 0), options.count - 1)
        let currentOption = options[clampedSelection]
        let style: Style = isFocused ? Style(inverse: true) : .plain

        var col = region.col
        col += buffer.write(label, row: region.row, col: col, style: style)
        col += buffer.write(": ", row: region.row, col: col, style: style)

        if isDropdownOpen {
            col += buffer.write("▼ ", row: region.row, col: col, style: style)
        } else {
            col += buffer.write("< ", row: region.row, col: col, style: style)
        }
        col += buffer.write(currentOption, row: region.row, col: col, style: style)
        // Pad to max option width for consistent layout
        let padding = maxOptionWidth - currentOption.displayWidth
        if padding > 0 {
            col += buffer.write(
                String(repeating: " ", count: padding),
                row: region.row,
                col: col,
                style: style,
            )
        }
        if isDropdownOpen {
            col += buffer.write(" ▼", row: region.row, col: col, style: style)
        } else {
            col += buffer.write(" >", row: region.row, col: col, style: style)
        }

        // Fill remaining width when focused
        if isFocused {
            while col < region.col + region.width, col < buffer.width {
                buffer[region.row, col].style = buffer[region.row, col].style.merging(style)
                col += 1
            }
        }

        // Register deferred overlay for dropdown (renders on top of everything)
        if isDropdownOpen, isFocused {
            let capturedOptions = options
            let highlightedIndex = pickerState.highlightedIndex
            let pickerRow = region.row
            let pickerCol = region.col
            let dropdownWidth = label.displayWidth + 2 + 2 + maxOptionWidth + 2

            context.overlayStore?.addOverlay(OverlayStore.Overlay { buffer, fullRegion in
                let border = BorderedView.BorderStyle.rounded
                // Account for top + bottom border rows in available space
                let spaceBelow = fullRegion.row + fullRegion.height - (pickerRow + 1) - 2
                let spaceAbove = pickerRow - fullRegion.row - 2
                let optionCount = capturedOptions.count

                // Choose direction: prefer below, flip above if needed
                let renderBelow: Bool
                let visibleCount: Int
                if optionCount <= spaceBelow {
                    renderBelow = true
                    visibleCount = optionCount
                } else if optionCount <= spaceAbove {
                    renderBelow = false
                    visibleCount = optionCount
                } else if spaceBelow >= spaceAbove {
                    renderBelow = true
                    visibleCount = max(spaceBelow, 0)
                } else {
                    renderBelow = false
                    visibleCount = max(spaceAbove, 0)
                }

                guard visibleCount > 0 else { return }

                // Compute scroll offset to keep highlighted item visible
                let scrollOffset: Int = if optionCount <= visibleCount {
                    0
                } else if highlightedIndex < visibleCount / 2 {
                    0
                } else if highlightedIndex > optionCount - visibleCount / 2 - 1 {
                    optionCount - visibleCount
                } else {
                    highlightedIndex - visibleCount / 2
                }

                // Border box dimensions (content + 2 for border)
                let boxWidth = dropdownWidth + 2
                let boxHeight = visibleCount + 2

                // Compute starting row for the border box
                let boxRow: Int = if renderBelow {
                    pickerRow + 1
                } else {
                    pickerRow - boxHeight
                }

                let boxCol = pickerCol

                // Draw rounded border
                guard boxRow >= 0,
                      boxRow + boxHeight <= buffer.height,
                      boxCol + boxWidth <= buffer.width
                else { return }

                buffer[boxRow, boxCol] = Cell(char: border.topLeft)
                buffer[boxRow, boxCol + boxWidth - 1] = Cell(char: border.topRight)
                buffer[boxRow + boxHeight - 1, boxCol] = Cell(char: border.bottomLeft)
                buffer[boxRow + boxHeight - 1, boxCol + boxWidth - 1] = Cell(char: border.bottomRight)
                buffer.horizontalLine(
                    row: boxRow, col: boxCol + 1,
                    length: boxWidth - 2, char: border.horizontal,
                )
                buffer.horizontalLine(
                    row: boxRow + boxHeight - 1, col: boxCol + 1,
                    length: boxWidth - 2, char: border.horizontal,
                )
                buffer.verticalLine(
                    row: boxRow + 1, col: boxCol,
                    length: boxHeight - 2, char: border.vertical,
                )
                buffer.verticalLine(
                    row: boxRow + 1, col: boxCol + boxWidth - 1,
                    length: boxHeight - 2, char: border.vertical,
                )

                // Render option rows inside the border
                let contentCol = boxCol + 1
                let contentStartRow = boxRow + 1

                for i in 0 ..< visibleCount {
                    let optionIndex = scrollOffset + i
                    guard optionIndex < capturedOptions.count else { break }
                    let row = contentStartRow + i

                    let option = capturedOptions[optionIndex]
                    let optionStyle: Style = optionIndex == highlightedIndex
                        ? Style(inverse: true)
                        : .plain

                    var optCol = contentCol
                    let prefix = optionIndex == highlightedIndex ? "▸ " : "  "
                    optCol += buffer.write(prefix, row: row, col: optCol, style: optionStyle)
                    optCol += buffer.write(option, row: row, col: optCol, style: optionStyle)

                    // Pad to consistent width (within the border)
                    while optCol < contentCol + dropdownWidth, optCol < buffer.width {
                        buffer[row, optCol] = Cell(char: " ", style: optionStyle)
                        optCol += 1
                    }
                }
            })
        }
    }
}
