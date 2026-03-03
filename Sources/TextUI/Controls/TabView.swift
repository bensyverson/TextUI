/// A container that switches between multiple content views using a tab bar.
///
/// TabView renders a 1-row tab bar at the top with content below. The tab bar
/// is focusable and responds to Left/Right arrow keys to switch tabs. The
/// selected tab's content fills the remaining space.
///
/// ```swift
/// TabView {
///     TabView.Tab("Home") {
///         Text("Welcome!")
///     }
///     TabView.Tab("Settings") {
///         Text("Preferences")
///     }
/// }
/// ```
///
/// The selected tab is highlighted with inverse styling. The tab bar and
/// content area are in separate focus sections.
public struct TabView: PrimitiveView {
    /// The tab definitions (label + content).
    let tabs: [Tab]

    /// Auto-generated key for focus registration and state persistence.
    let autoKey: String

    /// A single tab within a ``TabView``.
    public struct Tab {
        /// The display label for this tab.
        let label: String

        /// The content view displayed when this tab is selected.
        let content: any View

        /// Creates a tab with a label and content.
        ///
        /// - Parameters:
        ///   - label: The text shown in the tab bar.
        ///   - content: A ``ViewBuilder`` closure producing the tab's content.
        public init(_ label: String, @ViewBuilder content: () -> ViewGroup) {
            self.label = label
            self.content = content()
        }
    }

    /// Creates a tab view with the given tabs.
    ///
    /// - Parameters:
    ///   - fileID: Auto-captured file ID for stable identity.
    ///   - line: Auto-captured line number for stable identity.
    ///   - content: A ``TabBuilder`` closure producing the tabs.
    public init(
        fileID: String = #fileID,
        line: Int = #line,
        @TabBuilder content: () -> [Tab],
    ) {
        tabs = content()
        autoKey = "\(fileID):\(line)"
    }

    /// Persistent tab selection state.
    struct TabState: Sendable {
        var selectedIndex: Int = 0
        var tabCount: Int = 0
    }

    // MARK: - Sizing

    public func sizeThatFits(_ proposal: SizeProposal, context _: RenderContext) -> Size2D {
        // Greedy on both axes
        let width = proposal.width ?? tabBarWidth
        let height = proposal.height ?? (1 + maxContentIdealHeight)
        return Size2D(width: width, height: height)
    }

    /// The natural width of the tab bar.
    private var tabBarWidth: Int {
        // "[ Tab1 │ Tab2 │ Tab3 ]"
        guard !tabs.isEmpty else { return 2 }
        let labelWidths = tabs.reduce(0) { $0 + $1.label.displayWidth }
        let padding = tabs.count * 2 // space before and after each label
        let separators = tabs.count - 1 // │ between tabs
        return 2 + labelWidths + padding + separators // [ and ]
    }

    /// The tallest ideal content height among all tabs.
    private var maxContentIdealHeight: Int {
        // Since we don't have context here, use a reasonable default
        1
    }

    // MARK: - Rendering

    public func render(into buffer: inout Buffer, region: Region, context: RenderContext) {
        guard !region.isEmpty, !tabs.isEmpty else { return }
        let store = context.focusStore

        // Read selected tab
        var state = store?.controlState(forKey: autoKey, as: TabState.self) ?? TabState()
        state.selectedIndex = max(0, min(state.selectedIndex, tabs.count - 1))
        state.tabCount = tabs.count
        store?.setControlState(state, forKey: autoKey)
        store?.tabViewKeys.append(AnyHashable(autoKey))
        let selectedIndex = state.selectedIndex

        // Register tab bar as focusable (skip if FocusedView already registered us)
        let tabBarRegion = region.subregion(row: 0, col: 0, width: region.width, height: 1)
        let effectiveFocusID: Int?
        let isFocused: Bool

        if let env = context.focusEnvironment {
            effectiveFocusID = env.focusID
            isFocused = env.isFocused
        } else {
            let focusID = store?.register(
                interaction: .activate,
                region: tabBarRegion,
                sectionID: context.currentFocusSectionID,
                bindingKey: nil,
                autoKey: AnyHashable(autoKey),
            )
            effectiveFocusID = focusID
            isFocused = focusID.flatMap { store?.isFocused($0) } ?? false
        }

        // Register inline handler for Left/Right tab switching
        if isFocused, let id = effectiveFocusID {
            store?.registerInlineHandler(for: id) { [autoKey, tabCount = tabs.count] key in
                guard let store else { return .ignored }
                var state = store.controlState(forKey: autoKey, as: TabState.self) ?? TabState()
                switch key {
                case .left:
                    state.selectedIndex = (state.selectedIndex - 1 + tabCount) % tabCount
                    store.setControlState(state, forKey: autoKey)
                    return .handled
                case .right:
                    state.selectedIndex = (state.selectedIndex + 1) % tabCount
                    store.setControlState(state, forKey: autoKey)
                    return .handled
                default:
                    return .ignored
                }
            }
        }

        // Render tab bar on row 0
        renderTabBar(
            into: &buffer,
            region: tabBarRegion,
            selectedIndex: selectedIndex,
            isFocused: isFocused,
        )

        // Render content area (row 1+)
        guard region.height > 1 else { return }
        let contentRegion = region.subregion(row: 1, col: 0, width: region.width, height: region.height - 1)

        // Create focus section for content
        var contentContext = context
        if let store {
            contentContext.currentFocusSectionID = store.nextSection()
        }

        TextUI.render(tabs[selectedIndex].content, into: &buffer, region: contentRegion, context: contentContext)
    }

    // MARK: - Tab Bar Rendering

    private func renderTabBar(
        into buffer: inout Buffer,
        region: Region,
        selectedIndex: Int,
        isFocused: Bool,
    ) {
        var col = region.col
        let row = region.row

        col += buffer.write("[", row: row, col: col)

        for (i, tab) in tabs.enumerated() {
            let isSelected = i == selectedIndex
            let style: Style = if isSelected, isFocused {
                Style(inverse: true)
            } else if isSelected {
                Style(bold: true)
            } else {
                .plain
            }

            col += buffer.write(" ", row: row, col: col, style: style)
            col += buffer.write(tab.label, row: row, col: col, style: style)
            col += buffer.write(" ", row: row, col: col, style: style)

            if i < tabs.count - 1 {
                col += buffer.write("│", row: row, col: col)
            }
        }

        col += buffer.write("]", row: row, col: col)
    }
}

/// Result builder for constructing arrays of ``TabView/Tab``.
@resultBuilder
public enum TabBuilder {
    /// Builds a block of tabs.
    public static func buildBlock(_ components: TabView.Tab...) -> [TabView.Tab] {
        Array(components)
    }

    /// Builds a tab array from a `for` loop.
    public static func buildArray(_ components: [[TabView.Tab]]) -> [TabView.Tab] {
        components.flatMap(\.self)
    }
}
