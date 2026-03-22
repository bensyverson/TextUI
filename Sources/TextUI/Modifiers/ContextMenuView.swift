/// A view modifier that attaches a context menu to its content.
///
/// When the user right-clicks within the content's region, a bordered
/// menu overlay appears with the provided menu items. The menu is
/// dismissed by clicking an item, clicking outside, or pressing Escape.
///
/// Use the ``View/contextMenu(content:)`` modifier rather than
/// constructing this type directly:
///
/// ```swift
/// Text("Turtle Rock")
///     .contextMenu {
///         Button("Add to Favorites") { addFavorite() }
///         Button("Show in Maps") { showInMaps() }
///     }
/// ```
struct ContextMenuView: PrimitiveView {
    let content: any View
    let menuBuilder: @MainActor () -> [any View]
    let autoKey: AnyHashable

    /// Creates a context menu view with the default auto-generated key.
    init(
        content: any View,
        menuBuilder: @escaping @MainActor () -> [any View],
        fileID: String = #fileID,
        line: Int = #line,
    ) {
        self.content = content
        self.menuBuilder = menuBuilder
        autoKey = AnyHashable("\(fileID):\(line)")
    }

    /// Creates a context menu view with an explicit auto key (for testing).
    init(
        content: any View,
        menuBuilder: @escaping @MainActor () -> [any View],
        autoKey: AnyHashable,
    ) {
        self.content = content
        self.menuBuilder = menuBuilder
        self.autoKey = autoKey
    }

    func sizeThatFits(_ proposal: SizeProposal, context: RenderContext) -> Size2D {
        TextUI.sizeThatFits(content, proposal: proposal, context: context)
    }

    func render(into buffer: inout Buffer, region: Region, context: RenderContext) {
        // Render content normally
        TextUI.render(content, into: &buffer, region: region, context: context)

        let store = context.focusStore

        // Register this region as a context menu target
        store?.registerContextMenuTarget(FocusStore.ContextMenuTarget(
            region: region,
            autoKey: autoKey,
            menuBuilder: menuBuilder,
        ))

        // Check if the menu is currently open
        let menuState = store?.controlState(forKey: autoKey, as: FocusStore.ContextMenuState.self)
            ?? FocusStore.ContextMenuState()

        guard menuState.isOpen else { return }

        // Register dismiss handler to close on click-outside
        let capturedKey = autoKey
        store?.registerDismissHandler { [weak store] in
            guard let store else { return }
            var state = store.controlState(forKey: capturedKey, as: FocusStore.ContextMenuState.self)
                ?? FocusStore.ContextMenuState()
            state.isOpen = false
            store.setControlState(state, forKey: capturedKey)
        }

        // Build menu items and register overlay
        let menuItems = menuBuilder()
        let anchorRow = menuState.anchorRow
        let anchorCol = menuState.anchorCol

        context.overlayStore?.addOverlay(OverlayStore.Overlay { [capturedKey] buffer, fullRegion in
            guard !menuItems.isEmpty else { return }

            // Measure menu items to determine overlay size
            let itemWidths: [Int] = menuItems.map { item in
                let size = TextUI.sizeThatFits(item, proposal: SizeProposal(width: 40, height: 1), context: context)
                return size.width
            }
            let maxItemWidth = itemWidths.max() ?? 10
            let contentWidth = max(maxItemWidth, 8) // minimum 8 chars wide
            let boxWidth = contentWidth + 2 // border left + right
            let boxHeight = menuItems.count + 2 // border top + bottom

            // Position: prefer below-right of anchor, adjust if needed
            let spaceBelow = fullRegion.row + fullRegion.height - anchorRow
            let spaceAbove = anchorRow - fullRegion.row

            let boxRow: Int = if boxHeight <= spaceBelow {
                anchorRow
            } else if boxHeight <= spaceAbove {
                anchorRow - boxHeight
            } else {
                max(fullRegion.row, anchorRow - boxHeight / 2)
            }

            let boxCol = min(anchorCol, fullRegion.col + fullRegion.width - boxWidth)

            // Bounds check
            guard boxRow >= 0,
                  boxRow + boxHeight <= buffer.height,
                  boxCol >= 0,
                  boxCol + boxWidth <= buffer.width
            else { return }

            let border = BorderedView.BorderStyle.rounded

            // Draw border
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

            // Clear interior
            for r in (boxRow + 1) ..< (boxRow + boxHeight - 1) {
                for c in (boxCol + 1) ..< (boxCol + boxWidth - 1) {
                    buffer[r, c] = Cell(char: " ")
                }
            }

            // Render each menu item inside the border
            // Wrap each item's action to also close the menu
            var itemCtx = context
            itemCtx.buttonStyle = .plain

            for (i, item) in menuItems.enumerated() {
                let itemRegion = Region(
                    row: boxRow + 1 + i,
                    col: boxCol + 1,
                    width: contentWidth,
                    height: 1,
                )

                // Wrap the item in an OnKeyPressView to close on Escape
                if i == 0 {
                    let escHandler = OnKeyPressView(content: item) { key in
                        if key == .escape {
                            guard let store = itemCtx.focusStore else { return .ignored }
                            var state = store.controlState(
                                forKey: capturedKey,
                                as: FocusStore.ContextMenuState.self,
                            ) ?? FocusStore.ContextMenuState()
                            state.isOpen = false
                            store.setControlState(state, forKey: capturedKey)
                            return .handled
                        }
                        return .ignored
                    }
                    TextUI.render(escHandler, into: &buffer, region: itemRegion, context: itemCtx)
                } else {
                    TextUI.render(item, into: &buffer, region: itemRegion, context: itemCtx)
                }
            }
        })
    }
}
