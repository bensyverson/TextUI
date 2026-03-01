/// A property wrapper that triggers a re-render when its value changes.
///
/// Use `@Observed` on properties in your `@MainActor` state classes
/// to automatically signal the render loop when state is mutated.
///
/// ```swift
/// @MainActor
/// final class AppState {
///     @Observed var count = 0
///     @Observed var name = "World"
/// }
/// ```
///
/// No equality gating is performed — every set triggers a signal.
/// The ``Screen``'s differential flush handles the visual no-op case
/// efficiently.
@MainActor
@propertyWrapper
public struct Observed<Value: Sendable> {
    private var storage: Value

    /// The current value. Setting this triggers ``StateSignal/send()``.
    public var wrappedValue: Value {
        get { storage }
        set {
            storage = newValue
            StateSignal.send()
        }
    }

    /// Creates an observed property with the given initial value.
    public init(wrappedValue: Value) {
        storage = wrappedValue
    }
}
