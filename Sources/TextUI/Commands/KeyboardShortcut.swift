/// A combination of a key and modifiers for triggering a command.
///
/// ```swift
/// let save = KeyboardShortcut("s", modifiers: .control)   // Ctrl+S
/// let enter = KeyboardShortcut.defaultAction               // Enter
/// let escape = KeyboardShortcut.cancelAction               // Escape
/// ```
public struct KeyboardShortcut: Friendly {
    /// The key for this shortcut.
    public let key: KeyEquivalent

    /// The modifier keys required.
    public let modifiers: EventModifiers

    /// Creates a keyboard shortcut with a key equivalent and modifiers.
    public init(_ key: KeyEquivalent, modifiers: EventModifiers = []) {
        self.key = key
        self.modifiers = modifiers
    }

    /// Creates a keyboard shortcut from a character and modifiers.
    public init(_ char: Character, modifiers: EventModifiers = []) {
        key = KeyEquivalent(char)
        self.modifiers = modifiers
    }

    /// The default action shortcut (Enter / Return).
    public static let defaultAction = KeyboardShortcut(KeyEquivalent(.return))

    /// The cancel action shortcut (Escape).
    public static let cancelAction = KeyboardShortcut(KeyEquivalent(.escape))
}
