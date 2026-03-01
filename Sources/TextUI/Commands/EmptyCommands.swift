/// A default commands type that produces no command groups.
///
/// Used as the default value for ``App/commands`` when an app
/// does not define any commands.
public struct EmptyCommands: Sendable {
    /// The empty list of command groups.
    public let groups: [CommandGroup] = []

    /// Creates an empty commands value.
    public init() {}
}
