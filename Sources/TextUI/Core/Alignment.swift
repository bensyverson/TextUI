/// A combined horizontal and vertical alignment for positioning
/// a child within a larger container.
///
/// Used by ``FrameView``, ``FlexFrameView``, ``ZStack``, and other
/// container views that need to align a smaller child within a larger region.
///
/// ```swift
/// Text("Centered").frame(width: 20, height: 5, alignment: .center)
/// ```
public struct Alignment: Friendly {
    /// The horizontal component of the alignment.
    public let horizontal: HorizontalAlignment

    /// The vertical component of the alignment.
    public let vertical: VerticalAlignment

    /// Creates an alignment with the given horizontal and vertical components.
    public init(horizontal: HorizontalAlignment, vertical: VerticalAlignment) {
        self.horizontal = horizontal
        self.vertical = vertical
    }

    // MARK: - Static Constants

    /// Align to the top-leading corner.
    public static let topLeading = Alignment(horizontal: .leading, vertical: .top)

    /// Align to the top center.
    public static let top = Alignment(horizontal: .center, vertical: .top)

    /// Align to the top-trailing corner.
    public static let topTrailing = Alignment(horizontal: .trailing, vertical: .top)

    /// Align to the center-leading edge.
    public static let leading = Alignment(horizontal: .leading, vertical: .center)

    /// Align to the center.
    public static let center = Alignment(horizontal: .center, vertical: .center)

    /// Align to the center-trailing edge.
    public static let trailing = Alignment(horizontal: .trailing, vertical: .center)

    /// Align to the bottom-leading corner.
    public static let bottomLeading = Alignment(horizontal: .leading, vertical: .bottom)

    /// Align to the bottom center.
    public static let bottom = Alignment(horizontal: .center, vertical: .bottom)

    /// Align to the bottom-trailing corner.
    public static let bottomTrailing = Alignment(horizontal: .trailing, vertical: .bottom)

    // MARK: - Offset Computation

    /// Computes the (row, col) offset for a child of `childSize`
    /// within a container of `containerSize`.
    ///
    /// The offset positions the child according to this alignment.
    /// Values are clamped to zero so the child never goes outside the container.
    func offset(child childSize: Size2D, in containerSize: Size2D) -> (row: Int, col: Int) {
        let col: Int = switch horizontal {
        case .leading: 0
        case .center: max(0, (containerSize.width - childSize.width) / 2)
        case .trailing: max(0, containerSize.width - childSize.width)
        }
        let row: Int = switch vertical {
        case .top: 0
        case .center: max(0, (containerSize.height - childSize.height) / 2)
        case .bottom: max(0, containerSize.height - childSize.height)
        }
        return (row, col)
    }
}
