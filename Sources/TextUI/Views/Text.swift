/// A view that displays one or more lines of read-only text.
///
/// `Text` is a hugging view: it prefers its natural (ideal) size
/// and does not expand to fill available space. When proposed less
/// width than its content, it wraps at word boundaries. Multi-line
/// strings are split on newlines.
///
/// Use ``View/lineLimit(_:)`` to cap the number of visible lines,
/// ``View/truncationMode(_:)`` to control where the ellipsis appears,
/// and ``View/multilineTextAlignment(_:)`` to align wrapped lines.
///
/// ```swift
/// Text("Hello, world!")
/// Text("Line 1\nLine 2")
/// Text("Bold text", style: .bold)
/// ```
public struct Text: PrimitiveView, Sendable {
    /// How text is truncated when it exceeds the available space.
    public enum TruncationMode: Friendly {
        /// Truncate at the beginning: `…llo World`
        case head

        /// Truncate in the middle: `Hel…orld`
        case middle

        /// Truncate at the end: `Hello Wo…`
        case tail
    }

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

    // MARK: - Word Wrapping

    /// Wraps a single line at word boundaries to fit within `maxWidth` columns.
    ///
    /// Words are split on spaces. If a single word is wider than `maxWidth`,
    /// it is character-wrapped (broken at `maxWidth` boundaries respecting
    /// display widths for CJK/emoji).
    static func wordWrap(_ line: String, maxWidth: Int) -> [String] {
        guard maxWidth > 0 else { return [""] }
        guard line.displayWidth > maxWidth else { return [line] }

        let words = line.split(separator: " ", omittingEmptySubsequences: false).map(String.init)
        var result: [String] = []
        var currentLine = ""
        var currentWidth = 0

        for word in words {
            let wordWidth = word.displayWidth

            // Handle words wider than maxWidth — character-wrap them
            if wordWidth > maxWidth {
                // Flush current line first if non-empty
                if !currentLine.isEmpty {
                    result.append(currentLine)
                    currentLine = ""
                    currentWidth = 0
                }
                // Break the word into chunks that fit
                var chunk = ""
                var chunkWidth = 0
                for char in word {
                    let charWidth = char.displayWidth
                    if chunkWidth + charWidth > maxWidth, !chunk.isEmpty {
                        result.append(chunk)
                        chunk = ""
                        chunkWidth = 0
                    }
                    chunk.append(char)
                    chunkWidth += charWidth
                }
                // Remaining chunk becomes the start of a new line
                currentLine = chunk
                currentWidth = chunkWidth
                continue
            }

            // Would adding this word (plus a space separator) exceed the width?
            let separatorWidth = currentLine.isEmpty ? 0 : 1
            if currentWidth + separatorWidth + wordWidth > maxWidth {
                // Start a new line
                result.append(currentLine)
                currentLine = word
                currentWidth = wordWidth
            } else {
                if !currentLine.isEmpty {
                    currentLine += " "
                    currentWidth += 1
                }
                currentLine += word
                currentWidth += wordWidth
            }
        }
        // Don't forget the last line
        result.append(currentLine)
        return result
    }

    /// Computes all wrapped lines for a given width.
    private func wrappedLines(forWidth width: Int) -> [String] {
        lines.flatMap { line in
            Text.wordWrap(line, maxWidth: width)
        }
    }

    // MARK: - Truncation

    /// Truncates a single line to fit within `maxWidth` using the given mode.
    ///
    /// The ellipsis character `…` (U+2026, 1 column) replaces removed content.
    static func truncate(_ line: String, toWidth maxWidth: Int, mode: TruncationMode) -> String {
        let lineWidth = line.displayWidth
        guard lineWidth > maxWidth, maxWidth > 0 else { return line }

        let ellipsis: Character = "\u{2026}"
        let availableWidth = maxWidth - 1 // Reserve 1 column for ellipsis

        guard availableWidth > 0 else {
            return String(ellipsis)
        }

        switch mode {
        case .tail:
            // Keep leading characters, append ellipsis
            var result = ""
            var width = 0
            for char in line {
                let charWidth = char.displayWidth
                if width + charWidth > availableWidth { break }
                result.append(char)
                width += charWidth
            }
            result.append(ellipsis)
            return result

        case .head:
            // Keep trailing characters, prepend ellipsis
            var chars: [Character] = []
            var width = 0
            for char in line.reversed() {
                let charWidth = char.displayWidth
                if width + charWidth > availableWidth { break }
                chars.append(char)
                width += charWidth
            }
            return String(ellipsis) + String(chars.reversed())

        case .middle:
            // Keep some leading + some trailing, ellipsis in the middle
            let leadingWidth = (availableWidth + 1) / 2
            let trailingWidth = availableWidth / 2

            var leading = ""
            var lw = 0
            for char in line {
                let charWidth = char.displayWidth
                if lw + charWidth > leadingWidth { break }
                leading.append(char)
                lw += charWidth
            }

            var trailingChars: [Character] = []
            var tw = 0
            for char in line.reversed() {
                let charWidth = char.displayWidth
                if tw + charWidth > trailingWidth { break }
                trailingChars.append(char)
                tw += charWidth
            }

            return leading + String(ellipsis) + String(trailingChars.reversed())
        }
    }

    // MARK: - PrimitiveView

    public func sizeThatFits(_ proposal: SizeProposal, context: RenderContext) -> Size2D {
        let lineLimit = context.lineLimit

        let w: Int
        var h: Int

        switch proposal.width {
        case nil:
            w = idealWidth
            h = idealHeight
        case 0:
            return .zero
        case let proposed?:
            if proposed >= idealWidth {
                // Plenty of room — hug to content
                w = idealWidth
                h = idealHeight
            } else {
                // Need to wrap
                let wrapped = wrappedLines(forWidth: proposed)
                w = proposed
                h = wrapped.count
            }
        }

        // Apply line limit
        if let limit = lineLimit {
            h = min(h, max(limit, 0))
        }

        // Apply height proposal
        switch proposal.height {
        case nil:
            break
        case 0:
            return .zero
        case let proposed?:
            h = min(h, proposed)
        }

        return Size2D(width: w, height: h)
    }

    public func render(into buffer: inout Buffer, region: Region, context: RenderContext) {
        guard !region.isEmpty else { return }

        let lineLimit = context.lineLimit
        let truncationMode = context.truncationMode ?? .tail
        let alignment = context.multilineTextAlignment ?? .leading

        // Compute the lines to render
        let wrappedContent: [String] = if region.width >= idealWidth {
            lines
        } else {
            wrappedLines(forWidth: region.width)
        }

        // Determine max visible lines. lineLimit caps semantically (with ellipsis);
        // region height clips without indicator.
        let lineLimitCap = lineLimit.map { min($0, region.height) }
        let maxLines = lineLimitCap ?? region.height

        // Only apply semantic truncation (with ellipsis) when lineLimit is the cause
        let lineLimitCausesTruncation = lineLimitCap != nil
            && wrappedContent.count > maxLines
            && maxLines > 0

        let displayLines: [String] = if lineLimitCausesTruncation {
            Text.applyLineTruncation(
                wrappedContent,
                maxLines: maxLines,
                maxWidth: region.width,
                mode: truncationMode,
            )
        } else {
            Array(wrappedContent.prefix(maxLines))
        }

        for (i, line) in displayLines.enumerated() {
            var rendered = line

            // Truncate lines wider than the region (shouldn't happen often
            // since wrapping targets region width, but covers edge cases)
            if rendered.displayWidth > region.width {
                rendered = Text.truncate(rendered, toWidth: region.width, mode: truncationMode)
            }

            // Compute column offset for alignment
            let lineWidth = rendered.displayWidth
            let offset: Int = switch alignment {
            case .leading:
                0
            case .center:
                max(0, (region.width - lineWidth) / 2)
            case .trailing:
                max(0, region.width - lineWidth)
            }

            buffer.write(
                rendered,
                row: region.row + i,
                col: region.col + offset,
                style: style,
            )
        }
    }

    /// Applies line-level truncation when wrapped content exceeds the line limit.
    ///
    /// For `.tail` mode, shows the first lines and reconstructs remaining content
    /// on the last visible line. For `.head` mode, shows the last lines and
    /// reconstructs earlier content on the first visible line. For `.middle`,
    /// shows lines from both ends with truncation at the boundary.
    private static func applyLineTruncation(
        _ wrappedLines: [String],
        maxLines: Int,
        maxWidth: Int,
        mode: TruncationMode,
    ) -> [String] {
        guard maxLines > 0 else { return [] }

        switch mode {
        case .tail:
            // Show first (maxLines - 1) lines as-is, then reconstruct the
            // remaining content into a single line and tail-truncate it.
            var result = Array(wrappedLines.prefix(maxLines - 1))
            let remaining = wrappedLines.dropFirst(maxLines - 1).joined(separator: " ")
            result.append(truncate(remaining, toWidth: maxWidth, mode: .tail))
            return result

        case .head:
            // Show last (maxLines - 1) lines as-is, then reconstruct the
            // earlier content into a single line and head-truncate it.
            let tailLines = Array(wrappedLines.suffix(maxLines - 1))
            let earlier = wrappedLines.dropLast(maxLines - 1).joined(separator: " ")
            var result = [truncate(earlier, toWidth: maxWidth, mode: .head)]
            result.append(contentsOf: tailLines)
            return result

        case .middle:
            if maxLines == 1 {
                let combined = wrappedLines.joined(separator: " ")
                return [truncate(combined, toWidth: maxWidth, mode: .middle)]
            }
            // Show first ceil((maxLines-1)/2) and last floor((maxLines-1)/2) lines,
            // with a middle-truncated boundary line.
            let topCount = (maxLines + 1) / 2
            let bottomCount = maxLines / 2
            var result = Array(wrappedLines.prefix(topCount - 1))
            // Boundary line: join middle content and middle-truncate
            let middleStart = topCount - 1
            let middleEnd = wrappedLines.count - bottomCount
            let middleContent = wrappedLines[middleStart ... middleEnd].joined(separator: " ")
            result.append(truncate(middleContent, toWidth: maxWidth, mode: .middle))
            result.append(contentsOf: wrappedLines.suffix(bottomCount))
            return result
        }
    }
}
