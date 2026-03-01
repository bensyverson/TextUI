/// The visual style for a ``ProgressView``.
///
/// - ``compact``: A single-character indicator (spinner or block).
/// - ``bar(showPercent:)``: A horizontal bar with optional percentage.
public enum ProgressViewStyle: Friendly {
    /// A single-character indicator.
    ///
    /// For indeterminate progress, displays a spinning braille character.
    /// For determinate progress, displays a block character representing
    /// the fill level.
    case compact

    /// A horizontal bar that fills from left to right.
    ///
    /// - Parameter showPercent: Whether to display the percentage at the end.
    case bar(showPercent: Bool = true)
}
