/// An immutable context threaded through the render tree.
///
/// `RenderContext` carries environment objects injected via
/// ``View/environmentObject(_:)`` and made available to descendants
/// via ``EnvironmentObject``. It is a value type — inserting an
/// object returns a new context without mutating the original.
public struct RenderContext: Sendable {
    /// The stored environment objects, keyed by their metatype.
    private var environmentObjects: [ObjectIdentifier: any Sendable] = [:]

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
