/// The style of divider drawn below the tab bar in a ``TabView``.
///
/// Apply via ``View/tabDividerStyle(_:)``. The divider separates the
/// tab bar from the content area.
///
/// - ``none``: No divider — tabs float above content.
/// - ``middle``: Horizontal rule through the center of tab labels
///   (only effective at ``ControlSize/large``; degrades to ``bottom``
///   at smaller sizes).
/// - ``bottom``: Horizontal rule below tab labels (default).
public enum TabDividerStyle: Friendly {
    /// No horizontal rule between tabs and content.
    case none

    /// Rule through the center of tab labels (`.large` only; degrades to `.bottom`).
    case middle

    /// Rule below tab labels (default).
    case bottom
}
