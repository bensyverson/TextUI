/// A key that can be used as a keyboard shortcut.
///
/// `KeyEquivalent` represents either a character key or a named special key
/// (like Return, Escape, or arrow keys).
///
/// ```swift
/// let charKey = KeyEquivalent("s")
/// let namedKey = KeyEquivalent(.return)
/// ```
public struct KeyEquivalent: Friendly {
    /// The character this key represents, if any.
    public let character: Character?

    /// The named key this represents, if any.
    public let named: NamedKey?

    /// Creates a key equivalent from a character.
    public init(_ char: Character) {
        character = char
        named = nil
    }

    /// Creates a key equivalent from a named key.
    public init(_ named: NamedKey) {
        character = nil
        self.named = named
    }

    /// Named special keys for keyboard shortcuts.
    public enum NamedKey: String, Friendly {
        /// The Return / Enter key.
        case `return`

        /// The Escape key.
        case escape

        /// The Tab key.
        case tab

        /// The Delete (backspace) key.
        case delete

        /// The up arrow key.
        case upArrow

        /// The down arrow key.
        case downArrow

        /// The left arrow key.
        case leftArrow

        /// The right arrow key.
        case rightArrow
    }

    // MARK: - Custom Codable

    enum CodingKeys: String, CodingKey {
        case character, named
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let charStr = try container.decodeIfPresent(String.self, forKey: .character) {
            character = charStr.first
            named = nil
        } else {
            character = nil
            named = try container.decodeIfPresent(NamedKey.self, forKey: .named)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if let character {
            try container.encode(String(character), forKey: .character)
        }
        if let named {
            try container.encode(named, forKey: .named)
        }
    }
}
