/// A registry of all command groups and their entries.
///
/// Created by ``RunLoop`` and threaded through ``RenderContext``.
/// The registry enables shortcut matching during key event handling
/// and provides command data for ``CommandBar`` and command palettes.
final class CommandRegistry: @unchecked Sendable {
    /// The registered command groups with their entries.
    private(set) var groups: [(name: String, entries: [CommandEntry])] = []

    /// Whether the command palette overlay is currently visible.
    var isPaletteVisible: Bool = false

    /// The current filter text in the command palette.
    var filterText: String = ""

    /// The currently selected index in the command palette.
    var selectedIndex: Int = 0

    /// The entries matching the current filter text.
    ///
    /// Returns all entries when the filter is empty. Otherwise, performs
    /// a case-insensitive substring match on entry names.
    var filteredEntries: [CommandEntry] {
        let query = filterText.lowercased()
        guard !query.isEmpty else { return allEntries }
        return allEntries.filter { $0.name.lowercased().contains(query) }
    }

    /// Resets palette state to defaults (empty filter, first item selected).
    func resetPaletteState() {
        filterText = ""
        selectedIndex = 0
    }

    /// All command entries across all groups.
    var allEntries: [CommandEntry] {
        groups.flatMap(\.entries)
    }

    /// Registers command groups, replacing any existing groups.
    func register(_ commandGroups: [CommandGroup]) {
        groups = commandGroups.map { (name: $0.name, entries: $0.entries) }
    }

    /// Returns the first command entry whose shortcut matches the given key event.
    ///
    /// Groups are searched in registration order. Within a group, entries
    /// are searched in declaration order. The first match wins.
    func matchShortcut(_ event: KeyEvent) -> CommandEntry? {
        for group in groups {
            for entry in group.entries {
                if let shortcut = entry.shortcut, shortcut.matches(event) {
                    return entry
                }
            }
        }
        return nil
    }
}
