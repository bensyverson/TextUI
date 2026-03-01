/// A single-line text view with mixed styling spans.
///
/// Unlike ``Text``, which applies one style to the entire string,
/// `AttributedText` supports different styles for different parts
/// of the text.
///
/// ```swift
/// AttributedText {
///     TextSpan("Error: ", style: .bold.foreground(.red))
///     TextSpan("file not found", style: .plain)
/// }
/// ```
public struct AttributedText: PrimitiveView, Sendable {
    /// The styled text segments.
    let spans: [TextSpan]

    /// A segment of text with a specific style.
    public struct TextSpan: Friendly {
        /// The text content of this span.
        public let text: String

        /// The visual style applied to this span.
        public let style: Style

        /// Creates a text span with the given content and style.
        public init(_ text: String, style: Style = .plain) {
            self.text = text
            self.style = style
        }
    }

    /// Creates an attributed text view from an array of spans.
    public init(_ spans: [TextSpan]) {
        self.spans = spans
    }

    /// Creates an attributed text view using a result builder.
    public init(@SpanBuilder content: () -> [TextSpan]) {
        spans = content()
    }

    /// The total display width of all spans.
    private var totalWidth: Int {
        spans.reduce(0) { $0 + $1.text.displayWidth }
    }

    public func sizeThatFits(_ proposal: SizeProposal, context _: RenderContext) -> Size2D {
        let w: Int = switch proposal.width {
        case nil: totalWidth
        case 0: 0
        case let proposed?: min(totalWidth, proposed)
        }
        return Size2D(width: w, height: w > 0 ? 1 : 0)
    }

    public func render(into buffer: inout Buffer, region: Region, context _: RenderContext) {
        guard !region.isEmpty else { return }
        var col = region.col
        let maxCol = region.col + region.width
        for span in spans {
            guard col < maxCol else { break }
            let available = maxCol - col
            // Truncate span text to available width
            var rendered = ""
            var renderedWidth = 0
            for char in span.text {
                let w = char.displayWidth
                if renderedWidth + w > available { break }
                rendered.append(char)
                renderedWidth += w
            }
            let consumed = buffer.write(rendered, row: region.row, col: col, style: span.style)
            col += consumed
        }
    }
}

/// Result builder for constructing arrays of ``AttributedText/TextSpan``.
@resultBuilder
public enum SpanBuilder {
    /// Builds a block of text spans.
    public static func buildBlock(_ components: AttributedText.TextSpan...) -> [AttributedText.TextSpan] {
        Array(components)
    }

    /// Builds an expression from a single text span.
    public static func buildExpression(_ expression: AttributedText.TextSpan) -> AttributedText.TextSpan {
        expression
    }
}
