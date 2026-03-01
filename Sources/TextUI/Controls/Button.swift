/// A focusable button that triggers an action when activated.
///
/// Button hugs its label content and responds to Enter or Space when
/// focused. The focused button renders with inverse styling.
///
/// ```swift
/// Button("Submit") {
///     submitForm()
/// }
///
/// Button {
///     cancel()
/// } label: {
///     Text("Cancel").foregroundColor(.red)
/// }
/// ```
public struct Button: PrimitiveView, @unchecked Sendable {
    let label: any View
    let action: @Sendable () -> Void
    let autoKey: AnyHashable

    /// Creates a button with a text label.
    public init(
        _ title: String,
        action: @escaping @Sendable () -> Void,
        fileID: String = #fileID,
        line: Int = #line,
    ) {
        label = Text(title)
        self.action = action
        autoKey = AnyHashable("\(fileID):\(line)")
    }

    /// Creates a button with a custom label view.
    public init(
        action: @escaping @Sendable () -> Void,
        fileID: String = #fileID,
        line: Int = #line,
        @ViewBuilder label: () -> ViewGroup,
    ) {
        self.label = label()
        self.action = action
        autoKey = AnyHashable("\(fileID):\(line)")
    }

    public func sizeThatFits(_ proposal: SizeProposal, context: RenderContext) -> Size2D {
        TextUI.sizeThatFits(label, proposal: proposal, context: context)
    }

    public func render(into buffer: inout Buffer, region: Region, context: RenderContext) {
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

        // Render label
        TextUI.render(label, into: &buffer, region: region, context: context)

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
}
