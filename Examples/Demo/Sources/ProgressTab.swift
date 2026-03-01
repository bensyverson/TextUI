import TextUI

/// A tab demonstrating ProgressView in various styles.
///
/// Uses `@State` and `.task {}` to drive a looping progress animation
/// without any shared state object.
struct ProgressTab: View {
    @State var progress: Double = 0.0

    var body: some View {
        VStack(spacing: 1) {
            Text("Progress Indicators", style: .bold)
            Text("")

            Text("Indeterminate spinner:", style: .dim)
            ProgressView("Loading")
            Text("")

            Text("Determinate bar (\(Int(progress * 100))%):", style: .dim)
            ProgressView("Download", value: progress)
            Text("")

            Text("Compact style:", style: .dim)
            ProgressView("Indexing", value: 0.72)
                .progressViewStyle(.compact)
            Text("")

            Text("Full bar style:", style: .dim)
            ProgressView("Building", value: 0.58)
                .progressViewStyle(.bar())
            Text("")

            Text("Indeterminate bar:", style: .dim)
            ProgressView("Syncing")
                .progressViewStyle(.bar())
        }
        .padding(1)
        .task {
            while !Task.isCancelled {
                progress = 0.0
                for i in 1 ... 100 {
                    try? await Task.sleep(for: .milliseconds(100))
                    guard !Task.isCancelled else { return }
                    progress = Double(i) / 100.0
                }
                try? await Task.sleep(for: .seconds(1))
            }
        }
    }
}
