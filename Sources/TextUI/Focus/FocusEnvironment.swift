/// Focus state injected into the render context by ``FocusedView``.
///
/// Controls read this from ``RenderContext/focusEnvironment`` to
/// determine whether they are currently focused and to access their
/// focus ID for registering inline key handlers.
struct FocusEnvironment: Friendly {
    /// Whether the current scope is focused.
    let isFocused: Bool

    /// The focus ring ID for the current scope, if registered.
    let focusID: Int?
}
