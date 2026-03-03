/// A type that represents part of a terminal user interface.
///
/// Like SwiftUI's `View`, you create custom views by declaring a `body`
/// property that composes other views. Primitive views (those conforming
/// to ``PrimitiveView``) handle sizing and rendering directly.
///
/// All views are `@MainActor`-isolated, matching SwiftUI in Swift 6.
/// This means control closures (e.g. ``Button`` actions, ``TextField``
/// onChange) inherit main-actor isolation and can mutate `@MainActor`
/// state directly without `@Sendable` friction.
///
/// ```swift
/// struct Greeting: View {
///     var body: some View {
///         Text("Hello, world!")
///     }
/// }
/// ```
@MainActor public protocol View {
    /// The type of view representing the body of this view.
    associatedtype Body: View

    /// The content and behavior of this view.
    var body: Body { get }
}
