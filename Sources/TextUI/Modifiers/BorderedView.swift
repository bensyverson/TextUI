/// A view that draws a box-drawing border around its content.
///
/// The border adds 2 columns (left + right edges) and 2 rows
/// (top + bottom edges) to the child's size. An optional
/// ``Style/Color`` can be applied to the border characters.
public struct BorderedView: PrimitiveView {
    let content: any View
    let borderStyle: BorderStyle
    let borderColor: Style.Color?

    /// The style of box-drawing characters used for the border.
    public enum BorderStyle: Friendly {
        /// Rounded corners: ╭╮╰╯ with ─│ edges.
        case rounded
        /// Square corners: ┌┐└┘ with ─│ edges.
        case square

        var topLeft: Character {
            switch self {
            case .rounded: "╭"
            case .square: "┌"
            }
        }

        var topRight: Character {
            switch self {
            case .rounded: "╮"
            case .square: "┐"
            }
        }

        var bottomLeft: Character {
            switch self {
            case .rounded: "╰"
            case .square: "└"
            }
        }

        var bottomRight: Character {
            switch self {
            case .rounded: "╯"
            case .square: "┘"
            }
        }

        var horizontal: Character {
            "─"
        }

        var vertical: Character {
            "│"
        }

        // MARK: - Join Characters

        /// Horizontal line with a separator going down (┬).
        var teeDown: Character {
            "┬"
        }

        /// Horizontal line with a separator going up (┴).
        var teeUp: Character {
            "┴"
        }

        /// Vertical line with a branch going right (├).
        var teeRight: Character {
            "├"
        }

        /// Vertical line with a branch going left (┤).
        var teeLeft: Character {
            "┤"
        }
    }

    public func sizeThatFits(_ proposal: SizeProposal, context: RenderContext) -> Size2D {
        let inner = proposal.inset(horizontal: 2, vertical: 2)
        let childSize = TextUI.sizeThatFits(content, proposal: inner, context: context)
        return Size2D(
            width: childSize.width + 2,
            height: childSize.height + 2,
        )
    }

    public func render(into buffer: inout Buffer, region: Region, context: RenderContext) {
        guard region.width >= 2, region.height >= 2 else { return }

        let lastCol = region.col + region.width - 1
        let lastRow = region.row + region.height - 1
        let style = Style(fg: borderColor)

        // Draw corners
        buffer[region.row, region.col] = Cell(char: borderStyle.topLeft, style: style)
        buffer[region.row, lastCol] = Cell(char: borderStyle.topRight, style: style)
        buffer[lastRow, region.col] = Cell(char: borderStyle.bottomLeft, style: style)
        buffer[lastRow, lastCol] = Cell(char: borderStyle.bottomRight, style: style)

        // Draw horizontal edges
        buffer.horizontalLine(
            row: region.row, col: region.col + 1,
            length: region.width - 2, char: borderStyle.horizontal, style: style,
        )
        buffer.horizontalLine(
            row: lastRow, col: region.col + 1,
            length: region.width - 2, char: borderStyle.horizontal, style: style,
        )

        // Draw vertical edges
        buffer.verticalLine(
            row: region.row + 1, col: region.col,
            length: region.height - 2, char: borderStyle.vertical, style: style,
        )
        buffer.verticalLine(
            row: region.row + 1, col: lastCol,
            length: region.height - 2, char: borderStyle.vertical, style: style,
        )

        // Render content inside
        let innerRegion = region.inset(top: 1, left: 1, bottom: 1, right: 1)
        TextUI.render(content, into: &buffer, region: innerRegion, context: context)
    }
}
