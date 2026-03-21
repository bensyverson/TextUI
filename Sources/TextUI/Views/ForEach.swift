/// A view that creates views from a collection of data.
///
/// `ForEach` is layout-transparent: in a stack, its children are
/// flattened into the stack's children rather than being treated
/// as a single view.
///
/// ```swift
/// VStack {
///     ForEach(items) { item in
///         Text(item.name)
///     }
/// }
/// ```
public struct ForEach<Data: RandomAccessCollection & Sendable>: PrimitiveView, LayoutTransparent, Sendable
    where Data.Element: Sendable
{
    let children: [any View]

    /// Creates views by applying the content closure to each element.
    ///
    /// The closure is evaluated eagerly — only the resulting views are stored.
    public init(_ data: Data, @ViewBuilder content: (Data.Element) -> ViewGroup) {
        children = data.flatMap { element in
            content(element).children
        }
    }

    /// Creates views from a collection using a key path for identity.
    ///
    /// This matches SwiftUI's `ForEach(_:id:content:)` API. Because TextUI
    /// evaluates eagerly (no diffing), the `id` key path is not used at
    /// runtime — but it satisfies the same call-site ergonomics, allowing
    /// non-`Identifiable` elements like `String`, `Int`, or enumerated tuples.
    ///
    /// ```swift
    /// ForEach(lines, id: \.self) { line in
    ///     Text(line)
    /// }
    ///
    /// ForEach(Array(items.enumerated()), id: \.offset) { index, item in
    ///     Text("\(index): \(item)")
    /// }
    /// ```
    public init(
        _ data: Data,
        id _: KeyPath<Data.Element, some Hashable & Sendable>,
        @ViewBuilder content: (Data.Element) -> ViewGroup,
    ) {
        children = data.flatMap { element in
            content(element).children
        }
    }

    // MARK: - LayoutTransparent

    var layoutChildren: [any View] {
        children
    }

    // MARK: - PrimitiveView (bare usage outside a stack)

    public func sizeThatFits(_ proposal: SizeProposal, context: RenderContext) -> Size2D {
        guard let first = children.first else { return .zero }
        return TextUI.sizeThatFits(first, proposal: proposal, context: context)
    }

    public func render(into buffer: inout Buffer, region: Region, context: RenderContext) {
        guard let first = children.first else { return }
        TextUI.render(first, into: &buffer, region: region, context: context)
    }
}
