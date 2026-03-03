/// A modifier view that overlays modal content on a dimmed background.
///
/// When `isPresented` is `true`, the background content is rendered with
/// focus suppressed and dim styling, and the modal body is centered on
/// top with full focus registration. When `isPresented` is `false`, the
/// background passes through unchanged.
///
/// Applied via ``View/modal(isPresented:onDismiss:content:)``.
///
/// ```swift
/// ContentView()
///     .modal(isPresented: state.showConfirm, onDismiss: { state.showConfirm = false }) {
///         VStack {
///             Text("Are you sure?")
///             HStack {
///                 Button("Cancel") { state.showConfirm = false }
///                 Button("Confirm") { confirm() }
///             }
///         }
///         .border(.rounded)
///         .padding(1)
///     }
/// ```
struct ModalView: PrimitiveView, @unchecked Sendable {
    /// The content rendered behind the modal.
    let background: any View

    /// Whether the modal is currently visible.
    let isPresented: Bool

    /// Called when Escape is pressed while the modal is shown. If `nil`,
    /// Escape is not intercepted.
    let onDismiss: (@Sendable () -> Void)?

    /// The modal body content.
    let body: any View

    func sizeThatFits(_ proposal: SizeProposal, context: RenderContext) -> Size2D {
        // Modal doesn't affect layout — return background size.
        TextUI.sizeThatFits(background, proposal: proposal, context: context)
    }

    func render(into buffer: inout Buffer, region: Region, context: RenderContext) {
        guard isPresented else {
            TextUI.render(background, into: &buffer, region: region, context: context)
            return
        }

        // Step 1: Render background with focus suppressed.
        var disabledCtx = context
        disabledCtx.isDisabled = true
        TextUI.render(background, into: &buffer, region: region, context: disabledCtx)

        // Step 2: Apply dim scrim to all background cells.
        applyDim(to: &buffer, region: region)

        // Step 3: Measure modal body.
        let proposal = SizeProposal(width: region.width, height: region.height)
        let modalSize = TextUI.sizeThatFits(body, proposal: proposal, context: context)

        // Step 4: Center the modal within the region.
        let modalCol = region.col + max(0, (region.width - modalSize.width) / 2)
        let modalRow = region.row + max(0, (region.height - modalSize.height) / 2)
        let modalRegion = Region(
            row: modalRow,
            col: modalCol,
            width: modalSize.width,
            height: modalSize.height,
        )

        // Step 5: Clear modal area so body renders on a clean surface.
        buffer.fill(modalRegion)

        // Step 6: Render modal body with original context (focus enabled).
        if let onDismiss {
            let escapeHandler = OnKeyPressView(content: body) { key in
                if key == .escape {
                    onDismiss()
                    return .handled
                }
                return .ignored
            }
            TextUI.render(escapeHandler, into: &buffer, region: modalRegion, context: context)
        } else {
            TextUI.render(body, into: &buffer, region: modalRegion, context: context)
        }
    }

    /// Applies dim styling to every cell in the given region.
    private func applyDim(to buffer: inout Buffer, region: Region) {
        let dimStyle = Style(dim: true)
        for r in region.row ..< min(region.row + region.height, buffer.height) {
            for c in region.col ..< min(region.col + region.width, buffer.width) {
                guard r >= 0, c >= 0 else { continue }
                guard !buffer[r, c].isContinuation else { continue }
                buffer[r, c].style = buffer[r, c].style.merging(dimStyle)
            }
        }
    }
}
