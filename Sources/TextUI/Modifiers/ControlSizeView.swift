/// The size of a control, affecting its visual density.
///
/// Controls like ``TabView`` use control size to choose between
/// compact (1-line), regular (2-line), or spacious (3-line) chrome.
/// Apply via ``View/controlSize(_:)``.
///
/// The default is ``ControlSize/regular`` when no modifier is applied.
public enum ControlSize: Friendly {
    /// Compact 1-line rendering.
    case small

    /// Standard 2-line rendering (default).
    case regular

    /// Spacious 3-line rendering with full box-drawing.
    case large
}

/// A modifier view that sets the control size in the render context.
///
/// Applied via ``View/controlSize(_:)``. Descendant controls read
/// the size from ``RenderContext/controlSize``.
struct ControlSizeView: PrimitiveView {
    /// The wrapped content view.
    let content: any View

    /// The control size to apply.
    let size: ControlSize

    func sizeThatFits(_ proposal: SizeProposal, context: RenderContext) -> Size2D {
        var ctx = context
        ctx.controlSize = size
        return TextUI.sizeThatFits(content, proposal: proposal, context: ctx)
    }

    func render(into buffer: inout Buffer, region: Region, context: RenderContext) {
        var ctx = context
        ctx.controlSize = size
        TextUI.render(content, into: &buffer, region: region, context: ctx)
    }
}
