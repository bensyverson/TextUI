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

    /// Adds 1 cell of padding on all four sides.
    func padding() -> some View {
        PaddedView(content: self, top: 1, leading: 1, bottom: 1, trailing: 1)
    }

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
        _ handler: @escaping (KeyEvent) -> KeyEventResult,
    ) -> some View {
        OnKeyPressView(content: self, handler: handler)
    }

    /// Handles submit (Enter) events from `.edit` controls.
    ///
    /// Fires when a focused ``TextField`` receives Enter and no
    /// inline handler consumes it.
    func onSubmit(
        _ handler: @escaping () -> Void,
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

    // MARK: - Scroll Anchor

    /// Sets the default scroll anchor for descendant ``ScrollView`` instances.
    ///
    /// When set to ``VerticalAlignment/bottom``, a ScrollView will start
    /// at the bottom and automatically follow new content as it's added —
    /// unless the user has scrolled away from the bottom.
    ///
    /// ```swift
    /// ScrollView {
    ///     ForEach(logEntries) { entry in
    ///         Text(entry.message)
    ///     }
    /// }
    /// .defaultScrollAnchor(.bottom)
    /// ```
    func defaultScrollAnchor(_ anchor: VerticalAlignment) -> some View {
        DefaultScrollAnchorView(content: self, anchor: anchor)
    }

    // MARK: - Line Limit

    /// Sets the maximum number of lines for descendant ``Text`` views.
    ///
    /// Pass `nil` to remove any previously set limit.
    ///
    /// ```swift
    /// Text("A long paragraph…")
    ///     .lineLimit(3)
    /// ```
    func lineLimit(_ limit: Int?) -> some View {
        LineLimitView(content: self, limit: limit)
    }

    // MARK: - Truncation Mode

    /// Sets the truncation mode for descendant ``Text`` views.
    ///
    /// Controls where the ellipsis appears when text is truncated.
    ///
    /// ```swift
    /// Text("Hello, world!")
    ///     .lineLimit(1)
    ///     .truncationMode(.middle)
    /// ```
    func truncationMode(_ mode: Text.TruncationMode) -> some View {
        TruncationModeView(content: self, mode: mode)
    }

    // MARK: - Multiline Text Alignment

    /// Sets the alignment for wrapped lines in descendant ``Text`` views.
    ///
    /// ```swift
    /// Text("A paragraph that wraps…")
    ///     .multilineTextAlignment(.center)
    /// ```
    func multilineTextAlignment(_ alignment: HorizontalAlignment) -> some View {
        MultilineTextAlignmentView(content: self, alignment: alignment)
    }

    // MARK: - Button Style

    /// Sets the style for descendant ``Button`` instances.
    ///
    /// ```swift
    /// Button("Submit") { send() }
    ///     .buttonStyle(.bordered)
    /// ```
    func buttonStyle(_ style: ButtonStyle) -> some View {
        ButtonStyleView(content: self, style: style)
    }

    // MARK: - Animating

    /// Marks this view as animating, keeping the animation timer alive.
    ///
    /// Views that read ``AnimationTick`` should apply this modifier to
    /// signal the run loop that the animation timer should run while
    /// this view is visible. Reading the tick alone does not start the
    /// timer — this modifier provides explicit lifecycle control.
    ///
    /// ```swift
    /// Text(frames[tick % frames.count])
    ///     .animating()
    /// ```
    ///
    /// Pass `false` to conditionally disable animation:
    /// ```swift
    /// Text(frames[tick % frames.count])
    ///     .animating(shouldAnimate)
    /// ```
    func animating(_ isActive: Bool = true) -> some View {
        AnimatingView(content: self, isActive: isActive)
    }

    // MARK: - Disabled

    /// Disables interactive controls in this view's subtree.
    ///
    /// When `isDisabled` is `true`, descendant controls skip focus
    /// registration and cannot receive input. The content is rendered
    /// with dim styling.
    ///
    /// ```swift
    /// Button("Submit") { send() }
    ///     .disabled(isLoading)
    /// ```
    func disabled(_ isDisabled: Bool) -> some View {
        DisabledView(content: self, isDisabled: isDisabled)
    }

    // MARK: - Modal

    /// Presents a modal overlay centered on this view with a dimmed background.
    ///
    /// When `isPresented` is `true`, the receiver's controls are disabled
    /// and dimmed, and `content` is rendered centered on top with full
    /// focus registration. The user adds their own chrome (border, padding,
    /// background) to the modal body.
    ///
    /// ```swift
    /// ContentView()
    ///     .modal(isPresented: state.showConfirm, onDismiss: { state.showConfirm = false }) {
    ///         VStack {
    ///             Text("Are you sure?")
    ///             HStack {
    ///                 Button("Cancel") { state.showConfirm = false }
    ///                 Button("Confirm") { confirm() }
    ///             }
    ///         }
    ///         .border(.rounded)
    ///         .padding(1)
    ///     }
    /// ```
    ///
    /// - Parameters:
    ///   - isPresented: Controls whether the modal is visible.
    ///   - onDismiss: Called when Escape is pressed; pass `nil` to not
    ///     intercept Escape.
    ///   - content: The modal body.
    func modal(
        isPresented: Bool,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: () -> ViewGroup,
    ) -> some View {
        ModalView(background: self, isPresented: isPresented, onDismiss: onDismiss, body: content())
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
