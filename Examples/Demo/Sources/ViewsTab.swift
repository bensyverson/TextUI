import TextUI

/// A tab showcasing every view primitive not featured in other tabs.
///
/// Demonstrates: AttributedText, ZStack, Canvas, ForEach, Group.
struct ViewsTab: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 1) {
                Text("All Views", style: .bold)
                Text("")

                // MARK: - AttributedText

                Text("AttributedText:", style: .dim)
                AttributedText {
                    AttributedText.TextSpan("Error: ", style: Style(fg: .red).bolded())
                    AttributedText.TextSpan("file ", style: .plain)
                    AttributedText.TextSpan("not found", style: Style(fg: .yellow).italicized())
                }
                Text("")

                // MARK: - ForEach

                Text("ForEach:", style: .dim)
                HStack(spacing: 1) {
                    ForEach(["Alpha", "Beta", "Gamma", "Delta"]) { item in
                        Text(item, style: Style(fg: .cyan))
                            .padding(horizontal: 1)
                            .border(.square)
                    }
                }
                Text("")

                // MARK: - Group

                Text("Group (layout-transparent):", style: .dim)
                HStack(spacing: 2) {
                    Group {
                        Text("One", style: Style(fg: .green))
                        Text("Two", style: Style(fg: .yellow))
                        Text("Three", style: Style(fg: .magenta))
                    }
                }
                Text("")

                // MARK: - ZStack

                Text("ZStack (overlaid layers):", style: .dim)
                ZStack {
                    Color(.blue)
                        .frame(width: 30, height: 3)
                    Text("Centered on blue", style: Style(fg: .white).bolded())
                }
                Text("")

                // MARK: - Canvas

                Text("Canvas (custom drawing):", style: .dim)
                Canvas { buffer, region in
                    let pattern = "░▒▓█▓▒░"
                    for row in region.row ..< min(region.row + 2, region.row + region.height) {
                        var col = region.col
                        while col < region.col + min(30, region.width) {
                            for ch in pattern {
                                guard col < region.col + min(30, region.width) else { break }
                                buffer[row, col] = Cell(char: ch, style: Style(fg: .cyan))
                                col += 1
                            }
                        }
                    }
                }
                .frame(width: 30, height: 2)
            }
            .padding(1)
        } // ScrollView
    }
}
