/// An immutable context threaded through the render tree.
///
/// `RenderContext` carries environment objects injected via
/// ``View/environmentObject(_:)`` and made available to descendants
/// via ``EnvironmentObject``. It is a value type — inserting an
/// object returns a new context without mutating the original.
///
/// The context also carries focus system state:
/// - ``focusStore`` — the shared ``FocusStore`` for focus ring management
/// - ``currentFocusSectionID`` — the active focus section (set by ``FocusSectionView``)
/// - ``focusEnvironment`` — per-scope focus state (set by ``FocusedView``)
public struct RenderContext: Sendable {
    /// The stored environment objects, keyed by their metatype.
    private var environmentObjects: [ObjectIdentifier: any Sendable] = [:]

    /// The focus store for the current render pass, if any.
    ///
    /// Set by ``RunLoop`` and threaded through the render tree. Focusable
    /// controls register themselves here during `render()`.
    var focusStore: FocusStore?

    /// The active focus section ID, set by ``FocusSectionView``.
    ///
    /// Controls registered within a focus section share this ID for
    /// directional (arrow key) navigation.
    var currentFocusSectionID: Int?

    /// Per-scope focus state, set by ``FocusedView``.
    ///
    /// Controls read this to determine whether they are currently focused.
    var focusEnvironment: FocusEnvironment?

    /// Creates an empty render context.
    public init() {}

    /// Returns the environment object of the given type, or `nil` if none.
    public func environmentObject<T: AnyObject & Sendable>(ofType type: T.Type) -> T? {
        environmentObjects[ObjectIdentifier(type)] as? T
    }

    /// Returns a new context with the given object inserted.
    public func inserting(_ object: some AnyObject & Sendable) -> RenderContext {
        var copy = self
        copy.environmentObjects[ObjectIdentifier(type(of: object))] = object
        return copy
    }
}

/// Provides access to the current ``RenderContext`` during view body evaluation.
///
/// The render engine sets this via `withValue` when evaluating composite
/// view bodies, allowing ``EnvironmentObject`` property wrappers to
/// read from it.
public enum RenderEnvironment {
    /// The current render context, accessible via `@TaskLocal`.
    @TaskLocal public static var current = RenderContext()
}
