/// An immutable context threaded through the render tree.
///
/// `RenderContext` carries environment objects injected via
/// ``View/environmentObject(_:)`` and made available to descendants
/// via ``EnvironmentObject``. It is a value type — inserting an
/// object returns a new context without mutating the original.
///
/// The context also carries focus system state:
/// - `focusStore` — the shared `FocusStore` for focus ring management
/// - `currentFocusSectionID` — the active focus section (set by `FocusSectionView`)
/// - `focusEnvironment` — per-scope focus state (set by `FocusedView`)
public struct RenderContext: Sendable {
    /// The stored environment objects, keyed by their metatype.
    private var environmentObjects: [ObjectIdentifier: any Sendable] = [:]

    /// The focus store for the current render pass, if any.
    ///
    /// Set by `RunLoop` and threaded through the render tree. Focusable
    /// controls register themselves here during `render()`.
    var focusStore: FocusStore?

    /// The active focus section ID, set by `FocusSectionView`.
    ///
    /// Controls registered within a focus section share this ID for
    /// directional (arrow key) navigation.
    var currentFocusSectionID: Int?

    /// Per-scope focus state, set by `FocusedView`.
    ///
    /// Controls read this to determine whether they are currently focused.
    var focusEnvironment: FocusEnvironment?

    /// The animation tracker for the current render pass, if any.
    ///
    /// Set by `RunLoop` and read by ``AnimationTick`` to signal that
    /// the animation timer should continue running.
    var animationTracker: AnimationTracker?

    /// The command registry for the current render pass, if any.
    ///
    /// Set by `RunLoop` and read by ``CommandBar`` and command palette
    /// to display available commands.
    var commandRegistry: CommandRegistry?

    /// The overlay store for deferred overlay rendering.
    ///
    /// Set by `RunLoop` and used by views like ``Picker`` to register
    /// overlays that render on top of all other content.
    var overlayStore: OverlayStore?

    /// The task store for view-scoped async task lifecycle.
    ///
    /// Set by `RunLoop` and used by ``TaskView`` to register and manage
    /// async tasks that run while a view is in the tree.
    var taskStore: TaskStore?

    /// The progress view style override, if any.
    ///
    /// Set by ``ProgressViewStyleView`` and read by ``ProgressView``
    /// to determine its rendering style.
    var progressViewStyle: ProgressViewStyle?

    /// The default scroll anchor for descendant ``ScrollView`` instances.
    ///
    /// Set by ``DefaultScrollAnchorView`` and read by ``ScrollView``
    /// to determine initial and auto-scroll behavior.
    var defaultScrollAnchor: VerticalAlignment?

    /// The maximum number of lines for descendant ``Text`` views.
    ///
    /// Set by ``LineLimitView`` and read by ``Text`` to cap the number
    /// of visible lines. `nil` means unlimited.
    var lineLimit: Int?

    /// The truncation mode for descendant ``Text`` views.
    ///
    /// Set by ``TruncationModeView`` and read by ``Text`` to determine
    /// where the ellipsis appears when content is truncated.
    /// `nil` defaults to ``Text/TruncationMode/tail``.
    var truncationMode: Text.TruncationMode?

    /// The horizontal alignment for wrapped lines in descendant ``Text`` views.
    ///
    /// Set by ``MultilineTextAlignmentView`` and read by ``Text`` to
    /// position wrapped lines within the available width.
    /// `nil` defaults to ``HorizontalAlignment/leading``.
    var multilineTextAlignment: HorizontalAlignment?

    /// Creates an empty render context.
    public init() {}

    /// Returns the environment object of the given type, or `nil` if none.
    public func environmentObject<T: AnyObject & Sendable>(ofType type: T.Type) -> T? {
        environmentObjects[ObjectIdentifier(type)] as? T
    }

    /// Returns a new context with the given object inserted.
    public func inserting(_ object: some AnyObject & Sendable) -> RenderContext {
        var copy = self
        copy.environmentObjects[ObjectIdentifier(type(of: object))] = object
        return copy
    }
}

/// Provides access to the current ``RenderContext`` during view body evaluation.
///
/// The render engine sets this via `withValue` when evaluating composite
/// view bodies, allowing ``EnvironmentObject`` property wrappers to
/// read from it.
public enum RenderEnvironment {
    /// The current render context, accessible via `@TaskLocal`.
    @TaskLocal public static var current = RenderContext()
}
