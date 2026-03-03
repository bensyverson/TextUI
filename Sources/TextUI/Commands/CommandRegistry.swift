/// A registry of all command groups and their entries.
///
/// Created by ``RunLoop`` and threaded through ``RenderContext``.
/// The registry enables shortcut matching during key event handling
/// and provides command data for ``CommandBar`` and command palettes.
@MainActor
final class CommandRegistry {
    /// The registered command groups with their entries.
    private(set) var groups: [(name: String, entries: [CommandEntry])] = []

    /// Shortcuts discovered during the current render frame.
    ///
    /// Populated by ``KeyboardShortcutView`` when it wraps a `Button`.
    /// Cleared each frame via ``beginDiscovery()``.
    private(set) var discoveredEntries: [CommandEntry] = []

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

    /// All command entries across all groups, plus discovered shortcuts.
    var allEntries: [CommandEntry] {
        groups.flatMap(\.entries) + discoveredEntries
    }

    /// Registers command groups, replacing any existing groups.
    func register(_ commandGroups: [CommandGroup]) {
        groups = commandGroups.map { (name: $0.name, entries: $0.entries) }
    }

    /// Returns the first command entry whose shortcut matches the given key event.
    ///
    /// Static command groups are searched first (in registration order),
    /// then discovered shortcuts from the current frame. The first match wins.
    func matchShortcut(_ event: KeyEvent) -> CommandEntry? {
        for group in groups {
            for entry in group.entries {
                if let shortcut = entry.shortcut, shortcut.matches(event) {
                    return entry
                }
            }
        }
        for entry in discoveredEntries {
            if let shortcut = entry.shortcut, shortcut.matches(event) {
                return entry
            }
        }
        return nil
    }

    /// Clears discovered shortcuts in preparation for the next render frame.
    ///
    /// Called at the start of each frame so that shortcuts stay in sync
    /// with the currently rendered view tree.
    func beginDiscovery() {
        discoveredEntries.removeAll()
    }

    /// Registers a shortcut discovered during the render pass.
    ///
    /// Called by ``KeyboardShortcutView`` when its content is a `Button`.
    func registerDiscoveredShortcut(
        name: String,
        group: String,
        shortcut: KeyboardShortcut,
        action: @escaping () -> Void,
    ) {
        discoveredEntries.append(CommandEntry(
            name: name,
            group: group,
            shortcut: shortcut,
            action: action,
        ))
    }
}
