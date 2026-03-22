/// A parsed mouse event from the terminal.
///
/// Represents mouse interactions including clicks, releases, and scroll wheel
/// actions parsed from SGR extended mouse mode escape sequences.
///
/// Coordinates are 0-based, matching ``Region``'s coordinate system.
/// The terminal sends 1-based coordinates which are converted during parsing.
///
/// ```swift
/// let event = MouseEvent(
///     button: .left,
///     kind: .press,
///     column: 10,
///     row: 5,
///     modifiers: []
/// )
/// ```
public struct MouseEvent: Friendly {
    /// The mouse button involved in the event.
    public enum Button: Int, Friendly {
        /// Left mouse button.
        case left = 0

        /// Middle mouse button.
        case middle = 1

        /// Right mouse button.
        case right = 2

        /// Scroll wheel up.
        case scrollUp = 64

        /// Scroll wheel down.
        case scrollDown = 65
    }

    /// Whether the button was pressed or released.
    public enum Kind: Friendly {
        /// The button was pressed down.
        case press

        /// The button was released.
        case release
    }

    /// The button that triggered the event.
    public var button: Button

    /// Whether this is a press or release.
    public var kind: Kind

    /// The column where the event occurred (0-based).
    public var column: Int

    /// The row where the event occurred (0-based).
    public var row: Int

    /// Modifier keys held during the event.
    public var modifiers: EventModifiers
}
