/// A visual separator line, either horizontal or vertical.
///
/// Dividers are created via the static properties ``horizontal``
/// and ``vertical``. A horizontal divider fills its available width
/// and is 1 row tall; a vertical divider fills its available height
/// and is 1 column wide.
///
/// ```swift
/// VStack {
///     Text("Above")
///     Divider.horizontal
///     Text("Below")
/// }
/// ```
public struct Divider: PrimitiveView {
    /// The orientation of this divider.
    let orientation: Orientation

    enum Orientation: Friendly {
        case horizontal
        case vertical
    }

    private init(_ orientation: Orientation) {
        self.orientation = orientation
    }

    /// A horizontal divider line (`─`) that fills the available width.
    public static let horizontal = Divider(.horizontal)

    /// A vertical divider line (`│`) that fills the available height.
    public static let vertical = Divider(.vertical)

    public func sizeThatFits(_ proposal: SizeProposal, context _: RenderContext) -> Size2D {
        switch orientation {
        case .horizontal:
            let w = proposal.width ?? 1
            return Size2D(width: w, height: 1)
        case .vertical:
            let h = proposal.height ?? 1
            return Size2D(width: 1, height: h)
        }
    }

    public func render(into buffer: inout Buffer, region: Region, context _: RenderContext) {
        guard !region.isEmpty else { return }
        switch orientation {
        case .horizontal:
            buffer.horizontalLine(
                row: region.row,
                col: region.col,
                length: region.width,
            )
        case .vertical:
            buffer.verticalLine(
                row: region.row,
                col: region.col,
                length: region.height,
            )
        }
    }
}
