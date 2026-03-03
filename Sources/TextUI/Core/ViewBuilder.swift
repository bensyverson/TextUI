/// A result builder that constructs views from closures.
///
/// `ViewBuilder` is used with the `@ViewBuilder` attribute to enable
/// SwiftUI-like declarative syntax for composing views:
///
/// ```swift
/// struct MyView: View {
///     var body: some View {
///         Text("Hello")
///         Text("World")
///     }
/// }
/// ```
@MainActor @resultBuilder
public enum ViewBuilder {
    /// Builds a ``ViewGroup`` from multiple view expressions.
    public static func buildBlock(_ components: any View...) -> ViewGroup {
        ViewGroup(components)
    }

    /// Passes a single expression through as a view.
    public static func buildExpression(_ expression: any View) -> any View {
        expression
    }

    /// Builds an optional view, substituting ``EmptyView`` for `nil`.
    public static func buildOptional(_ component: (any View)?) -> any View {
        component ?? EmptyView()
    }

    /// Builds the first branch of an `if`/`else`.
    public static func buildEither(first component: any View) -> any View {
        component
    }

    /// Builds the second branch of an `if`/`else`.
    public static func buildEither(second component: any View) -> any View {
        component
    }

    /// Builds a view from a `for` loop by wrapping the results in a ``ViewGroup``.
    public static func buildArray(_ components: [any View]) -> ViewGroup {
        ViewGroup(components)
    }
}
