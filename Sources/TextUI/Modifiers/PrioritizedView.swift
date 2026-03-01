/// A view that carries a layout priority for stack distribution.
///
/// Higher-priority children receive their space allocation before
/// lower-priority children in the stack's greedy algorithm.
/// The default priority is `0`.
struct PrioritizedView: PrimitiveView, Sendable {
    let content: any View
    let priority: Double

    func sizeThatFits(_ proposal: SizeProposal) -> Size2D {
        TextUI.sizeThatFits(content, proposal: proposal)
    }

    func render(into buffer: inout Buffer, region: Region) {
        TextUI.render(content, into: &buffer, region: region)
    }
}
