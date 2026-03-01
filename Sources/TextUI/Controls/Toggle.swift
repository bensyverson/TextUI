/// A focusable toggle that switches between on and off states.
///
/// Toggle renders as `[x] Label` (on) or `[ ] Label` (off) and responds
/// to Space when focused. The state is owned by the caller via the
/// `isOn` parameter and `onChange` callback.
///
/// ```swift
/// Toggle("Dark mode", isOn: settings.darkMode) { newValue in
///     settings.darkMode = newValue
/// }
/// ```
public struct Toggle: PrimitiveView, @unchecked Sendable {
    let label: String
    let isOn: Bool
    let onChange: @Sendable (Bool) -> Void
    let autoKey: AnyHashable

    /// Creates a toggle with a text label.
    ///
    /// - Parameters:
    ///   - label: The text displayed after the checkbox.
    ///   - isOn: The current on/off state.
    ///   - fileID: The source file identifier (used for automatic focus keys).
    ///   - line: The source line number (used for automatic focus keys).
    ///   - onChange: Called with the new value when toggled.
    public init(
        _ label: String,
        isOn: Bool,
        fileID: String = #fileID,
        line: Int = #line,
        onChange: @escaping @Sendable (Bool) -> Void,
    ) {
        self.label = label
        self.isOn = isOn
        self.onChange = onChange
        autoKey = AnyHashable("\(fileID):\(line)")
    }

    public func sizeThatFits(_ proposal: SizeProposal, context _: RenderContext) -> Size2D {
        // "[x] " = 4 chars + label display width
        let width = 4 + label.displayWidth
        return Size2D(width: min(width, proposal.width ?? .max), height: 1)
    }

    public func render(into buffer: inout Buffer, region: Region, context: RenderContext) {
        guard region.height >= 1 else { return }

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
            store?.registerInlineHandler(for: id) { [isOn, onChange] key in
                if key == .character(" ") {
                    onChange(!isOn)
                    return .handled
                }
                return .ignored
            }
        }

        // Render checkbox and label
        let checkbox = isOn ? "[x] " : "[ ] "
        let style: Style = isFocused ? Style(inverse: true) : .plain
        var col = region.col
        col += buffer.write(checkbox, row: region.row, col: col, style: style)
        col += buffer.write(label, row: region.row, col: col, style: style)

        // Fill remaining width with inverse when focused
        if isFocused {
            while col < region.col + region.width, col < buffer.width {
                buffer[region.row, col].style = buffer[region.row, col].style.merging(style)
                col += 1
            }
        }
    }
}
