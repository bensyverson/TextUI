/// A view that displays one or more lines of read-only text.
///
/// `Text` is a hugging view: it prefers its natural (ideal) size
/// and does not expand to fill available space. When proposed less
/// width than its content, it truncates. Multi-line strings are
/// split on newlines.
///
/// ```swift
/// Text("Hello, world!")
/// Text("Line 1\nLine 2")
/// Text("Bold text", style: .bold)
/// ```
public struct Text: PrimitiveView, Sendable {
    /// The string content to display.
    public let content: String

    /// The visual style applied to each character.
    public let style: Style

    /// The individual lines of content, split on newlines.
    private let lines: [String]

    /// Creates a text view with the given content and style.
    public init(_ content: String, style: Style = .plain) {
        self.content = content
        self.style = style
        lines = content.split(separator: "\n", omittingEmptySubsequences: false)
            .map(String.init)
    }

    /// The ideal width: the display width of the longest line.
    private var idealWidth: Int {
        lines.map(\.displayWidth).max() ?? 0
    }

    /// The ideal height: the number of lines.
    private var idealHeight: Int {
        lines.count
    }

    public func sizeThatFits(_ proposal: SizeProposal, context _: RenderContext) -> Size2D {
        let w: Int = switch proposal.width {
        case nil:
            idealWidth
        case 0:
            0
        case let proposed?:
            // Hug to content width — never expand beyond ideal
            min(idealWidth, proposed)
        }

        let h: Int = switch proposal.height {
        case nil:
            idealHeight
        case 0:
            0
        case let proposed?:
            min(idealHeight, proposed)
        }

        return Size2D(width: w, height: h)
    }

    public func render(into buffer: inout Buffer, region: Region, context _: RenderContext) {
        guard !region.isEmpty else { return }
        for (i, line) in lines.enumerated() {
            guard i < region.height else { break }
            buffer.write(
                line,
                row: region.row + i,
                col: region.col,
                style: style,
            )
        }
    }
}
