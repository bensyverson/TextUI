/// The result of handling a key event.
///
/// Key event handlers return this to indicate whether they consumed
/// the event or whether it should propagate to the next handler.
public enum KeyEventResult: Friendly {
    /// The event was consumed and should not propagate further.
    case handled

    /// The event was not consumed and should propagate to the next handler.
    case ignored
}
