/// A size proposal from parent to child during layout negotiation.
///
/// Each dimension is optional, conveying different intent:
/// - `nil` — ask for the child's **ideal** size
/// - `0` — ask for the child's **minimum** size
/// - `.max` — ask for the child's **maximum** size
/// - A concrete value — offer that many cells
public struct SizeProposal: Friendly {
    /// The proposed width in columns, or `nil` to request ideal width.
    public var width: Int?

    /// The proposed height in rows, or `nil` to request ideal height.
    public var height: Int?

    public init(width: Int?, height: Int?) {
        self.width = width
        self.height = height
    }

    /// Ask for the child's ideal size on both axes.
    public static let unspecified = SizeProposal(width: nil, height: nil)

    /// Ask for the child's minimum size on both axes.
    public static let zero = SizeProposal(width: 0, height: 0)

    /// Ask for the child's maximum size on both axes.
    public static let max = SizeProposal(width: .max, height: .max)

    /// Returns a new proposal with both dimensions reduced by the given amounts.
    ///
    /// `nil` dimensions remain `nil`. Concrete dimensions are clamped to zero.
    public func inset(horizontal: Int = 0, vertical: Int = 0) -> SizeProposal {
        SizeProposal(
            width: width.map { Swift.max(0, $0 - horizontal) },
            height: height.map { Swift.max(0, $0 - vertical) },
        )
    }

    /// Returns a new proposal where `nil` dimensions are replaced with defaults.
    public func replacingUnspecified(width: Int = 0, height: Int = 0) -> SizeProposal {
        SizeProposal(
            width: self.width ?? width,
            height: self.height ?? height,
        )
    }
}
