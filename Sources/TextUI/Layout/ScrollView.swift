/// A vertically scrollable container that displays a viewport into its content.
///
/// ScrollView measures all children at their ideal height, then renders
/// only the visible portion based on the current scroll offset. It registers
/// itself as focusable so it appears in the focus ring and responds to
/// scroll keys (Up/Down/PageUp/PageDown/Home/End).
///
/// When a focusable child inside the ScrollView is focused, scroll keys
/// bubble up through the ancestor handler chain so the ScrollView still
/// scrolls.
///
/// ```swift
/// ScrollView {
///     ForEach(items) { item in
///         Text(item.name)
///     }
/// }
/// ```
///
/// An optional scroll indicator (a proportional thumb on a track) appears
/// on the right edge when content overflows the viewport.
public struct ScrollView: PrimitiveView, @unchecked Sendable {
    /// Whether to show the scroll indicator when content overflows.
    let showsIndicator: Bool

    /// The flattened children to scroll through.
    let children: [any View]

    /// Auto-generated key for focus registration and state persistence.
    let autoKey: String

    /// Creates a vertically scrollable container.
    ///
    /// - Parameters:
    ///   - showsIndicator: Whether to show a scroll indicator. Defaults to `true`.
    ///   - fileID: Auto-captured file ID for stable identity.
    ///   - line: Auto-captured line number for stable identity.
    ///   - content: A ``ViewBuilder`` closure producing the scrollable children.
    public init(
        showsIndicator: Bool = true,
        fileID: String = #fileID,
        line: Int = #line,
        @ViewBuilder content: () -> ViewGroup,
    ) {
        self.showsIndicator = showsIndicator
        let flat = StackLayout.flattenChildren(content().children)
        children = StackLayout.prepareChildren(flat, axis: .vertical)
        autoKey = "\(fileID):\(line)"
    }

    /// Persistent scroll state stored in ``FocusStore/controlState``.
    struct ScrollState: Sendable {
        var offset: Int = 0
    }

    // MARK: - Sizing

    public func sizeThatFits(_ proposal: SizeProposal, context: RenderContext) -> Size2D {
        guard !children.isEmpty else { return .zero }

        // Measure children at ideal height, with offered width
        let childProposal = SizeProposal(width: proposal.width, height: nil)
        var totalHeight = 0
        var maxWidth = 0
        for child in children {
            let size = TextUI.sizeThatFits(child, proposal: childProposal, context: context)
            totalHeight += size.height
            maxWidth = max(maxWidth, size.width)
        }

        // Greedy on height: take what's offered (or ideal sum if nil)
        let height: Int = if let proposed = proposal.height {
            proposed
        } else {
            totalHeight
        }

        // Width: hug to content
        let width: Int = if let proposed = proposal.width {
            min(maxWidth, proposed)
        } else {
            maxWidth
        }

        return Size2D(width: width, height: height)
    }

    // MARK: - Rendering

    public func render(into buffer: inout Buffer, region: Region, context: RenderContext) {
        guard !region.isEmpty else { return }
        let store = context.focusStore

        // Measure all children to get their ideal heights
        let contentWidth = showsIndicator ? max(0, region.width - 1) : region.width
        let childProposal = SizeProposal(width: contentWidth, height: nil)
        var childSizes: [Size2D] = []
        for child in children {
            childSizes.append(TextUI.sizeThatFits(child, proposal: childProposal, context: context))
        }

        // Build cumulative offset array
        var cumulativeOffsets = [0]
        for size in childSizes {
            cumulativeOffsets.append(cumulativeOffsets.last! + size.height)
        }
        let totalContentHeight = cumulativeOffsets.last!

        // Read scroll offset, clamp
        let viewportHeight = region.height
        let maxOffset = max(0, totalContentHeight - viewportHeight)
        var state = store?.controlState(forKey: autoKey, as: ScrollState.self) ?? ScrollState()
        state.offset = max(0, min(state.offset, maxOffset))
        store?.setControlState(state, forKey: autoKey)

        // Register as focusable
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

        // Build scroll handler
        let scrollHandler: @Sendable (KeyEvent) -> KeyEventResult = { [autoKey] key in
            guard let store else { return .ignored }
            var state = store.controlState(forKey: autoKey, as: ScrollState.self) ?? ScrollState()
            switch key {
            case .up: state.offset -= 1
            case .down: state.offset += 1
            case .pageUp: state.offset -= viewportHeight
            case .pageDown: state.offset += viewportHeight
            case .home: state.offset = 0
            case .end: state.offset = maxOffset
            default: return .ignored
            }
            state.offset = max(0, min(state.offset, maxOffset))
            store.setControlState(state, forKey: autoKey)
            return .handled
        }

        // Push scroll handler onto ancestor chain for child focus
        store?.pushKeyHandler(FocusStore.KeyHandler(handler: scrollHandler))

        // Create focus section for children
        var childContext = context
        if let store {
            childContext.currentFocusSectionID = store.nextSection()
        }

        // Render visible children
        let scrollOffset = state.offset
        for (i, child) in children.enumerated() {
            let childTop = cumulativeOffsets[i]
            let childHeight = childSizes[i].height
            let childBottom = childTop + childHeight

            // Skip children entirely above viewport
            if childBottom <= scrollOffset {
                continue
            }

            // Stop if we've passed the viewport
            if childTop >= scrollOffset + viewportHeight {
                break
            }

            // Calculate visible portion
            let visibleTop = max(childTop, scrollOffset)
            let visibleBottom = min(childBottom, scrollOffset + viewportHeight)
            let rowInRegion = visibleTop - scrollOffset

            // If the child starts above the viewport, skip rows from the top
            let skipRows = visibleTop - childTop
            let visibleHeight = visibleBottom - visibleTop

            if skipRows == 0 {
                // Fully visible from top (may be clipped at bottom)
                let childRegion = region.subregion(
                    row: rowInRegion,
                    col: 0,
                    width: contentWidth,
                    height: visibleHeight,
                )
                TextUI.render(child, into: &buffer, region: childRegion, context: childContext)
            } else {
                // Child is partially above viewport — render into a temp buffer
                // and copy the visible portion
                var tempBuffer = Buffer(width: contentWidth, height: childHeight)
                let tempRegion = Region(row: 0, col: 0, width: contentWidth, height: childHeight)
                TextUI.render(child, into: &tempBuffer, region: tempRegion, context: childContext)

                // Copy visible rows
                for r in 0 ..< visibleHeight {
                    let srcRow = skipRows + r
                    let dstRow = region.row + rowInRegion + r
                    for c in 0 ..< contentWidth {
                        let srcCell = tempBuffer[srcRow, c]
                        let dstCol = region.col + c
                        if dstRow >= 0, dstRow < buffer.height, dstCol >= 0, dstCol < buffer.width {
                            buffer[dstRow, dstCol] = srcCell
                        }
                    }
                }
            }
        }

        // Pop scroll handler
        store?.popKeyHandler()

        // Register inline handler when ScrollView itself is focused
        if isFocused, let id = focusID {
            store?.registerInlineHandler(for: id, handler: scrollHandler)
        }

        // Render scroll indicator
        if showsIndicator, totalContentHeight > viewportHeight {
            renderIndicator(
                into: &buffer,
                region: region,
                viewportHeight: viewportHeight,
                totalContentHeight: totalContentHeight,
                scrollOffset: scrollOffset,
            )
        }
    }

    // MARK: - Scroll Indicator

    /// Renders a scroll indicator on the right edge of the region.
    private func renderIndicator(
        into buffer: inout Buffer,
        region: Region,
        viewportHeight: Int,
        totalContentHeight: Int,
        scrollOffset: Int,
    ) {
        let indicatorCol = region.col + region.width - 1
        guard indicatorCol >= 0, indicatorCol < buffer.width else { return }

        // Draw track
        for r in 0 ..< viewportHeight {
            let row = region.row + r
            if row >= 0, row < buffer.height {
                buffer.write("│", row: row, col: indicatorCol)
            }
        }

        // Compute thumb position and size
        let thumbHeight = max(1, viewportHeight * viewportHeight / totalContentHeight)
        let thumbTop: Int = if totalContentHeight <= viewportHeight {
            0
        } else {
            scrollOffset * (viewportHeight - thumbHeight) / (totalContentHeight - viewportHeight)
        }

        for r in thumbTop ..< min(thumbTop + thumbHeight, viewportHeight) {
            let row = region.row + r
            if row >= 0, row < buffer.height {
                buffer.write("█", row: row, col: indicatorCol)
            }
        }
    }
}
