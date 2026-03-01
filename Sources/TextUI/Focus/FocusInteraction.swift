/// The kind of interaction a focusable control supports.
///
/// Controls declare their interaction type when registering in the
/// focus ring. This determines how the focus system routes key events:
/// - ``activate`` controls respond to Enter/Space (buttons, toggles)
/// - ``edit`` controls capture all keyboard input (text fields)
public enum FocusInteraction: Friendly {
    /// The control responds to discrete activation (Enter/Space).
    ///
    /// Used by ``Button``, ``Toggle``, and ``Picker``.
    case activate

    /// The control captures keyboard input for editing.
    ///
    /// Used by ``TextField``. The ``OnSubmitView`` modifier fires
    /// its handler on Enter for controls with this interaction type.
    case edit
}
