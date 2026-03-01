/// An escape-hatch view for custom drawing directly into the buffer.
///
/// `Canvas` is greedy by default — it expands to fill its proposed size.
/// The draw closure receives the buffer and region for direct manipulation.
///
/// ```swift
/// Canvas { buffer, region in
///     buffer.write("Custom!", row: region.row, col: region.col)
/// }
/// ```
public struct Canvas: PrimitiveView, Sendable {
    /// The custom drawing closure.
    let draw: @Sendable (inout Buffer, Region) -> Void

    /// Creates a canvas with the given drawing closure.
    public init(draw: @escaping @Sendable (inout Buffer, Region) -> Void) {
        self.draw = draw
    }

    public func sizeThatFits(_ proposal: SizeProposal) -> Size2D {
        // Greedy: fill proposed space
        Size2D(
            width: proposal.width ?? 0,
            height: proposal.height ?? 0,
        )
    }

    public func render(into buffer: inout Buffer, region: Region) {
        draw(&buffer, region)
    }
}
