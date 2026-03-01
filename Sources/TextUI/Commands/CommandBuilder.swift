/// A result builder for composing ``CommandGroup`` arrays.
///
/// ```swift
/// @CommandBuilder var commands: [CommandGroup] {
///     CommandGroup("File") { ... }
///     CommandGroup("Edit") { ... }
/// }
/// ```
@resultBuilder
public enum CommandBuilder {
    /// Builds a block from individual command groups.
    public static func buildBlock(_ groups: CommandGroup...) -> [CommandGroup] {
        Array(groups)
    }

    /// Builds an array from conditional or loop results.
    public static func buildArray(_ components: [[CommandGroup]]) -> [CommandGroup] {
        components.flatMap(\.self)
    }
}
