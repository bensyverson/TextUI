import TextUI

/// A tab demonstrating ProgressView in various styles.
struct ProgressTab: View {
    @EnvironmentObject var state: DemoState

    var body: some View {
        VStack(spacing: 1) {
            Text("Progress Indicators", style: .bold)
            Text("")

            Text("Indeterminate spinner:", style: .dim)
            ProgressView("Loading")
            Text("")

            Text("Determinate bar (35%):", style: .dim)
            ProgressView("Download", value: state.progress)
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
    }
}
