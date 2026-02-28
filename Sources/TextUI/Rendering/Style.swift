/// Terminal text styling: colors, attributes, and styled string composition.
///
/// `Style` captures all visual attributes for a terminal cell — foreground
/// and background colors plus text decorations (bold, dim, italic, etc.).
/// Styles generate ANSI SGR escape sequences for terminal output, with
/// differential encoding to minimize bytes written.
public struct Style: Friendly {
    /// Foreground color.
    public var fg: Color?

    /// Background color.
    public var bg: Color?

    /// Whether the text is bold.
    public var bold: Bool

    /// Whether the text is dim.
    public var dim: Bool

    /// Whether the text is italic.
    public var italic: Bool

    /// Whether the text is underlined.
    public var underline: Bool

    /// Whether the text has inverse video (swap fg/bg).
    public var inverse: Bool

    /// Whether the text is struck through.
    public var strikethrough: Bool

    public init(
        fg: Color? = nil,
        bg: Color? = nil,
        bold: Bool = false,
        dim: Bool = false,
        italic: Bool = false,
        underline: Bool = false,
        inverse: Bool = false,
        strikethrough: Bool = false,
    ) {
        self.fg = fg
        self.bg = bg
        self.bold = bold
        self.dim = dim
        self.italic = italic
        self.underline = underline
        self.inverse = inverse
        self.strikethrough = strikethrough
    }

    /// The default (no styling) style.
    public static let plain = Style()

    /// Bold text.
    public static let bold = Style(bold: true)

    /// Dim text.
    public static let dim = Style(dim: true)

    /// Italic text.
    public static let italic = Style(italic: true)

    // MARK: - Builder Methods

    /// Returns a copy with the foreground color set.
    public func foreground(_ color: Color) -> Style {
        var copy = self
        copy.fg = color
        return copy
    }

    /// Returns a copy with the background color set.
    public func background(_ color: Color) -> Style {
        var copy = self
        copy.bg = color
        return copy
    }

    /// Returns a copy with bold enabled.
    public func bolded() -> Style {
        var copy = self
        copy.bold = true
        return copy
    }

    /// Returns a copy with dim enabled.
    public func dimmed() -> Style {
        var copy = self
        copy.dim = true
        return copy
    }

    /// Returns a copy with italic enabled.
    public func italicized() -> Style {
        var copy = self
        copy.italic = true
        return copy
    }

    /// Returns a copy with underline enabled.
    public func underlined() -> Style {
        var copy = self
        copy.underline = true
        return copy
    }

    /// Returns a copy with inverse video enabled.
    public func inversed() -> Style {
        var copy = self
        copy.inverse = true
        return copy
    }

    /// Returns a copy with strikethrough enabled.
    public func struckthrough() -> Style {
        var copy = self
        copy.strikethrough = true
        return copy
    }

    // MARK: - ANSI Generation

    /// Generate the ANSI escape sequence to apply this style.
    ///
    /// If `previous` is provided, only emits codes for attributes that changed.
    public func ansiSequence(from previous: Style? = nil) -> String {
        // If nothing changed, emit nothing
        if let previous, self == previous { return "" }

        var codes: [String] = []

        // If transitioning from styled to plain, reset first
        if let previous, needsReset(from: previous) {
            codes.append("0")
            // After reset, we need to re-apply all current attributes
            return "\u{1B}[\(codes.joined(separator: ";"))m" + ansiSequence()
        }

        if bold, previous?.bold != true { codes.append("1") }
        if dim, previous?.dim != true { codes.append("2") }
        if italic, previous?.italic != true { codes.append("3") }
        if underline, previous?.underline != true { codes.append("4") }
        if inverse, previous?.inverse != true { codes.append("7") }
        if strikethrough, previous?.strikethrough != true { codes.append("9") }

        if let fg, fg != previous?.fg {
            codes.append(fg.fgCode)
        }
        if let bg, bg != previous?.bg {
            codes.append(bg.bgCode)
        }

        if codes.isEmpty { return "" }
        return "\u{1B}[\(codes.joined(separator: ";"))m"
    }

    /// Whether we need a reset before applying this style over the previous.
    private func needsReset(from previous: Style) -> Bool {
        (previous.bold && !bold) ||
            (previous.dim && !dim) ||
            (previous.italic && !italic) ||
            (previous.underline && !underline) ||
            (previous.inverse && !inverse) ||
            (previous.strikethrough && !strikethrough) ||
            (previous.fg != nil && fg == nil) ||
            (previous.bg != nil && bg == nil)
    }
}

// MARK: - Color

public extension Style {
    /// A terminal color, supporting basic 16, 256-color, and 24-bit RGB.
    enum Color: Friendly {
        // Basic 16 colors
        case black, red, green, yellow, blue, magenta, cyan, white
        case brightBlack, brightRed, brightGreen, brightYellow
        case brightBlue, brightMagenta, brightCyan, brightWhite

        /// 256-color palette (0–255).
        case palette(UInt8)

        /// 24-bit RGB color.
        case rgb(UInt8, UInt8, UInt8)

        /// The ANSI SGR code for this color as a foreground.
        var fgCode: String {
            switch self {
            case .black: "30"
            case .red: "31"
            case .green: "32"
            case .yellow: "33"
            case .blue: "34"
            case .magenta: "35"
            case .cyan: "36"
            case .white: "37"
            case .brightBlack: "90"
            case .brightRed: "91"
            case .brightGreen: "92"
            case .brightYellow: "93"
            case .brightBlue: "94"
            case .brightMagenta: "95"
            case .brightCyan: "96"
            case .brightWhite: "97"
            case let .palette(n): "38;5;\(n)"
            case let .rgb(r, g, b): "38;2;\(r);\(g);\(b)"
            }
        }

        /// The ANSI SGR code for this color as a background.
        var bgCode: String {
            switch self {
            case .black: "40"
            case .red: "41"
            case .green: "42"
            case .yellow: "43"
            case .blue: "44"
            case .magenta: "45"
            case .cyan: "46"
            case .white: "47"
            case .brightBlack: "100"
            case .brightRed: "101"
            case .brightGreen: "102"
            case .brightYellow: "103"
            case .brightBlue: "104"
            case .brightMagenta: "105"
            case .brightCyan: "106"
            case .brightWhite: "107"
            case let .palette(n): "48;5;\(n)"
            case let .rgb(r, g, b): "48;2;\(r);\(g);\(b)"
            }
        }
    }
}
