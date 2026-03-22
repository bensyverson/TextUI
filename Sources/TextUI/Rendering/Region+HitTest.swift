public extension Region {
    /// Returns whether the given position falls within this region.
    ///
    /// Both `row` and `column` are 0-based buffer coordinates.
    /// The check uses half-open intervals: the origin is inclusive,
    /// the boundary at `row + height` and `col + width` is exclusive.
    ///
    /// - Parameters:
    ///   - row: The 0-based row to test.
    ///   - column: The 0-based column to test.
    /// - Returns: `true` if the point is inside this region.
    func contains(row: Int, column: Int) -> Bool {
        row >= self.row && row < self.row + height &&
            column >= col && column < col + width
    }
}
