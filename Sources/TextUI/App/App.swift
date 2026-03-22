/// A type that represents the top-level structure of a TextUI application.
///
/// Conform to `App` and implement the ``body`` property to define your
/// application's root view. Use the `@main` attribute and call
/// ``main()`` to launch the application.
///
/// ```swift
/// @main
/// struct MyApp: App {
///     var body: some View {
///         VStack {
///             Text("Hello, TextUI!")
///         }
///     }
///
///     static func main() async {
///         await MyApp.main()
///     }
/// }
/// ```
@MainActor
public protocol App {
    /// The type of the root view.
    associatedtype Body: View

    /// The root view of the application.
    var body: Body { get }

    /// The command groups for this application.
    ///
    /// Override this to register keyboard shortcuts:
    ///
    /// ```swift
    /// var commands: [CommandGroup] {
    ///     CommandGroup("File") {
    ///         Button("Save") { save() }
    ///             .keyboardShortcut("s", modifiers: .control)
    ///     }
    /// }
    /// ```
    var commands: [CommandGroup] { get }

    /// Whether mouse events (clicks, scroll wheel) are enabled.
    ///
    /// Defaults to `true`. Set to `false` to disable terminal mouse
    /// tracking, which restores normal text selection in the terminal.
    ///
    /// ```swift
    /// var allowsMouseEvents: Bool {
    ///     !CommandLine.arguments.contains("--no-mouse")
    /// }
    /// ```
    var allowsMouseEvents: Bool { get }

    /// Creates a new instance of the application.
    init()
}

public extension App {
    /// Default empty commands for apps that don't define any.
    var commands: [CommandGroup] {
        []
    }

    /// Mouse events are enabled by default.
    var allowsMouseEvents: Bool {
        true
    }

    /// Launches the application with the default run loop.
    ///
    /// This is the main entry point for a TextUI application. It:
    /// 1. Creates an instance of your `App`
    /// 2. Enters raw mode and the alternate screen buffer
    /// 3. Starts the key reader and event loop
    /// 4. Renders frames in response to state changes, key events, and resizes
    /// 5. Cleans up the terminal on exit (Ctrl+C or shutdown signal)
    static func main() async {
        await RunLoop.launch(Self())
    }
}
