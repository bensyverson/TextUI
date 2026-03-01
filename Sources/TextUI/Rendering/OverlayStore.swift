/// Accumulates deferred overlay closures during a render pass.
///
/// Views like ``Picker`` register overlays that render on top of all other
/// content. ``RunLoop`` executes these after the main render pass completes.
///
/// `OverlayStore` is a reference type so all copies of ``RenderContext``
/// share the same overlay list — the same pattern used by ``FocusStore``
/// and ``AnimationTracker``.
final class OverlayStore: @unchecked Sendable {
    /// A deferred overlay that renders into a buffer after the main pass.
    struct Overlay: @unchecked Sendable {
        /// Renders the overlay into the given buffer within the full screen region.
        let render: (inout Buffer, Region) -> Void
    }

    /// The overlays collected during the current frame.
    private(set) var overlays: [Overlay] = []

    /// Registers a deferred overlay to be rendered after the main pass.
    func addOverlay(_ overlay: Overlay) {
        overlays.append(overlay)
    }

    /// Clears all overlays at the start of a new frame.
    func beginFrame() {
        overlays = []
    }
}
