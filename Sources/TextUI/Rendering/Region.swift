/// A rectangular sub-area within a ``Buffer``.
///
/// Regions define where views render into the buffer. They are passed down
/// through the layout tree so each child knows its allocated space.
public struct Region: Friendly {
    /// The top row (0-based) of this region within the buffer.
    public var row: Int

    /// The left column (0-based) of this region within the buffer.
    public var col: Int

    /// The width (number of columns) of this region.
    public var width: Int

    /// The height (number of rows) of this region.
    public var height: Int

    public init(row: Int, col: Int, width: Int, height: Int) {
        self.row = row
        self.col = col
        self.width = width
        self.height = height
    }

    /// Whether this region has any visible area.
    public var isEmpty: Bool {
        width <= 0 || height <= 0
    }

    /// Create a sub-region offset from this region's origin.
    ///
    /// The sub-region is clamped so it does not extend beyond this region's bounds.
    public func subregion(row: Int, col: Int, width: Int, height: Int) -> Region {
        Region(
            row: self.row + row,
            col: self.col + col,
            width: min(width, self.width - col),
            height: min(height, self.height - row),
        )
    }

    /// Inset this region by the given amounts.
    ///
    /// Width and height are clamped to a minimum of zero.
    public func inset(top: Int = 0, left: Int = 0, bottom: Int = 0, right: Int = 0) -> Region {
        Region(
            row: row + top,
            col: col + left,
            width: max(0, width - left - right),
            height: max(0, height - top - bottom),
        )
    }
}
