/// A view that shows the progress of a task.
///
/// `ProgressView` supports both indeterminate (spinner) and determinate
/// (progress bar) modes. Animation is driven by ``AnimationTick``, which
/// automatically starts the run loop's animation timer when the view is visible.
///
/// `ProgressView` is a composite view — its `body` uses `@ViewBuilder` to
/// conditionally compose ``Text``, ``Canvas``, and ``HStack`` children
/// depending on the style and whether a label is present.
///
/// ```swift
/// // Indeterminate spinner
/// ProgressView()
///
/// // With label
/// ProgressView("Loading...")
///
/// // Determinate progress
/// ProgressView(value: 0.42)
///
/// // With label and total
/// ProgressView("Uploading", value: bytesWritten, total: totalBytes)
/// ```
public struct ProgressView: View {
    /// The optional label displayed alongside the progress indicator.
    let label: String?

    /// The current progress value, or `nil` for indeterminate.
    let value: Double?

    /// The total value representing completion (default 1.0).
    let total: Double

    /// The animation frame counter, driving spinner and bar animations.
    @AnimationTick var tick

    /// Creates an indeterminate progress view.
    public init() {
        label = nil
        value = nil
        total = 1.0
    }

    /// Creates an indeterminate progress view with a label.
    public init(_ label: String) {
        self.label = label
        value = nil
        total = 1.0
    }

    /// Creates a determinate progress view.
    public init(value: Double, total: Double = 1.0) {
        label = nil
        self.value = value
        self.total = total
    }

    /// Creates a determinate progress view with a label.
    public init(_ label: String, value: Double, total: Double = 1.0) {
        self.label = label
        self.value = value
        self.total = total
    }

    /// The progress fraction clamped to 0...1.
    private var progress: Double {
        guard let value, total > 0 else { return 0 }
        return min(max(value / total, 0), 1)
    }

    /// Whether this progress view shows determinate progress.
    private var isDeterminate: Bool {
        value != nil
    }

    /// The resolved style, considering context overrides.
    private var resolvedStyle: ProgressViewStyle {
        RenderEnvironment.current.progressViewStyle
            ?? (isDeterminate ? .bar(showPercent: true) : .compact)
    }

    // MARK: - Spinner frames

    static let spinnerFrames = ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"]
    static let blockChars: [Character] = ["▏", "▎", "▍", "▌", "▋", "▊", "▉", "█"]

    // MARK: - Body

    // swiftformat:disable redundantViewBuilder
    @ViewBuilder
    public var body: some View {
        if let label {
            HStack(spacing: 1) {
                Text(label)
                indicator
            }
            .animating()
        } else {
            indicator
                .animating()
        }
    }

    // swiftformat:enable redundantViewBuilder

    /// The progress indicator view, styled according to the resolved style.
    @ViewBuilder
    private var indicator: some View {
        switch resolvedStyle {
        case .compact:
            compactIndicator
        case let .bar(showPercent):
            barIndicator(showPercent: showPercent)
        }
    }

    /// A single-character compact indicator.
    @ViewBuilder
    private var compactIndicator: some View {
        if isDeterminate {
            let index = Int(progress * Double(Self.blockChars.count - 1))
            Text(String(Self.blockChars[index]))
        } else {
            let frame = Self.spinnerFrames[tick % Self.spinnerFrames.count]
            Text(frame)
        }
    }

    /// A horizontal bar indicator rendered via ``Canvas``.
    @ViewBuilder
    private func barIndicator(showPercent: Bool) -> some View {
        let currentTick = tick
        let currentProgress = progress
        let determinate = isDeterminate
        Canvas { buffer, region in
            guard region.width > 0 else { return }
            if determinate {
                let percentWidth = showPercent ? 5 : 0
                let barWidth = max(0, region.width - percentWidth)
                let filled = Int(currentProgress * Double(barWidth))
                let filledStr = String(repeating: "▓", count: filled)
                let emptyStr = String(repeating: "░", count: barWidth - filled)
                buffer.write(filledStr + emptyStr, row: region.row, col: region.col)
                if showPercent, barWidth + percentWidth <= region.width {
                    let pct = String(format: "%3d%%", Int(currentProgress * 100))
                    buffer.write(" " + pct, row: region.row, col: region.col + barWidth)
                }
            } else {
                for i in 0 ..< region.width {
                    let offset = (i + currentTick) % 4
                    let char: Character = offset == 0 ? "▓" : "░"
                    buffer.write(String(char), row: region.row, col: region.col + i)
                }
            }
        }
        .frame(height: 1)
    }
}
