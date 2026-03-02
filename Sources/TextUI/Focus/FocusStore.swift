/// The engine-internal focus manager for a TextUI application.
///
/// `FocusStore` maintains the **focus ring** — an ordered list of focusable
/// controls built during each render pass. It handles:
/// - Focus ring construction and per-frame reset
/// - Tab/Shift-Tab cycling with wrap-around
/// - Directional (arrow key) navigation within focus sections
/// - Key event routing through inline handlers and ancestor handler chains
/// - Programmatic focus via binding keys
/// - Per-control state storage (e.g. ``TextField`` cursor positions)
///
/// The store is created once by ``RunLoop`` and threaded through the render
/// tree via ``RenderContext/focusStore``. During each render pass, focusable
/// controls call ``register(interaction:region:sectionID:bindingKey:autoKey:)``
/// to join the ring.
/// - Note: Although not `@MainActor`-isolated, `FocusStore` is only ever
///   accessed from ``RunLoop`` (which is `@MainActor`) and from
///   `PrimitiveView.render()` calls that occur synchronously within the
///   render pass. The `@unchecked Sendable` conformance reflects this.
final class FocusStore: @unchecked Sendable {
    /// An entry in the focus ring, representing one focusable control.
    struct FocusEntry: @unchecked Sendable {
        /// Sequential ID assigned during the current render pass.
        let id: Int

        /// The interaction type this control supports.
        let interaction: FocusInteraction

        /// The region this control occupies in the buffer.
        let region: Region

        /// The focus section this control belongs to, if any.
        let sectionID: Int?

        /// An explicit binding key from `.focused($binding, equals:)`.
        let bindingKey: AnyHashable?

        /// An auto-generated key from `#fileID:#line`.
        let autoKey: AnyHashable?

        /// Snapshot of ancestor `onKeyPress` handlers at registration time.
        let keyHandlerChain: [KeyHandler]

        /// Snapshot of ancestor `onSubmit` handlers at registration time.
        let submitHandlerChain: [SubmitHandler]
    }

    /// A key event handler captured from an `onKeyPress` modifier.
    struct KeyHandler: @unchecked Sendable {
        let handler: @Sendable (KeyEvent) -> KeyEventResult
    }

    /// A submit handler captured from an `onSubmit` modifier.
    struct SubmitHandler: @unchecked Sendable {
        let handler: @Sendable () -> Void
    }

    // MARK: - Focus Ring

    /// The ordered list of focusable controls for the current frame.
    private(set) var ring: [FocusEntry] = []

    /// The index of the currently focused entry, persisted across frames.
    private(set) var focusedIndex: Int?

    // MARK: - Handler Chain Stack

    /// The current stack of ancestor key handlers, built during render.
    private var keyHandlerStack: [KeyHandler] = []

    /// The current stack of ancestor submit handlers, built during render.
    private var submitHandlerStack: [SubmitHandler] = []

    // MARK: - Inline Handlers

    /// Per-control inline key handlers, keyed by focus entry ID.
    private var inlineHandlers: [Int: @Sendable (KeyEvent) -> KeyEventResult] = [:]

    // MARK: - Control State

    /// Per-control state storage (e.g. cursor position), keyed by the
    /// control's effective key (binding key or auto key).
    private var controlStates: [AnyHashable: any Sendable] = [:]

    // MARK: - ID Generation

    /// The next sequential ID to assign during this frame.
    private var nextID: Int = 0

    /// The next section ID to assign.
    private var nextSectionID: Int = 0

    // MARK: - Default Focus

    /// The binding key to focus on the first frame, set by `.defaultFocus()`.
    var defaultFocusTarget: AnyHashable?

    /// Whether the first frame has been processed (default focus applied).
    private var hasAppliedDefaultFocus: Bool = false

    // MARK: - Focus Identity Tracking

    /// The identity (autoKey or bindingKey) of the currently focused control,
    /// used to reconcile focus across frames when the ring is rebuilt.
    private var focusedIdentity: AnyHashable?

    // MARK: - TabView Keys

    /// Auto keys of TabViews registered during the current frame (innermost last).
    var tabViewKeys: [AnyHashable] = []

    // MARK: - Frame Lifecycle

    /// Resets the focus ring for a new render pass.
    ///
    /// Called at the start of each frame before rendering. Clears the ring
    /// and inline handlers but preserves the focused index, control states,
    /// and default focus state.
    func beginFrame() {
        ring = []
        inlineHandlers = [:]
        keyHandlerStack = []
        submitHandlerStack = []
        tabViewKeys = []
        nextID = 0
    }

    /// Applies the default focus target on the first frame.
    ///
    /// If ``defaultFocusTarget`` is set and no focus has been established,
    /// focuses the entry matching that binding key. If no default is set,
    /// focuses the first entry in the ring.
    func applyDefaultFocus() {
        guard !hasAppliedDefaultFocus else { return }
        hasAppliedDefaultFocus = true

        if let target = defaultFocusTarget {
            if let idx = ring.firstIndex(where: { $0.bindingKey == target }) {
                focusedIndex = idx
                focusedIdentity = identityOf(ring[idx])
            }
        } else if !ring.isEmpty, focusedIndex == nil {
            focusedIndex = 0
            focusedIdentity = identityOf(ring[0])
        }
    }

    /// Reconciles focus after the ring has been rebuilt by a render pass.
    ///
    /// Handles three cases:
    /// 1. **First frame**: delegates to ``applyDefaultFocus()``
    /// 2. **Ring composition changed**: if the previously focused control
    ///    (identified by autoKey/bindingKey) is still in the ring, moves
    ///    `focusedIndex` to its new position. If it's gone (e.g. a control
    ///    was disabled or the view hierarchy changed), resets to index 0.
    /// 3. **Index out of bounds**: clamps to the valid range.
    ///
    /// - Returns: `true` if focus changed (callers should re-render so
    ///   the focused control draws with the correct visual state).
    @discardableResult
    func reconcileFocus() -> Bool {
        // First frame: apply default focus
        if !hasAppliedDefaultFocus {
            let before = focusedIndex
            applyDefaultFocus()
            return focusedIndex != before
        }

        guard !ring.isEmpty else {
            let changed = focusedIndex != nil
            focusedIndex = nil
            focusedIdentity = nil
            return changed
        }

        let oldIndex = focusedIndex

        // If we have a tracked identity, try to find it in the new ring
        if let identity = focusedIdentity {
            if let idx = focusedIndex, idx < ring.count,
               identityOf(ring[idx]) == identity
            {
                // Same control at same index — no change needed
                return false
            }
            // Try to find the control at a different index
            if let newIdx = ring.firstIndex(where: { identityOf($0) == identity }) {
                focusedIndex = newIdx
                return focusedIndex != oldIndex
            }
        }

        // Focused control is gone or index is stale — reset to first control
        focusedIndex = 0
        focusedIdentity = identityOf(ring[0])
        return focusedIndex != oldIndex
    }

    /// The effective identity key for a focus entry (prefers autoKey over bindingKey).
    private func identityOf(_ entry: FocusEntry) -> AnyHashable? {
        entry.autoKey ?? entry.bindingKey
    }

    // MARK: - Registration

    /// Registers a focusable control in the focus ring.
    ///
    /// Called during `render()` by focusable controls. The control receives
    /// a snapshot of the current ancestor handler chain.
    ///
    /// - Returns: The assigned focus entry ID.
    @discardableResult
    func register(
        interaction: FocusInteraction,
        region: Region,
        sectionID: Int?,
        bindingKey: AnyHashable?,
        autoKey: AnyHashable?,
    ) -> Int {
        let id = nextID
        nextID += 1

        let entry = FocusEntry(
            id: id,
            interaction: interaction,
            region: region,
            sectionID: sectionID,
            bindingKey: bindingKey,
            autoKey: autoKey,
            keyHandlerChain: keyHandlerStack,
            submitHandlerChain: submitHandlerStack,
        )
        ring.append(entry)
        return id
    }

    /// Registers an inline key handler for a specific focus entry.
    ///
    /// Only the focused control should register an inline handler to
    /// avoid unnecessary closure overhead.
    func registerInlineHandler(
        for entryID: Int,
        handler: @escaping @Sendable (KeyEvent) -> KeyEventResult,
    ) {
        inlineHandlers[entryID] = handler
    }

    // MARK: - Focus Queries

    /// Whether the given entry ID is currently focused.
    func isFocused(_ entryID: Int) -> Bool {
        guard let idx = focusedIndex, idx < ring.count else { return false }
        return ring[idx].id == entryID
    }

    /// Whether the entry with the given binding key is currently focused.
    func isFocusedByBindingKey(_ key: AnyHashable) -> Bool {
        guard let idx = focusedIndex, idx < ring.count else { return false }
        return ring[idx].bindingKey == key
    }

    /// The binding key of the currently focused entry, or `nil`.
    var focusedBindingKey: AnyHashable? {
        guard let idx = focusedIndex, idx < ring.count else { return nil }
        return ring[idx].bindingKey
    }

    // MARK: - Programmatic Focus

    /// Moves focus to the entry matching the given binding key.
    func setFocusByBindingKey(_ key: AnyHashable?) {
        guard let key else {
            focusedIndex = nil
            focusedIdentity = nil
            return
        }
        if let idx = ring.firstIndex(where: { $0.bindingKey == key }) {
            focusedIndex = idx
            focusedIdentity = identityOf(ring[idx])
        }
    }

    // MARK: - Handler Chain Management

    /// Pushes a key handler onto the ancestor chain stack.
    ///
    /// Called by ``OnKeyPressView`` before rendering its content.
    func pushKeyHandler(_ handler: KeyHandler) {
        keyHandlerStack.append(handler)
    }

    /// Pops the most recent key handler from the ancestor chain stack.
    ///
    /// Called by ``OnKeyPressView`` after rendering its content.
    func popKeyHandler() {
        _ = keyHandlerStack.popLast()
    }

    /// Pushes a submit handler onto the ancestor chain stack.
    ///
    /// Called by ``OnSubmitView`` before rendering its content.
    func pushSubmitHandler(_ handler: SubmitHandler) {
        submitHandlerStack.append(handler)
    }

    /// Pops the most recent submit handler from the ancestor chain stack.
    ///
    /// Called by ``OnSubmitView`` after rendering its content.
    func popSubmitHandler() {
        _ = submitHandlerStack.popLast()
    }

    // MARK: - Section IDs

    /// Allocates a new focus section ID.
    func nextSection() -> Int {
        let id = nextSectionID
        nextSectionID += 1
        return id
    }

    // MARK: - Key Event Routing

    /// Routes a key event through the focused control's handler chain.
    ///
    /// The routing order is:
    /// 1. The focused control's inline handler (TextField editing, Button Enter)
    /// 2. Ancestor `onKeyPress` chain (innermost/deepest first)
    /// 3. `onSubmit` handlers (Enter on `.edit` controls only)
    ///
    /// - Returns: `.handled` if any handler consumed the event.
    func routeKeyEvent(_ key: KeyEvent) -> KeyEventResult {
        guard let idx = focusedIndex, idx < ring.count else { return .ignored }
        let entry = ring[idx]

        // 1. Control's own inline handler
        if let handler = inlineHandlers[entry.id] {
            if handler(key) == .handled { return .handled }
        }

        // 2. Ancestor onKeyPress chain (innermost first = reversed)
        for kh in entry.keyHandlerChain.reversed() {
            if kh.handler(key) == .handled { return .handled }
        }

        // 3. Submit handlers (Enter on .edit controls)
        if key == .enter, entry.interaction == .edit, let submit = entry.submitHandlerChain.last {
            submit.handler()
            return .handled
        }

        return .ignored
    }

    // MARK: - Focus Navigation

    /// Moves focus to the next entry in the ring (wraps around).
    func focusNext() {
        guard !ring.isEmpty else { return }
        if let idx = focusedIndex {
            focusedIndex = (idx + 1) % ring.count
        } else {
            focusedIndex = 0
        }
        focusedIdentity = ring[focusedIndex!].autoKey ?? ring[focusedIndex!].bindingKey
    }

    /// Moves focus to the previous entry in the ring (wraps around).
    func focusPrevious() {
        guard !ring.isEmpty else { return }
        if let idx = focusedIndex {
            focusedIndex = (idx - 1 + ring.count) % ring.count
        } else {
            focusedIndex = ring.count - 1
        }
        focusedIdentity = ring[focusedIndex!].autoKey ?? ring[focusedIndex!].bindingKey
    }

    /// Moves focus in a direction within the current focus section.
    ///
    /// Arrow navigation is constrained to entries sharing the same
    /// section ID as the currently focused entry. Up/Left moves to the
    /// previous entry in the section; Down/Right moves to the next.
    ///
    /// - Returns: `.handled` if focus moved, `.ignored` otherwise.
    @discardableResult
    func focusInDirection(_ direction: KeyEvent) -> KeyEventResult {
        guard let idx = focusedIndex, idx < ring.count else { return .ignored }
        let current = ring[idx]

        // Only navigate within a section
        let sectionEntries: [(offset: Int, element: FocusEntry)] = if let sid = current.sectionID {
            ring.enumerated().filter { $0.element.sectionID == sid }
        } else {
            // No section: use the entire ring
            Array(ring.enumerated())
        }

        guard sectionEntries.count > 1 else { return .ignored }

        guard let posInSection = sectionEntries.firstIndex(where: { $0.offset == idx }) else {
            return .ignored
        }

        switch direction {
        case .up, .left:
            let newPos = (posInSection - 1 + sectionEntries.count) % sectionEntries.count
            focusedIndex = sectionEntries[newPos].offset
            focusedIdentity = identityOf(ring[focusedIndex!])
            return .handled
        case .down, .right:
            let newPos = (posInSection + 1) % sectionEntries.count
            focusedIndex = sectionEntries[newPos].offset
            focusedIdentity = identityOf(ring[focusedIndex!])
            return .handled
        default:
            return .ignored
        }
    }

    // MARK: - Control State

    /// Retrieves stored state for a control identified by its key.
    func controlState<T: Sendable>(forKey key: AnyHashable, as _: T.Type) -> T? {
        controlStates[key] as? T
    }

    /// Stores state for a control identified by its key.
    func setControlState(_ value: some Sendable, forKey key: AnyHashable) {
        controlStates[key] = value
    }
}
