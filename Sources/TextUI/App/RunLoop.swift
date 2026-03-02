/// The main event loop for a TextUI application.
///
/// `RunLoop` manages the terminal lifecycle, event merging, and render
/// cycle. It collects events from multiple sources (keyboard, state
/// changes, resize signals, shutdown) and dispatches them sequentially.
///
/// Key events are routed through the ``FocusStore``:
/// 1. Ctrl+C always exits
/// 2. ``FocusStore/routeKeyEvent(_:)`` — inline handler → onKeyPress chain → onSubmit
/// 3. If `.ignored`: Tab/Shift-Tab → ``FocusStore/focusNext()``/``FocusStore/focusPrevious()``
/// 4. If `.ignored`: arrows → ``FocusStore/focusInDirection(_:)``
/// 5. If anything was handled: ``renderFrame()``
@MainActor
final class RunLoop {
    /// The currently running run loop instance, if any.
    static var current: RunLoop?

    /// The double-buffered screen for rendering.
    private var screen: Screen

    /// The keyboard input reader.
    private let keyReader: KeyReader

    /// The root view to render each frame.
    private let rootView: any View

    /// The render context (carries environment objects).
    private var context: RenderContext

    /// Whether the run loop is still active.
    var isRunning: Bool = true

    /// Injects a shutdown event into the event stream, causing the run
    /// loop to exit promptly without waiting for another event.
    func requestShutdown() {
        isRunning = false
        eventContinuation?.yield(.shutdown)
    }

    /// The focus manager, created once and reused across frames.
    private let focusStore: FocusStore

    /// The focus store, accessible for ``State`` reads/writes outside the render pass.
    var stateStore: FocusStore {
        focusStore
    }

    /// The animation tracker, created once and reused across frames.
    private let animationTracker: AnimationTracker

    /// The background task that drives animation ticks, if running.
    private var tickTask: Task<Void, Never>?

    /// The command registry for shortcut matching.
    private let commandRegistry: CommandRegistry

    /// The timestamp of the last completed render, used for deduplication.
    /// Initialized to the past so the first `renderFrame()` call always succeeds.
    private var lastRenderTime = ContinuousClock.now.advanced(by: .seconds(-1))

    /// The number of frames rendered, exposed for testing.
    private(set) var renderCount: Int = 0

    /// Whether the next render should be a full (non-tick-only) render.
    ///
    /// Set to `true` by event handlers that change state or layout (key events,
    /// state changes, resize). The animation timer leaves this `false`, causing
    /// the render to be flagged as tick-only.
    private var pendingFullRender: Bool = true

    /// The overlay store for deferred overlay rendering (e.g. Picker dropdowns).
    private let overlayStore = OverlayStore()

    /// The task store for view-scoped async task lifecycle.
    private let taskStore = TaskStore()

    /// The merged event stream continuation, used to inject shutdown events.
    private var eventContinuation: AsyncStream<Event>.Continuation?

    /// Internal event types that the run loop processes.
    enum Event: Sendable {
        /// A key was pressed.
        case key(KeyEvent)

        /// State changed (an `@Observed` property was mutated).
        case stateChanged

        /// The terminal was resized.
        case resize(Terminal.Size)

        /// A shutdown signal was received (SIGTERM).
        case shutdown
    }

    /// Creates a run loop for the given root view and optional commands.
    init(rootView: any View, commands: [CommandGroup] = []) {
        let size = Terminal.size()
        screen = Screen(width: size.width, height: size.height)
        screen.colorCapability = ColorCapability.detect()
        keyReader = KeyReader()
        self.rootView = rootView
        context = RenderContext()
        focusStore = FocusStore()
        animationTracker = AnimationTracker()
        commandRegistry = CommandRegistry()
        commandRegistry.register(commands)
    }

    /// Runs the event loop until shutdown.
    ///
    /// This method blocks until the user presses Ctrl+C or a shutdown
    /// signal is received.
    func run() async {
        RunLoop.current = self

        // Setup terminal
        Terminal.enableRawMode()
        Terminal.enterAlternateScreen()
        Terminal.hideCursor()
        Terminal.clearScreen()
        Terminal.installSignalHandlers()

        defer {
            RunLoop.current = nil
            // Always clean up, even on unexpected exit
            keyReader.stop()
            Terminal.showCursor()
            Terminal.leaveAlternateScreen()
            Terminal.disableRawMode()
        }

        // Start key reader
        keyReader.start()

        // Initial render
        renderFrame()

        // Event loop
        for await event in mergedEvents() {
            guard isRunning else { break }

            switch event {
            case let .key(keyEvent):
                handleKey(keyEvent)
            case .stateChanged:
                pendingFullRender = true
                renderFrame()
            case let .resize(newSize):
                pendingFullRender = true
                screen.resize(width: newSize.width, height: newSize.height)
                Terminal.clearScreen()
                renderFrame(force: true)
            case .shutdown:
                isRunning = false
            }
        }
    }

    // MARK: - Event Merging

    /// Merges all event sources into a single async stream.
    ///
    /// Spawns child tasks to forward events from each source stream
    /// into a unified continuation. Uses `onTermination` to cancel
    /// child tasks when the stream is finished.
    private func mergedEvents() -> AsyncStream<Event> {
        AsyncStream<Event> { continuation in
            self.eventContinuation = continuation

            // Forward key events
            let keyTask = Task { [keyReader] in
                for await key in keyReader.events {
                    continuation.yield(.key(key))
                }
            }

            // Forward state change signals
            let stateTask = Task {
                for await _ in StateSignal.stream {
                    continuation.yield(.stateChanged)
                }
            }

            // Forward resize events (via async-signal-safe pipe)
            let resizeTask = Task {
                for await size in Terminal.resizeEvents() {
                    continuation.yield(.resize(size))
                }
            }

            // Forward shutdown signal
            let shutdownContinuation = continuation
            Terminal.onShutdown {
                shutdownContinuation.yield(.shutdown)
            }

            continuation.onTermination = { _ in
                keyTask.cancel()
                stateTask.cancel()
                resizeTask.cancel()
            }
        }
    }

    // MARK: - Key Handling

    /// Handles a key event by routing through commands, then focus.
    ///
    /// Key routing order:
    /// 1. Ctrl+C always exits
    /// 2. If palette visible: route to ``handlePaletteKey(_:)``
    /// 3. Command shortcuts → execute action
    /// 4. Ctrl+P → open palette
    /// 5. Focus system (inline → onKeyPress → onSubmit)
    /// 6. Tab/Shift-Tab → focus navigation
    /// 7. Arrows → directional navigation
    private func handleKey(_ key: KeyEvent) {
        // Ctrl+C always exits
        if key == .ctrl("c") {
            isRunning = false
            return
        }

        // When palette is visible, route all keys through palette handler
        if commandRegistry.isPaletteVisible {
            handlePaletteKey(key)
            return
        }

        // Command shortcuts (before focus routing)
        if let entry = commandRegistry.matchShortcut(key) {
            entry.action()
            pendingFullRender = true
            renderFrame()
            return
        }

        // Global tab switching with Ctrl+Shift+Arrow or Alt+Arrow
        if key == .ctrlShiftRight || key == .ctrlShiftLeft || key == .altRight || key == .altLeft {
            let direction = (key == .ctrlShiftRight || key == .altRight) ? 1 : -1
            switchTab(direction: direction)
            pendingFullRender = true
            renderFrame()
            return
        }

        // Toggle command palette with Ctrl+P
        if key == .ctrl("p") {
            commandRegistry.resetPaletteState()
            commandRegistry.isPaletteVisible = true
            pendingFullRender = true
            renderFrame()
            return
        }

        var handled = false

        // Route through focus system (inline → onKeyPress → onSubmit)
        if focusStore.routeKeyEvent(key) == .handled {
            handled = true
        }

        // Focus navigation
        if !handled {
            switch key {
            case .tab:
                focusStore.focusNext()
                handled = true
            case .shiftTab:
                focusStore.focusPrevious()
                handled = true
            case .up, .down, .left, .right:
                if focusStore.focusInDirection(key) == .handled {
                    handled = true
                }
            default:
                break
            }
        }

        if handled {
            pendingFullRender = true
            renderFrame()
        }
    }

    /// Handles key events while the command palette is visible.
    ///
    /// All keys except Ctrl+C are consumed by the palette:
    /// - **Escape / Ctrl+P** — close palette
    /// - **Enter** — execute selected command, close palette
    /// - **Up / Down** — navigate selection
    /// - **Backspace** — delete last filter character
    /// - **Character** — append to filter text
    private func handlePaletteKey(_ key: KeyEvent) {
        switch key {
        case .escape, .ctrl("p"):
            commandRegistry.isPaletteVisible = false
            commandRegistry.resetPaletteState()

        case .enter:
            let entries = commandRegistry.filteredEntries
            let index = commandRegistry.selectedIndex
            if index < entries.count {
                let entry = entries[index]
                commandRegistry.isPaletteVisible = false
                commandRegistry.resetPaletteState()
                entry.action()
            }

        case .up:
            if commandRegistry.selectedIndex > 0 {
                commandRegistry.selectedIndex -= 1
            }

        case .down:
            let maxIndex = commandRegistry.filteredEntries.count - 1
            if commandRegistry.selectedIndex < maxIndex {
                commandRegistry.selectedIndex += 1
            }

        case .backspace:
            if !commandRegistry.filterText.isEmpty {
                commandRegistry.filterText.removeLast()
                commandRegistry.selectedIndex = 0
            }

        case let .character(char):
            commandRegistry.filterText.append(char)
            commandRegistry.selectedIndex = 0

        default:
            break // Swallow all other keys
        }

        pendingFullRender = true
        renderFrame()
    }

    // MARK: - Tab Switching

    /// Switches the innermost TabView by the given direction (-1 or +1).
    private func switchTab(direction: Int) {
        guard let tabKey = focusStore.tabViewKeys.last else { return }
        var state = focusStore.controlState(forKey: tabKey, as: TabView.TabState.self)
            ?? TabView.TabState()
        guard state.tabCount > 0 else { return }
        state.selectedIndex = (state.selectedIndex + direction + state.tabCount) % state.tabCount
        focusStore.setControlState(state, forKey: tabKey)
    }

    // MARK: - Rendering

    /// Renders a single frame: sizes the root view, renders into the
    /// back buffer, and flushes changed cells to the terminal.
    ///
    /// - Parameter force: When `true`, bypasses the deduplication guard.
    ///   Used for resize events that must always re-render.
    private func renderFrame(force: Bool = false) {
        // Deduplication: two renders within <1ms cannot reflect different state
        // since everything is @MainActor.
        let now = ContinuousClock.now
        guard force || now - lastRenderTime >= .milliseconds(1) else { return }
        lastRenderTime = now
        renderCount += 1
        // Prepare stores for this frame
        focusStore.beginFrame()
        animationTracker.beginFrame()
        overlayStore.beginFrame()
        taskStore.beginFrame()

        // Determine if this is a tick-only render (animation tick, no state/key/resize)
        let isTickOnly = !pendingFullRender && !force
        pendingFullRender = false

        // Thread stores into the render context
        var ctx = context
        ctx.focusStore = focusStore
        ctx.animationTracker = animationTracker
        ctx.commandRegistry = commandRegistry
        ctx.overlayStore = overlayStore
        ctx.taskStore = taskStore
        ctx.isTickOnlyRender = isTickOnly

        screen.clear()

        let proposal = SizeProposal(width: screen.width, height: screen.height)
        let region = Region(row: 0, col: 0, width: screen.width, height: screen.height)

        _ = TextUI.sizeThatFits(rootView, proposal: proposal, context: ctx)
        TextUI.render(rootView, into: &screen.back, region: region, context: ctx)

        // Execute deferred overlays (e.g. Picker dropdowns)
        for overlay in overlayStore.overlays {
            overlay.render(&screen.back, region)
        }

        // Render command palette overlay if visible
        if commandRegistry.isPaletteVisible {
            let palette = CommandPalette()
            palette.render(into: &screen.back, region: region, context: ctx)
        }

        // Cancel tasks for views that are no longer in the tree
        taskStore.endFrame()

        // Reconcile focus: find the previously focused control in the new
        // ring, or reset to the first control if it's gone.  On the first
        // frame this also applies the default focus target.
        if focusStore.reconcileFocus() {
            // Focus changed after render (e.g. first frame, or the focused
            // control was removed). Re-render so the correct control draws
            // with focused styling / registers its inline handler.
            focusStore.beginFrame()
            animationTracker.beginFrame()
            overlayStore.beginFrame()
            taskStore.beginFrame()

            ctx.focusStore = focusStore
            ctx.animationTracker = animationTracker
            ctx.overlayStore = overlayStore
            ctx.taskStore = taskStore
            ctx.isTickOnlyRender = false

            screen.clear()
            _ = TextUI.sizeThatFits(rootView, proposal: proposal, context: ctx)
            TextUI.render(rootView, into: &screen.back, region: region, context: ctx)

            for overlay in overlayStore.overlays {
                overlay.render(&screen.back, region)
            }
            if commandRegistry.isPaletteVisible {
                let palette = CommandPalette()
                palette.render(into: &screen.back, region: region, context: ctx)
            }
            taskStore.endFrame()
        }

        let output = screen.flush()
        if !output.isEmpty {
            Terminal.write(output)
        }

        // Manage animation timer based on whether views requested animation
        if animationTracker.needsAnimation {
            startTickTimer()
        } else {
            stopTickTimer()
        }
    }

    // MARK: - Animation Timer

    /// Starts the animation tick timer if not already running.
    private func startTickTimer() {
        guard tickTask == nil else { return }
        tickTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(33))
                guard let self, isRunning else { break }
                animationTracker.tick()
                renderFrame()
            }
        }
    }

    /// Stops the animation tick timer if running.
    private func stopTickTimer() {
        tickTask?.cancel()
        tickTask = nil
    }
}
