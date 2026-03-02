import TextUI

/// A tab demonstrating ProgressView in various styles.
///
/// Uses `@State` and `.task {}` for the animation loop, and reads
/// ``ThemeState`` via `@EnvironmentObject` to tint the progress bars
/// with the accent color chosen in ``FormTab``.
struct ProgressTab: View {
    @EnvironmentObject var theme: ThemeState
    @State var progress: Double = 0.0

    var body: some View {
        VStack(spacing: 1) {
            Text("Progress Indicators", style: .bold)
                .padding(bottom: 2)

            Text("Indeterminate spinner:", style: .dim)
            ProgressView("Loading")
                .foregroundColor(theme.accentColor)
                .padding(bottom: 2)

            Text("Compact progress:", style: .dim)
            ProgressView("Indexing", value: progress)
                .progressViewStyle(.compact)
                .foregroundColor(theme.accentColor)
                .padding(bottom: 2)

            Text("Determinate bar (\(Int(progress * 100))%):", style: .dim)
            ProgressView("Download", value: progress)
                .foregroundColor(theme.accentColor)
                .padding(bottom: 2)

            Text("Indeterminate bar:", style: .dim)
            ProgressView("Syncing")
                .progressViewStyle(.bar())
                .foregroundColor(theme.accentColor)
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
