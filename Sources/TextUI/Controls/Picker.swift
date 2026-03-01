/// A focusable picker that cycles through a list of options.
///
/// Picker renders as `Label: < Option >` and responds to Left/Right
/// arrow keys when focused. The selection is owned by the caller via
/// the `selection` parameter and `onChange` callback.
///
/// ```swift
/// Picker("Color", selection: settings.colorIndex, options: colors) { newIndex in
///     settings.colorIndex = newIndex
/// }
/// ```
///
/// The `options` array provides display strings. The `selection` is an
/// index into this array.
public struct Picker: PrimitiveView, @unchecked Sendable {
    let label: String
    let selection: Int
    let options: [String]
    let onChange: @Sendable (Int) -> Void
    let autoKey: AnyHashable

    /// Creates a picker with a label and option list.
    ///
    /// - Parameters:
    ///   - label: The text displayed before the arrows.
    ///   - selection: The index of the currently selected option.
    ///   - options: The display strings for each option.
    ///   - onChange: Called with the new selection index when changed.
    public init(
        _ label: String,
        selection: Int,
        options: [String],
        fileID: String = #fileID,
        line: Int = #line,
        onChange: @escaping @Sendable (Int) -> Void,
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

        // Register in focus ring
        let store = context.focusStore
        let focusID = store?.register(
            interaction: .activate,
            region: region,
            sectionID: context.currentFocusSectionID,
            bindingKey: nil,
            autoKey: autoKey,
        )
        let isFocused: Bool = if let env = context.focusEnvironment {
            env.isFocused
        } else {
            focusID.flatMap { store?.isFocused($0) } ?? false
        }

        // Register inline handler when focused
        if isFocused, let id = focusID {
            store?.registerInlineHandler(for: id) { [selection, options, onChange] key in
                switch key {
                case .left:
                    let newIndex = (selection - 1 + options.count) % options.count
                    onChange(newIndex)
                    return .handled
                case .right:
                    let newIndex = (selection + 1) % options.count
                    onChange(newIndex)
                    return .handled
                default:
                    return .ignored
                }
            }
        }

        let clampedSelection = min(max(selection, 0), options.count - 1)
        let currentOption = options[clampedSelection]
        let style: Style = isFocused ? Style(inverse: true) : .plain

        var col = region.col
        col += buffer.write(label, row: region.row, col: col, style: style)
        col += buffer.write(": ", row: region.row, col: col, style: style)
        col += buffer.write("< ", row: region.row, col: col, style: style)
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
        col += buffer.write(" >", row: region.row, col: col, style: style)

        // Fill remaining width when focused
        if isFocused {
            while col < region.col + region.width, col < buffer.width {
                buffer[region.row, col].style = buffer[region.row, col].style.merging(style)
                col += 1
            }
        }
    }
}
