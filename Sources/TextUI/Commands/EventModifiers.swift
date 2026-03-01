/// Modifier keys that can be combined with a key equivalent.
///
/// Use as an `OptionSet` to combine modifiers:
///
/// ```swift
/// let mods: EventModifiers = [.control, .shift]
/// ```
public struct EventModifiers: OptionSet, Friendly {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    /// The Control key modifier.
    public static let control = EventModifiers(rawValue: 1 << 0)

    /// The Shift key modifier.
    public static let shift = EventModifiers(rawValue: 1 << 1)

    /// The Option / Alt key modifier.
    public static let option = EventModifiers(rawValue: 1 << 2)
}
