/// An escape-hatch view for custom drawing directly into the buffer.
///
/// `Canvas` is greedy — it expands to fill its proposed size on both axes.
/// When queried for its ideal size (`nil` proposal), it returns `0×0`,
/// so it must be given a concrete size via its parent or a `.frame()` modifier.
///
/// The draw closure receives a mutable ``Buffer`` and the ``Region`` allocated
/// to the canvas. Use ``Buffer/write(_:row:col:style:)`` to place styled
/// characters at specific positions.
///
/// ```swift
/// Canvas { buffer, region in
///     for col in region.col ..< region.col + region.width {
///         buffer[region.row, col] = Cell("━", style: Style(fg: .cyan))
///     }
///     buffer.write("✦", row: region.row, col: region.col, style: .bold)
/// }
/// .frame(height: 1)
/// ```
///
/// Common use cases include custom decorative elements, sparkline charts,
/// progress indicators with non-standard visuals, and box-drawing art that
/// goes beyond what ``Text`` and ``Divider`` provide.
public struct Canvas: PrimitiveView {
    /// The custom drawing closure.
    let draw: (inout Buffer, Region) -> Void

    /// Creates a canvas with the given drawing closure.
    public init(draw: @escaping (inout Buffer, Region) -> Void) {
        self.draw = draw
    }

    public func sizeThatFits(_ proposal: SizeProposal, context _: RenderContext) -> Size2D {
        // Greedy: fill proposed space
        Size2D(
            width: proposal.width ?? 0,
            height: proposal.height ?? 0,
        )
    }

    public func render(into buffer: inout Buffer, region: Region, context _: RenderContext) {
        draw(&buffer, region)
    }
}
