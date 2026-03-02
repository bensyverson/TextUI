/// A focusable single-line text input field.
///
/// TextField is greedy on width (fills available space) and has a fixed
/// height of 1. When focused, it displays a cursor and captures keyboard
/// input. Cursor position is stored in the `FocusStore` so it persists
/// across render frames.
///
/// ```swift
/// TextField("Search", text: state.query) { newValue in
///     state.query = newValue
/// }
///     .onSubmit { performSearch() }
/// ```
public struct TextField: PrimitiveView, @unchecked Sendable {
    let placeholder: String
    let text: String
    let onChange: @Sendable (String) -> Void
    let autoKey: String

    /// Creates a text field with a placeholder and current text value.
    ///
    /// - Parameters:
    ///   - placeholder: Dim text shown when the field is empty and unfocused.
    ///   - text: The current text content.
    ///   - fileID: The source file identifier (used for automatic focus keys).
    ///   - line: The source line number (used for automatic focus keys).
    ///   - onChange: Called with the new text when the user edits.
    public init(
        _ placeholder: String,
        text: String,
        fileID: String = #fileID,
        line: Int = #line,
        onChange: @escaping @Sendable (String) -> Void,
    ) {
        self.placeholder = placeholder
        self.text = text
        self.onChange = onChange
        autoKey = "\(fileID):\(line)"
    }

    /// Persistent editing state stored in the `FocusStore`.
    ///
    /// Stores both cursor position and working text so that multiple
    /// key events in a single frame can build on each other's changes
    /// without waiting for a re-render.
    struct EditState: Sendable {
        var cursor: Int
        var text: String
    }

    /// The effective key for storing editing state.
    private var stateKey: String {
        autoKey
    }

    public func sizeThatFits(_ proposal: SizeProposal, context _: RenderContext) -> Size2D {
        // Greedy width, fixed height of 1
        Size2D(width: proposal.width ?? 20, height: 1)
    }

    public func render(into buffer: inout Buffer, region: Region, context: RenderContext) {
        guard region.height >= 1, region.width >= 1 else { return }

        // When disabled, render text or placeholder only — no focus registration
        if context.isDisabled == true {
            if text.isEmpty {
                _ = buffer.write(placeholder, row: region.row, col: region.col, style: Style(dim: true))
            } else {
                _ = buffer.write(text, row: region.row, col: region.col, style: .plain)
            }
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
                interaction: .edit,
                region: region,
                sectionID: context.currentFocusSectionID,
                bindingKey: nil,
                autoKey: AnyHashable(autoKey),
            )
            effectiveFocusID = focusID
            isFocused = focusID.flatMap { store?.isFocused($0) } ?? false
        }

        // Get or initialize editing state.
        // If the stored text matches the current text, use the stored cursor.
        // Otherwise, the external text has changed — reset to end of new text
        // and persist the reset so the handler sees it.
        let editState: EditState = {
            let key = AnyHashable(stateKey)
            if let stored = store?.controlState(forKey: key, as: EditState.self),
               stored.text == text
            {
                return stored
            }
            let reset = EditState(cursor: text.count, text: text)
            store?.setControlState(reset, forKey: key)
            return reset
        }()
        let cursorPos = editState.cursor

        // Register inline handler when focused
        if isFocused, let id = effectiveFocusID {
            let capturedStateKey = AnyHashable(stateKey)
            nonisolated(unsafe) let sendableKey = capturedStateKey
            store?.registerInlineHandler(for: id) { [onChange, store] key in
                // Read working state from store — this picks up changes from
                // earlier key events in the same frame.
                guard let store else { return .ignored }
                var state = store.controlState(forKey: sendableKey, as: EditState.self)
                    ?? editState

                switch key {
                case let .character(ch):
                    let idx = state.text.index(state.text.startIndex, offsetBy: state.cursor)
                    state.text.insert(ch, at: idx)
                    state.cursor += 1

                case .backspace:
                    guard state.cursor > 0 else { return .handled }
                    let idx = state.text.index(state.text.startIndex, offsetBy: state.cursor - 1)
                    state.text.remove(at: idx)
                    state.cursor -= 1

                case .delete:
                    guard state.cursor < state.text.count else { return .handled }
                    let idx = state.text.index(state.text.startIndex, offsetBy: state.cursor)
                    state.text.remove(at: idx)

                case .left:
                    state.cursor = max(0, state.cursor - 1)

                case .right:
                    state.cursor = min(state.text.count, state.cursor + 1)

                case .home:
                    state.cursor = 0

                case .end:
                    state.cursor = state.text.count

                default:
                    return .ignored
                }

                let textChanged = state.text != editState.text
                store.setControlState(state, forKey: sendableKey)
                if textChanged {
                    onChange(state.text)
                }
                return .handled
            }
        }

        // Render content
        if text.isEmpty, !isFocused {
            // Show placeholder when empty and unfocused
            _ = buffer.write(placeholder, row: region.row, col: region.col, style: Style(dim: true))
        } else {
            // Calculate visible window (scroll if cursor would be off-screen)
            let visibleWidth = region.width
            let scrollOffset: Int = if cursorPos >= visibleWidth {
                cursorPos - visibleWidth + 1
            } else {
                0
            }

            // Render visible portion of text
            let chars = Array(text)
            var col = region.col
            for i in scrollOffset ..< chars.count {
                guard col < region.col + visibleWidth else { break }
                let style: Style = isFocused && i == cursorPos
                    ? Style(inverse: true)
                    : .plain
                col += buffer.write(String(chars[i]), row: region.row, col: col, style: style)
            }

            // Render cursor at end of text (block cursor on empty space)
            if isFocused, cursorPos >= chars.count, cursorPos - scrollOffset < visibleWidth {
                let cursorCol = region.col + cursorPos - scrollOffset
                if cursorCol < region.col + visibleWidth, cursorCol < buffer.width {
                    buffer[region.row, cursorCol].style = Style(inverse: true)
                }
            }
        }
    }
}
