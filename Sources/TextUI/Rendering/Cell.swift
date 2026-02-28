/// A single terminal cell: one character with associated styling.
///
/// Cells are the atomic unit of the rendering buffer. Each position
/// in the terminal grid holds one `Cell`. Wide characters (emoji, CJK)
/// occupy two cells — the primary cell holds the character, and the
/// following cell is marked as a continuation.
public struct Cell: Friendly {
    /// The character displayed in this cell.
    public var char: Character

    /// The visual style (colors, bold, etc.) for this cell.
    public var style: Style

    /// Whether this cell is the second half of a wide character.
    ///
    /// Continuation cells are skipped during rendering — the terminal
    /// automatically advances the cursor after a wide character.
    public var isContinuation: Bool

    public init(char: Character = " ", style: Style = .plain, isContinuation: Bool = false) {
        self.char = char
        self.style = style
        self.isContinuation = isContinuation
    }

    /// A blank cell with default styling.
    public static let blank = Cell()

    /// A continuation marker for the second column of a wide character.
    public static let continuation = Cell(isContinuation: true)

    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case char
        case style
        case isContinuation
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let charString = try container.decode(String.self, forKey: .char)
        guard let first = charString.first else {
            throw DecodingError.dataCorruptedError(
                forKey: .char,
                in: container,
                debugDescription: "Empty string for char",
            )
        }
        char = first
        style = try container.decode(Style.self, forKey: .style)
        isContinuation = try container.decode(Bool.self, forKey: .isContinuation)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(String(char), forKey: .char)
        try container.encode(style, forKey: .style)
        try container.encode(isContinuation, forKey: .isContinuation)
    }
}
