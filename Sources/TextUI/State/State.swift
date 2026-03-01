/// A property wrapper that provides view-local mutable state.
///
/// `@State` stores its value in the ``FocusStore``'s control state
/// dictionary, using the declaration site (`#fileID:#line`) as the key.
/// This means the value persists across render frames without polluting
/// shared state objects.
///
/// ```swift
/// struct CounterView: View {
///     @State var count: Int = 0
///
///     var body: some View {
///         HStack {
///             Text("Count: \(count)")
///             Button("+1") { count += 1 }
///         }
///     }
/// }
/// ```
///
/// The setter calls ``StateSignal/send()`` to trigger a re-render,
/// just like ``Observed``.
///
/// - Important: `@State` is designed for simple value types owned by a
///   single view. For shared state across multiple views, use
///   ``Observed`` on a `@MainActor` class and inject it with
///   `.environmentObject()`.
@propertyWrapper
public struct State<Value: Sendable>: Sendable {
    private let key: String
    private let defaultValue: Value

    /// Creates a state property with an initial value.
    ///
    /// The storage key is derived from the declaration site, so each
    /// `@State` property in the source code gets its own slot.
    public init(wrappedValue: Value, fileID: String = #fileID, line: Int = #line) {
        key = "\(fileID):\(line)"
        defaultValue = wrappedValue
    }

    /// Resolves the backing store for this state property.
    ///
    /// During the render pass, the store comes from the `@TaskLocal`
    /// render context. Outside the render pass (e.g. in `.task {}`
    /// closures), it falls back to the run loop's store. Both paths
    /// execute on `@MainActor`; the `nonisolated(unsafe)` access is
    /// safe because `@State` is only used from MainActor contexts.
    private var resolvedStore: FocusStore? {
        if let store = RenderEnvironment.current.focusStore {
            return store
        }
        return MainActor.assumeIsolated { RunLoop.current?.stateStore }
    }

    public var wrappedValue: Value {
        get {
            resolvedStore?.controlState(forKey: AnyHashable(key), as: Value.self)
                ?? defaultValue
        }
        nonmutating set {
            resolvedStore?.setControlState(newValue, forKey: AnyHashable(key))
            MainActor.assumeIsolated { StateSignal.send() }
        }
    }
}
