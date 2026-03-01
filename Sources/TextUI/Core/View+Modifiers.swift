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

    // MARK: - Focus

    /// Binds this view to a focus value for programmatic focus management.
    ///
    /// When the binding's value matches `value`, this view is focused.
    /// Setting the binding programmatically moves focus.
    ///
    /// ```swift
    /// @FocusState var focus: Field?
    ///
    /// TextField("Name", text: $name)
    ///     .focused($focus, equals: .name)
    /// ```
    func focused<Value: Hashable & Sendable>(
        _: FocusState<Value?>.Binding,
        equals value: Value,
    ) -> some View {
        FocusedView(content: self, bindingKey: AnyHashable(value))
    }

    /// Groups focusable descendants into a focus section.
    ///
    /// Arrow key navigation is constrained to controls within the
    /// same section.
    func focusSection() -> some View {
        FocusSectionView(content: self)
    }

    /// Sets the default focus target for the first frame.
    ///
    /// On the first render pass, the focus system will focus the entry
    /// matching `value` instead of the first entry in the ring.
    func defaultFocus<Value: Hashable & Sendable>(
        _: FocusState<Value?>.Binding,
        _ value: Value,
    ) -> some View {
        DefaultFocusView(content: self, targetKey: AnyHashable(value))
    }

    /// Intercepts key events for focusable descendants.
    ///
    /// Return `.handled` to consume the event or `.ignored` to
    /// let it propagate.
    func onKeyPress(
        _ handler: @escaping @Sendable (KeyEvent) -> KeyEventResult,
    ) -> some View {
        OnKeyPressView(content: self, handler: handler)
    }

    /// Handles submit (Enter) events from `.edit` controls.
    ///
    /// Fires when a focused ``TextField`` receives Enter and no
    /// inline handler consumes it.
    func onSubmit(
        _ handler: @escaping @Sendable () -> Void,
    ) -> some View {
        OnSubmitView(content: self, handler: handler)
    }

    // MARK: - Progress View Style

    /// Sets the style for descendant ``ProgressView`` instances.
    ///
    /// ```swift
    /// ProgressView(value: 0.5)
    ///     .progressViewStyle(.compact)
    /// ```
    func progressViewStyle(_ style: ProgressViewStyle) -> some View {
        ProgressViewStyleView(content: self, style: style)
    }

    // MARK: - Keyboard Shortcuts

    /// Attaches a keyboard shortcut to this view.
    ///
    /// Used inside ``CommandGroup`` to associate shortcuts with buttons:
    ///
    /// ```swift
    /// Button("Save") { save() }
    ///     .keyboardShortcut("s", modifiers: .control)
    /// ```
    func keyboardShortcut(
        _ key: KeyEquivalent,
        modifiers: EventModifiers = [],
    ) -> some View {
        KeyboardShortcutView(
            content: self,
            shortcut: KeyboardShortcut(key, modifiers: modifiers),
        )
    }

    /// Attaches a keyboard shortcut from a character to this view.
    func keyboardShortcut(
        _ char: Character,
        modifiers: EventModifiers = [],
    ) -> some View {
        KeyboardShortcutView(
            content: self,
            shortcut: KeyboardShortcut(char, modifiers: modifiers),
        )
    }

    /// Attaches a pre-built keyboard shortcut to this view.
    func keyboardShortcut(_ shortcut: KeyboardShortcut) -> some View {
        KeyboardShortcutView(content: self, shortcut: shortcut)
    }

    // MARK: - Task

    /// Runs an async task when the view first appears in the tree.
    ///
    /// The task is automatically cancelled when the view is removed.
    /// Use this to perform async work scoped to a view's lifetime:
    ///
    /// ```swift
    /// ScrollView {
    ///     ForEach(items) { item in Text(item.name) }
    /// }
    /// .task {
    ///     for await batch in stream {
    ///         items.append(contentsOf: batch)
    ///     }
    /// }
    /// ```
    func task(
        fileID: String = #fileID,
        line: Int = #line,
        _ action: @escaping @MainActor @Sendable () async -> Void,
    ) -> some View {
        TaskView(content: self, action: action, key: "\(fileID):\(line)")
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
