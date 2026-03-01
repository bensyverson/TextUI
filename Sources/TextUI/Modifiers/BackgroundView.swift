/// A view that fills its region with a background color.
///
/// Renders the child first, then sets the background color on all cells
/// where `bg` is still `nil`. This fills gaps (padding, empty space) while
/// preserving explicitly-set backgrounds from child views.
struct BackgroundView: PrimitiveView, Sendable {
    let content: any View
    let color: Style.Color

    func sizeThatFits(_ proposal: SizeProposal) -> Size2D {
        TextUI.sizeThatFits(content, proposal: proposal)
    }

    func render(into buffer: inout Buffer, region: Region) {
        TextUI.render(content, into: &buffer, region: region)
        for r in region.row ..< min(region.row + region.height, buffer.height) {
            for c in region.col ..< min(region.col + region.width, buffer.width) {
                guard r >= 0, c >= 0 else { continue }
                if buffer[r, c].style.bg == nil {
                    buffer[r, c].style.bg = color
                }
            }
        }
    }
}
