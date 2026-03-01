/// A view that post-processes rendered cells to apply style attributes.
///
/// The style is merged additively using ``Style/merging(_:)``:
/// `.bold()` adds bold without clearing existing foreground color,
/// `.foregroundColor(.red)` sets foreground without touching background.
struct StyledView: PrimitiveView, Sendable {
    let content: any View
    let styleOverride: Style

    func sizeThatFits(_ proposal: SizeProposal) -> Size2D {
        TextUI.sizeThatFits(content, proposal: proposal)
    }

    func render(into buffer: inout Buffer, region: Region) {
        TextUI.render(content, into: &buffer, region: region)
        for r in region.row ..< min(region.row + region.height, buffer.height) {
            for c in region.col ..< min(region.col + region.width, buffer.width) {
                guard r >= 0, c >= 0 else { continue }
                guard !buffer[r, c].isContinuation else { continue }
                buffer[r, c].style = buffer[r, c].style.merging(styleOverride)
            }
        }
    }
}
