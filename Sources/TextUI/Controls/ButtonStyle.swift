/// The visual style for a ``Button``.
///
/// - ``plain``: Label text only, inverse when focused. The default.
/// - ``bordered``: Label inside a rounded border, inverse when focused.
/// - ``borderedProminent``: Bold label inside a rounded border, inverse when focused.
public enum ButtonStyle: Friendly {
    /// Label text only, inverse when focused. The default.
    case plain
    /// Label inside a rounded border, inverse when focused.
    case bordered
    /// Bold label inside a rounded border, inverse when focused.
    case borderedProminent
}
