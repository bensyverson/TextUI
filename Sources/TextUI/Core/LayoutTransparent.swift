/// A marker protocol for views whose children should be flattened
/// into the parent container during stack layout.
///
/// ``ViewGroup``, ``ForEach``, and ``Group`` conform to this protocol.
/// Stacks flatten layout-transparent children rather than treating
/// them as single views.
protocol LayoutTransparent {
    /// The children to flatten into the parent layout.
    var layoutChildren: [any View] { get }
}
