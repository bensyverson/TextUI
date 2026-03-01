/// A single command extracted from a ``CommandGroup``.
///
/// Each entry represents a named action with an optional keyboard shortcut,
/// suitable for display in a ``CommandBar`` or command palette.
public struct CommandEntry: Sendable {
    /// The display name of the command.
    public let name: String

    /// The group this command belongs to.
    public let group: String

    /// The keyboard shortcut for this command, if any.
    public let shortcut: KeyboardShortcut?

    /// The action to perform when this command is invoked.
    public let action: @Sendable () -> Void
}
