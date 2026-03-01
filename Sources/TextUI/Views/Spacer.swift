/// A flexible space that expands along the primary axis of its container.
///
/// In an ``HStack``, a spacer expands horizontally. In a ``VStack``,
/// it expands vertically. Outside a stack, it expands on both axes.
///
/// ```swift
/// HStack {
///     Text("left")
///     Spacer()
///     Text("right")
/// }
/// ```
public struct Spacer: PrimitiveView, Sendable {
    /// The minimum length the spacer occupies along its axis.
    public let minLength: Int

    /// The axis along which this spacer expands.
    ///
    /// Set by the containing stack via ``withAxis(_:)``.
    /// Defaults to `.both` (expands on both axes when outside a stack).
    let axis: Axis

    /// Creates a spacer with the given minimum length.
    ///
    /// - Parameter minLength: The minimum number of cells this spacer
    ///   occupies along its primary axis. Defaults to `0`.
    public init(minLength: Int = 0) {
        self.minLength = minLength
        axis = .both
    }

    /// Creates a copy of this spacer with the given axis.
    func withAxis(_ newAxis: Axis) -> Spacer {
        Spacer(minLength: minLength, axis: newAxis)
    }

    /// Internal initializer with explicit axis.
    private init(minLength: Int, axis: Axis) {
        self.minLength = minLength
        self.axis = axis
    }

    /// The axis along which a spacer can expand.
    enum Axis: Friendly {
        /// Expands horizontally (used in ``HStack``).
        case horizontal

        /// Expands vertically (used in ``VStack``).
        case vertical

        /// Expands on both axes (used outside a stack).
        case both
    }

    public func sizeThatFits(_ proposal: SizeProposal) -> Size2D {
        let w: Int
        let h: Int

        switch axis {
        case .horizontal:
            w = proposal.width.map { max($0, minLength) } ?? minLength
            h = 0
        case .vertical:
            w = 0
            h = proposal.height.map { max($0, minLength) } ?? minLength
        case .both:
            w = proposal.width.map { max($0, minLength) } ?? minLength
            h = proposal.height.map { max($0, minLength) } ?? minLength
        }

        return Size2D(width: w, height: h)
    }

    public func render(into _: inout Buffer, region _: Region) {
        // Spacers are invisible — nothing to render
    }
}
