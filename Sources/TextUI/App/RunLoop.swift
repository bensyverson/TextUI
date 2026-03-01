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
    /// The double-buffered screen for rendering.
    private var screen: Screen

    /// The keyboard input reader.
    private let keyReader: KeyReader

    /// The root view to render each frame.
    private let rootView: any View

    /// The render context (carries environment objects).
    private var context: RenderContext

    /// Whether the run loop is still active.
    private var isRunning: Bool = true

    /// The focus manager, created once and reused across frames.
    private let focusStore: FocusStore

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

    /// Creates a run loop for the given root view.
    init(rootView: any View) {
        let size = Terminal.size()
        screen = Screen(width: size.width, height: size.height)
        screen.colorCapability = ColorCapability.detect()
        keyReader = KeyReader()
        self.rootView = rootView
        context = RenderContext()
        focusStore = FocusStore()
    }

    /// Runs the event loop until shutdown.
    ///
    /// This method blocks until the user presses Ctrl+C or a shutdown
    /// signal is received.
    func run() async {
        // Setup terminal
        Terminal.enableRawMode()
        Terminal.enterAlternateScreen()
        Terminal.hideCursor()
        Terminal.clearScreen()
        Terminal.installSignalHandlers()

        defer {
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
                renderFrame()
            case let .resize(newSize):
                screen.resize(width: newSize.width, height: newSize.height)
                renderFrame()
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

            // Forward resize events
            let resizeContinuation = continuation
            Terminal.onResize { size in
                resizeContinuation.yield(.resize(size))
            }

            // Forward shutdown signal
            let shutdownContinuation = continuation
            Terminal.onShutdown {
                shutdownContinuation.yield(.shutdown)
            }

            continuation.onTermination = { _ in
                keyTask.cancel()
                stateTask.cancel()
            }
        }
    }

    // MARK: - Key Handling

    /// Handles a key event by routing through the focus system.
    ///
    /// Ctrl+C always exits. Other keys are first routed through the
    /// ``FocusStore``'s handler chain, then through focus navigation
    /// (Tab/Shift-Tab, arrows). A re-render is triggered if any handler
    /// consumed the event or focus moved.
    private func handleKey(_ key: KeyEvent) {
        // Ctrl+C always exits
        if key == .ctrl("c") {
            isRunning = false
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
            renderFrame()
        }
    }

    // MARK: - Rendering

    /// Renders a single frame: sizes the root view, renders into the
    /// back buffer, and flushes changed cells to the terminal.
    private func renderFrame() {
        // Prepare focus store for this frame
        focusStore.beginFrame()

        // Thread focus store into the render context
        var ctx = context
        ctx.focusStore = focusStore

        screen.clear()

        let proposal = SizeProposal(width: screen.width, height: screen.height)
        let region = Region(row: 0, col: 0, width: screen.width, height: screen.height)

        _ = TextUI.sizeThatFits(rootView, proposal: proposal, context: ctx)
        TextUI.render(rootView, into: &screen.back, region: region, context: ctx)

        // Apply default focus on first frame
        focusStore.applyDefaultFocus()

        let output = screen.flush()
        if !output.isEmpty {
            Terminal.write(output)
        }
    }
}
