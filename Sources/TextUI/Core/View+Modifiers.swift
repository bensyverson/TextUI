/// Modifier methods on ``View`` for building declarative view hierarchies.
///
/// Each method returns an opaque `some View` wrapping the original view
/// in a modifier. Modifiers can be chained:
///
/// ```swift
/// Text("Hello")
///     .padding(1)
///     .border(.rounded)
///     .background(.blue)
/// ```
public extension View {
    // MARK: - Padding

    /// Adds equal padding on all four sides.
    func padding(_ amount: Int) -> some View {
        PaddedView(content: self, top: amount, leading: amount, bottom: amount, trailing: amount)
    }

    /// Adds padding on specific edges.
    func padding(
        top: Int = 0,
        leading: Int = 0,
        bottom: Int = 0,
        trailing: Int = 0,
    ) -> some View {
        PaddedView(content: self, top: top, leading: leading, bottom: bottom, trailing: trailing)
    }

    /// Adds symmetric horizontal and vertical padding.
    func padding(horizontal: Int = 0, vertical: Int = 0) -> some View {
        PaddedView(content: self, top: vertical, leading: horizontal, bottom: vertical, trailing: horizontal)
    }

    // MARK: - Fixed Size

    /// Prevents the view from being compressed below its ideal size on both axes.
    func fixedSize() -> some View {
        FixedSizeView(content: self, horizontal: true, vertical: true)
    }

    /// Prevents compression on the specified axes.
    func fixedSize(horizontal: Bool = true, vertical: Bool = true) -> some View {
        FixedSizeView(content: self, horizontal: horizontal, vertical: vertical)
    }

    // MARK: - Hidden

    /// Hides the view while preserving its layout space.
    func hidden() -> some View {
        HiddenView(content: self)
    }

    // MARK: - Frame

    /// Sets an exact frame size for the view.
    ///
    /// `nil` dimensions pass through to the child unchanged.
    func frame(
        width: Int? = nil,
        height: Int? = nil,
        alignment: Alignment = .center,
    ) -> some View {
        FrameView(content: self, width: width, height: height, alignment: alignment)
    }

    /// Sets flexible frame constraints with min/max bounds.
    ///
    /// Use `.frame(maxWidth: .max)` to make a hugging view expand
    /// to fill its container.
    func frame(
        minWidth: Int? = nil,
        maxWidth: Int? = nil,
        minHeight: Int? = nil,
        maxHeight: Int? = nil,
        alignment: Alignment = .center,
    ) -> some View {
        FlexFrameView(
            content: self,
            minWidth: minWidth,
            maxWidth: maxWidth,
            minHeight: minHeight,
            maxHeight: maxHeight,
            alignment: alignment,
        )
    }

    // MARK: - Style

    /// Sets the foreground color for the view's content.
    func foregroundColor(_ color: Style.Color) -> some View {
        StyledView(content: self, styleOverride: Style(fg: color))
    }

    /// Makes the view's text bold.
    func bold() -> some View {
        StyledView(content: self, styleOverride: Style(bold: true))
    }

    /// Makes the view's text dim.
    func dim() -> some View {
        StyledView(content: self, styleOverride: Style(dim: true))
    }

    /// Makes the view's text italic.
    func italic() -> some View {
        StyledView(content: self, styleOverride: Style(italic: true))
    }

    /// Underlines the view's text.
    func underline() -> some View {
        StyledView(content: self, styleOverride: Style(underline: true))
    }

    /// Applies strikethrough to the view's text.
    func strikethrough() -> some View {
        StyledView(content: self, styleOverride: Style(strikethrough: true))
    }

    /// Applies inverse video to the view's text.
    func inverse() -> some View {
        StyledView(content: self, styleOverride: Style(inverse: true))
    }

    /// Applies a complete style override to the view.
    func style(_ style: Style) -> some View {
        StyledView(content: self, styleOverride: style)
    }

    // MARK: - Background

    /// Fills the view's region with a background color.
    ///
    /// Cells where the child has already set a background color
    /// are not overwritten.
    func background(_ color: Style.Color) -> some View {
        BackgroundView(content: self, color: color)
    }

    // MARK: - Overlay

    /// Renders additional content on top of this view.
    func overlay(@ViewBuilder _ content: () -> ViewGroup) -> some View {
        OverlayView(content: self, overlay: content())
    }

    // MARK: - Border

    /// Draws a box-drawing border around the view.
    ///
    /// Adds 2 to both width and height (1 cell per side).
    func border(_ style: BorderedView.BorderStyle = .rounded) -> some View {
        BorderedView(content: self, borderStyle: style)
    }

    // MARK: - Layout Priority

    /// Sets the layout priority for stack distribution.
    ///
    /// Higher-priority children receive space before lower-priority ones.
    /// The default priority is `0`.
    func layoutPriority(_ priority: Double) -> some View {
        PrioritizedView(content: self, priority: priority)
    }

    // MARK: - Environment

    /// Injects an environment object into the view hierarchy.
    ///
    /// Descendant views can access this object using the
    /// ``EnvironmentObject`` property wrapper.
    ///
    /// ```swift
    /// MyView()
    ///     .environmentObject(appState)
    /// ```
    func environmentObject(_ object: some AnyObject & Sendable) -> some View {
        EnvironmentObjectView(content: self, object: object)
    }
}
