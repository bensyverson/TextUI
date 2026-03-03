/// A property wrapper that reads an environment object from the render context.
///
/// Use `@EnvironmentObject` in views to access objects injected by
/// ancestor views via ``View/environmentObject(_:)``.
///
/// ```swift
/// @MainActor
/// final class AppState: Sendable {
///     @Observed var count = 0
/// }
///
/// struct CounterView: View {
///     @EnvironmentObject var state: AppState
///
///     var body: some View {
///         Text("Count: \(state.count)")
///     }
/// }
/// ```
///
/// Accessing the property before the object has been injected is a
/// fatal error — always ensure an ancestor provides the object.
@MainActor
@propertyWrapper
public struct EnvironmentObject<T: AnyObject & Sendable> {
    /// Creates an environment object property wrapper.
    public init() {}

    /// The environment object value, read from the current render context.
    ///
    /// - Precondition: An ancestor view must have called
    ///   `.environmentObject(_:)` with an object of type `T`.
    public var wrappedValue: T {
        guard let obj = RenderEnvironment.current.environmentObject(ofType: T.self) else {
            fatalError(
                "No environment object of type \(T.self) found. " +
                    "Use .environmentObject() on an ancestor view to inject it.",
            )
        }
        return obj
    }
}
