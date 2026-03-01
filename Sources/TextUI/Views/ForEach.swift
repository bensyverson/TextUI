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

    // MARK: - LayoutTransparent

    var layoutChildren: [any View] {
        children
    }

    // MARK: - PrimitiveView (bare usage outside a stack)

    public func sizeThatFits(_ proposal: SizeProposal) -> Size2D {
        guard let first = children.first else { return .zero }
        return TextUI.sizeThatFits(first, proposal: proposal)
    }

    public func render(into buffer: inout Buffer, region: Region) {
        guard let first = children.first else { return }
        TextUI.render(first, into: &buffer, region: region)
    }
}
