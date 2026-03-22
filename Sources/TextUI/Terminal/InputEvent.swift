/// A terminal input event — either a key press or a mouse action.
///
/// `InputEvent` is the unified type emitted by the terminal input reader,
/// wrapping both keyboard and mouse interactions into a single stream.
///
/// ```swift
/// for await event in keyReader.events {
///     switch event {
///     case .key(let key): handleKey(key)
///     case .mouse(let mouse): handleMouse(mouse)
///     }
/// }
/// ```
public enum InputEvent: Hashable, Equatable, Sendable {
    /// A keyboard event.
    case key(KeyEvent)

    /// A mouse event.
    case mouse(MouseEvent)
}
