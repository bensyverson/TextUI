/// A property wrapper that reads and writes focus state.
///
/// Use `@FocusState` with an optional `Hashable` value to programmatically
/// control which view is focused. Pair it with the `.focused(_:equals:)`
/// modifier to bind views to focus values.
///
/// ```swift
/// enum Field: Hashable {
///     case name, email
/// }
///
/// struct FormView: View {
///     @FocusState var focus: Field?
///     @EnvironmentObject var state: FormState
///
///     var body: some View {
///         VStack {
///             TextField("Name", text: state.name)
///                 .focused($focus, equals: .name)
///             TextField("Email", text: state.email)
///                 .focused($focus, equals: .email)
///             Button("Submit") {
///                 if state.name.isEmpty {
///                     focus = .name  // move focus programmatically
///                 }
///             }
///         }
///     }
/// }
/// ```
///
/// The wrapped value is `nil` when nothing with a matching binding is
/// focused. Setting it to `nil` removes focus from all bound views.
///
/// - Note: Programmatic focus changes take effect immediately in the
///   `FocusStore`. The `RunLoop` re-renders after every key event,
///   so the visual update follows automatically. If you set focus from
///   an `@Observed` property's `didSet`, the state change signal already
///   triggers a re-render.
@propertyWrapper
public struct FocusState<Value: Hashable & Sendable>: Sendable {
    private var storage: Value

    /// The current focus value.
    ///
    /// Reading returns the currently focused binding key (or `nil`).
    /// Writing moves focus to the entry matching the new value (or
    /// removes focus if `nil`).
    public var wrappedValue: Value {
        get {
            let store = RenderEnvironment.current.focusStore
            if let key = store?.focusedBindingKey {
                if let value = key.base as? Value {
                    return value
                }
            }
            return storage
        }
        nonmutating set {
            let store = RenderEnvironment.current.focusStore
            // When Value is Optional, unwrap before creating AnyHashable
            // so that AnyHashable("email") matches the binding key.
            // When nil, pass nil to clear focus.
            let key: AnyHashable? = if let optional = newValue as? (any OptionalProtocol) {
                optional._unwrappedHashable
            } else {
                AnyHashable(newValue)
            }
            store?.setFocusByBindingKey(key)
        }
    }

    /// The binding projection for use with `.focused()` and `.defaultFocus()`.
    public var projectedValue: Binding {
        Binding(focusState: self)
    }

    /// Creates a focus state property with the given initial value.
    public init(wrappedValue: Value) {
        storage = wrappedValue
    }

    /// A binding to a ``FocusState`` that can be passed to `.focused()`.
    ///
    /// This is a marker type — the actual read/write happens through
    /// the `FocusStore`. The binding key is provided at the call site
    /// via `.focused($focus, equals: .name)`.
    public struct Binding: Sendable {
        let focusState: FocusState<Value>

        init(focusState: FocusState<Value>) {
            self.focusState = focusState
        }
    }
}

/// Internal protocol for extracting the inner value from optional types.
protocol OptionalProtocol {
    /// The unwrapped value as `AnyHashable`, or `nil` if the optional is `nil`.
    var _unwrappedHashable: AnyHashable? { get }
}

extension Optional: OptionalProtocol where Wrapped: Hashable {
    var _unwrappedHashable: AnyHashable? {
        switch self {
        case let .some(value): AnyHashable(value)
        case .none: nil
        }
    }
}

/// Convenience initializer for the common `Optional` case.
///
/// ```swift
/// @FocusState var focus: Field?  // defaults to nil
/// ```
public extension FocusState where Value: ExpressibleByNilLiteral {
    init() {
        self.init(wrappedValue: nil)
    }
}
