/// A type that represents part of a terminal user interface.
///
/// Like SwiftUI's `View`, you create custom views by declaring a `body`
/// property that composes other views. Primitive views (those conforming
/// to ``PrimitiveView``) handle sizing and rendering directly.
///
/// ```swift
/// struct Greeting: View {
///     var body: some View {
///         Text("Hello, world!")
///     }
/// }
/// ```
public protocol View: Sendable {
    /// The type of view representing the body of this view.
    associatedtype Body: View

    /// The content and behavior of this view.
    var body: Body { get }
}
