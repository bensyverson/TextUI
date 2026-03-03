/// A focusable button that triggers an action when activated.
///
/// Button hugs its label content and responds to Enter or Space when
/// focused. The focused button renders with inverse styling.
///
/// Use ``View/buttonStyle(_:)`` to control the visual treatment:
///
/// ```swift
/// Button("Submit") {
///     submitForm()
/// }
/// .buttonStyle(.bordered)
///
/// Button {
///     cancel()
/// } label: {
///     Text("Cancel").foregroundColor(.red)
/// }
/// ```
public struct Button: PrimitiveView {
    let label: any View
    let action: () -> Void
    let autoKey: AnyHashable

    /// Creates a button with a text label.
    public init(
        _ title: String,
        action: @escaping () -> Void,
        fileID: String = #fileID,
        line: Int = #line,
    ) {
        label = Text(title)
        self.action = action
        autoKey = AnyHashable("\(fileID):\(line)")
    }

    /// Creates a button with a custom label view.
    public init(
        action: @escaping () -> Void,
        fileID: String = #fileID,
        line: Int = #line,
        @ViewBuilder label: () -> ViewGroup,
    ) {
        self.label = label()
        self.action = action
        autoKey = AnyHashable("\(fileID):\(line)")
    }

    public func sizeThatFits(_ proposal: SizeProposal, context: RenderContext) -> Size2D {
        let style = context.buttonStyle ?? .plain
        let labelSize = TextUI.sizeThatFits(label, proposal: proposal, context: context)
        switch style {
        case .plain:
            return labelSize
        case .bordered, .borderedProminent:
            // +4 width (border left/right + 1 space padding each side)
            // +2 height (border top/bottom)
            let innerProposal = proposal.inset(horizontal: 4, vertical: 2)
            let innerSize = TextUI.sizeThatFits(label, proposal: innerProposal, context: context)
            return Size2D(
                width: innerSize.width + 4,
                height: innerSize.height + 2,
            )
        }
    }

    public func render(into buffer: inout Buffer, region: Region, context: RenderContext) {
        let style = context.buttonStyle ?? .plain

        // When disabled, render label only — no focus registration or handler
        if context.isDisabled == true {
            renderContent(style: style, into: &buffer, region: region, context: context)
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

        // Register inline handler when focused
        if isFocused, let id = effectiveFocusID {
            store?.registerInlineHandler(for: id) { [action] key in
                if key == .enter || key == .character(" ") {
                    action()
                    return .handled
                }
                return .ignored
            }
        }

        // Render content with appropriate style
        renderContent(style: style, into: &buffer, region: region, context: context)

        // Apply inverse styling when focused
        if isFocused {
            let inverseStyle = Style(inverse: true)
            for r in region.row ..< min(region.row + region.height, buffer.height) {
                for c in region.col ..< min(region.col + region.width, buffer.width) {
                    guard r >= 0, c >= 0 else { continue }
                    guard !buffer[r, c].isContinuation else { continue }
                    buffer[r, c].style = buffer[r, c].style.merging(inverseStyle)
                }
            }
        }
    }

    // MARK: - Private

    private func renderContent(
        style: ButtonStyle,
        into buffer: inout Buffer,
        region: Region,
        context: RenderContext,
    ) {
        switch style {
        case .plain:
            TextUI.render(label, into: &buffer, region: region, context: context)

        case .bordered, .borderedProminent:
            guard region.width >= 4, region.height >= 2 else { return }

            let lastCol = region.col + region.width - 1
            let lastRow = region.row + region.height - 1

            // Draw rounded border
            buffer[region.row, region.col] = Cell(char: "╭")
            buffer[region.row, lastCol] = Cell(char: "╮")
            buffer[lastRow, region.col] = Cell(char: "╰")
            buffer[lastRow, lastCol] = Cell(char: "╯")

            buffer.horizontalLine(
                row: region.row, col: region.col + 1,
                length: region.width - 2, char: "─",
            )
            buffer.horizontalLine(
                row: lastRow, col: region.col + 1,
                length: region.width - 2, char: "─",
            )
            buffer.verticalLine(
                row: region.row + 1, col: region.col,
                length: region.height - 2, char: "│",
            )
            buffer.verticalLine(
                row: region.row + 1, col: lastCol,
                length: region.height - 2, char: "│",
            )

            // Render label inside border with 1-cell horizontal padding
            let innerRegion = region.inset(top: 1, left: 2, bottom: 1, right: 2)
            TextUI.render(label, into: &buffer, region: innerRegion, context: context)

            // For borderedProminent, apply bold to the label cells
            if style == .borderedProminent {
                let boldStyle = Style(bold: true)
                for r in innerRegion.row ..< min(innerRegion.row + innerRegion.height, buffer.height) {
                    for c in innerRegion.col ..< min(innerRegion.col + innerRegion.width, buffer.width) {
                        guard r >= 0, c >= 0 else { continue }
                        guard !buffer[r, c].isContinuation else { continue }
                        buffer[r, c].style = buffer[r, c].style.merging(boldStyle)
                    }
                }
            }
        }
    }
}
