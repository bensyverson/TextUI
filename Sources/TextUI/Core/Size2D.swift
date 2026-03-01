/// A two-dimensional size measured in terminal cells.
///
/// Used throughout the layout system to represent both proposed
/// and actual sizes. Width counts columns, height counts rows.
public struct Size2D: Friendly {
    /// The number of columns.
    public var width: Int

    /// The number of rows.
    public var height: Int

    public init(width: Int, height: Int) {
        self.width = width
        self.height = height
    }

    /// A zero-sized value: no columns, no rows.
    public static let zero = Size2D(width: 0, height: 0)
}
