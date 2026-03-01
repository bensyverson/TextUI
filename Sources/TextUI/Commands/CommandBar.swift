/// A status bar view that displays available command shortcuts.
///
/// `CommandBar` reads the command registry from the render context
/// and renders each shortcut entry as `displayString name`, separated
/// by two-space gaps. Shortcuts render in bold, names in dim.
///
/// ```swift
/// VStack {
///     mainContent
///     CommandBar()
/// }
/// ```
///
/// Use the group-filtering initializer to show only specific groups:
///
/// ```swift
/// CommandBar(groups: ["File", "Edit"])
/// ```
public struct CommandBar: PrimitiveView, Sendable {
    /// The groups to display, or `nil` for all groups.
    let groups: [String]?

    /// Creates a command bar that displays all command groups.
    public init() {
        groups = nil
    }

    /// Creates a command bar that displays only the specified groups.
    public init(groups: [String]) {
        self.groups = groups
    }

    public func sizeThatFits(_ proposal: SizeProposal, context _: RenderContext) -> Size2D {
        // Height 1, greedy width
        let width = proposal.width ?? 0
        return Size2D(width: width, height: width > 0 ? 1 : 0)
    }

    public func render(into buffer: inout Buffer, region: Region, context: RenderContext) {
        guard !region.isEmpty else { return }
        let entries = filteredEntries(context: context)
        guard !entries.isEmpty else { return }

        var col = region.col
        let maxCol = region.col + region.width
        var isFirst = true

        for entry in entries {
            guard let shortcut = entry.shortcut else { continue }
            let display = shortcut.displayString
            let label = " \(entry.name)"
            let totalWidth = display.displayWidth + label.displayWidth
            let gap = isFirst ? 0 : 2

            // Check if the entire entry fits (truncate at entry boundary)
            guard col + gap + totalWidth <= maxCol else { break }

            col += gap

            // Render shortcut in bold/inverse
            let shortcutStyle = Style(bold: true, inverse: true)
            let consumed = buffer.write(display, row: region.row, col: col, style: shortcutStyle)
            col += consumed

            // Render name in dim
            let nameStyle = Style(dim: true)
            let nameConsumed = buffer.write(label, row: region.row, col: col, style: nameStyle)
            col += nameConsumed

            isFirst = false
        }
    }

    /// Returns entries filtered by group, if groups are specified.
    private func filteredEntries(context: RenderContext) -> [CommandEntry] {
        guard let registry = context.commandRegistry else { return [] }

        if let groups {
            let groupSet = Set(groups)
            return registry.groups
                .filter { groupSet.contains($0.name) }
                .flatMap(\.entries)
        }
        return registry.allEntries
    }
}
