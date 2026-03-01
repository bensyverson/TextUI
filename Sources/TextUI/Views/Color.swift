/// A view that fills its proposed region with a solid color.
///
/// `Color` is a greedy view: it expands to fill all available space.
/// Commonly used as a background in a ``ZStack``.
///
/// ```swift
/// ZStack {
///     Color(.blue)
///     Text("Hello")
/// }
/// ```
public struct Color: PrimitiveView, Sendable {
    /// The color to fill with.
    let color: Style.Color

    /// Creates a solid color view.
    public init(_ color: Style.Color) {
        self.color = color
    }

    public func sizeThatFits(_ proposal: SizeProposal) -> Size2D {
        // Greedy: fill all proposed space, ideal size is zero
        Size2D(
            width: proposal.width ?? 0,
            height: proposal.height ?? 0,
        )
    }

    public func render(into buffer: inout Buffer, region: Region) {
        buffer.fill(region, style: Style(bg: color))
    }
}
