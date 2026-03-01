/// A view that participates in layout but does not render.
///
/// Created by the ``View/hidden()`` modifier. The view occupies the
/// same space as its content but produces no visible output.
struct HiddenView: PrimitiveView, Sendable {
    let content: any View

    func sizeThatFits(_ proposal: SizeProposal) -> Size2D {
        TextUI.sizeThatFits(content, proposal: proposal)
    }

    func render(into _: inout Buffer, region _: Region) {
        // Intentionally empty — hidden views occupy space but render nothing
    }
}
