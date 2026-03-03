/// A named group of commands extracted from a declarative view builder.
///
/// `CommandGroup` walks the view tree produced by its `@ViewBuilder` closure,
/// looking for `Button(...).keyboardShortcut(...)` patterns to extract
/// command entries.
///
/// ```swift
/// CommandGroup("File") {
///     Button("Save") { save() }
///         .keyboardShortcut("s", modifiers: .control)
///     Button("Open") { open() }
///         .keyboardShortcut("o", modifiers: .control)
/// }
/// ```
@MainActor
public struct CommandGroup {
    /// The display name of this command group.
    public let name: String

    /// The command entries extracted from the group's content.
    public let entries: [CommandEntry]

    /// Creates a command group by extracting entries from a view builder closure.
    public init(_ name: String, @ViewBuilder content: () -> ViewGroup) {
        self.name = name
        entries = CommandGroup.extractEntries(
            from: content(),
            groupName: name,
        )
    }

    /// Creates a command group with pre-built entries (for testing).
    init(name: String, entries: [CommandEntry]) {
        self.name = name
        self.entries = entries
    }

    /// Extracts command entries from a view group's children.
    ///
    /// Walks the flattened children looking for `KeyboardShortcutView(Button(...))`
    /// or bare `Button(...)` patterns.
    static func extractEntries(
        from group: ViewGroup,
        groupName: String,
    ) -> [CommandEntry] {
        var entries: [CommandEntry] = []
        for child in StackLayout.flattenChildren(group.children) {
            var shortcut: KeyboardShortcut?
            var view: any View = child

            // Unwrap KeyboardShortcutView if present
            if let ksv = view as? KeyboardShortcutView {
                shortcut = ksv.shortcut
                view = ksv.content
            }

            // Extract Button
            if let button = view as? Button {
                let name = (button.label as? Text)?.content ?? "Command"
                entries.append(CommandEntry(
                    name: name,
                    group: groupName,
                    shortcut: shortcut,
                    action: button.action,
                ))
            }
        }
        return entries
    }
}
