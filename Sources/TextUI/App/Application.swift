/// Global application lifecycle control.
///
/// Provides a public API for quitting the application programmatically.
///
/// ```swift
/// Button("Quit") {
///     Application.quit()
/// }
/// ```
public enum Application {
    /// Stops the run loop, causing the application to exit cleanly.
    ///
    /// This method uses `MainActor.assumeIsolated` so it can be called
    /// from `@Sendable` closures (like Button actions) that execute
    /// synchronously on the main actor during the render/event cycle.
    public static func quit() {
        MainActor.assumeIsolated {
            RunLoop.current?.requestShutdown()
        }
    }
}
