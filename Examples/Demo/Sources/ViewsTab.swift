import TextUI

/// A tab showcasing every view primitive not featured in other tabs.
///
/// Demonstrates: AttributedText, ZStack, Canvas, ForEach, Group.
struct ViewsTab: View {
    @State var count: Int = 0

    var body: some View {
        ScrollView {
            VStack(spacing: 1) {
                Text("All Views", style: .bold)
                    .padding(bottom: 1)

                HStack(alignment: .center, spacing: 1) {
                    Text("Count: \(count)")
                    Button("+1") {
                        count += 1
                    }.border()
                }.padding(bottom: 2)

                // MARK: - AttributedText

                Text("AttributedText:", style: .dim)
                AttributedText {
                    AttributedText.TextSpan("Error: ", style: Style(fg: .red).bolded())
                    AttributedText.TextSpan("file ", style: .plain)
                    AttributedText.TextSpan("not found", style: Style(fg: .yellow).italicized())
                }
                .padding(bottom: 2)

                // MARK: - Text Wrapping

                Text("Text wrapping:", style: .dim)
                Text("TextUI is a SwiftUI-inspired framework for building expressive terminal UIs in Swift, with zero dependencies. Why? Why not! It makes building fancy terminal apps super fun.")
                    .frame(maxWidth: 40)
                    .padding(1)
                    .border()
                    .foregroundColor(.blue)
                    .padding(bottom: 2)

                // MARK: - Line Limit

                Text("lineLimit(2):", style: .dim)
                Text("This text has a line limit of 2. Any content beyond the second line will be truncated with an ellipsis to indicate there is more.")
                    .lineLimit(2)
                    .frame(maxWidth: 35)
                    .padding(1)
                    .border()
                    .padding(bottom: 2)
                    .foregroundColor(.red)

                // MARK: - Truncation Mode

                Text("truncationMode(.head):", style: .dim)
                Text("Head-truncated: shows the end of the text with an ellipsis at the beginning.")
                    .lineLimit(1)
                    .truncationMode(.head)
                    .frame(maxWidth: 35)
                    .padding(bottom: 1)

                Text("truncationMode(.middle):", style: .dim)
                Text("Middle-truncated: shows start and end with an ellipsis in the middle of the text.")
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .frame(maxWidth: 35)
                    .padding(bottom: 1)

                // MARK: - Multiline Text Alignment

                Text("multilineTextAlignment(.center):", style: .dim)
                Text("Centered text wraps and aligns each line to the center of the available space.")
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 35)
                    .padding(bottom: 1)

                Text("multilineTextAlignment(.trailing):", style: .dim)
                Text("Trailing-aligned text wraps and aligns each line to the right edge. This will become apparent with longer lines.")
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 35)
                    .padding(1)
                    .border()
                    .padding(bottom: 1)

                // MARK: - ForEach

                Text("ForEach:", style: .dim)
                HStack(spacing: 1) {
                    ForEach(["Alpha", "Beta", "Gamma", "Delta"]) { item in
                        Text(item, style: Style(fg: .cyan))
                            .padding(horizontal: 1)
                            .border()
                    }
                }
                .padding(bottom: 2)

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
                .padding(bottom: 2)
            }
            .padding(1)
        } // ScrollView
    }
}
