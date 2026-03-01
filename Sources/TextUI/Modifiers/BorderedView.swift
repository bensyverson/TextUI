/// A view that draws a box-drawing border around its content.
///
/// The border adds 2 columns (left + right edges) and 2 rows
/// (top + bottom edges) to the child's size.
public struct BorderedView: PrimitiveView, Sendable {
    let content: any View
    let borderStyle: BorderStyle

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
    }

    public func sizeThatFits(_ proposal: SizeProposal) -> Size2D {
        let inner = proposal.inset(horizontal: 2, vertical: 2)
        let childSize = TextUI.sizeThatFits(content, proposal: inner)
        return Size2D(
            width: childSize.width + 2,
            height: childSize.height + 2,
        )
    }

    public func render(into buffer: inout Buffer, region: Region) {
        guard region.width >= 2, region.height >= 2 else { return }

        let lastCol = region.col + region.width - 1
        let lastRow = region.row + region.height - 1

        // Draw corners
        buffer[region.row, region.col] = Cell(char: borderStyle.topLeft)
        buffer[region.row, lastCol] = Cell(char: borderStyle.topRight)
        buffer[lastRow, region.col] = Cell(char: borderStyle.bottomLeft)
        buffer[lastRow, lastCol] = Cell(char: borderStyle.bottomRight)

        // Draw horizontal edges
        buffer.horizontalLine(
            row: region.row, col: region.col + 1,
            length: region.width - 2, char: borderStyle.horizontal,
        )
        buffer.horizontalLine(
            row: lastRow, col: region.col + 1,
            length: region.width - 2, char: borderStyle.horizontal,
        )

        // Draw vertical edges
        buffer.verticalLine(
            row: region.row + 1, col: region.col,
            length: region.height - 2, char: borderStyle.vertical,
        )
        buffer.verticalLine(
            row: region.row + 1, col: lastCol,
            length: region.height - 2, char: borderStyle.vertical,
        )

        // Render content inside
        let innerRegion = region.inset(top: 1, left: 1, bottom: 1, right: 1)
        TextUI.render(content, into: &buffer, region: innerRegion)
    }
}
