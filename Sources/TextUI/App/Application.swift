/// Global application lifecycle control.
///
/// Provides a public API for quitting the application programmatically.
///
/// ```swift
/// Button("Quit") {
///     Application.quit()
/// }
/// ```
@MainActor
public enum Application {
    /// Stops the run loop, causing the application to exit cleanly.
    public static func quit() {
        RunLoop.current?.requestShutdown()
    }
}
