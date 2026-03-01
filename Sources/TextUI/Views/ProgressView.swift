/// A view that shows the progress of a task.
///
/// `ProgressView` supports both indeterminate (spinner) and determinate
/// (progress bar) modes. Animation is driven by ``AnimationTick``, which
/// automatically starts the run loop's animation timer when the view is visible.
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
public struct ProgressView: PrimitiveView, @unchecked Sendable {
    /// The optional label displayed alongside the progress indicator.
    let label: String?

    /// The current progress value, or `nil` for indeterminate.
    let value: Double?

    /// The total value representing completion (default 1.0).
    let total: Double

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
    private func resolvedStyle(context: RenderContext) -> ProgressViewStyle {
        context.progressViewStyle ?? (isDeterminate ? .bar(showPercent: true) : .compact)
    }

    /// The width of the label portion including separator space.
    private var labelWidth: Int {
        guard let label else { return 0 }
        return label.displayWidth + 1 // label + space
    }

    // MARK: - Spinner frames

    private static let spinnerFrames = ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"]
    private static let blockChars: [Character] = ["▏", "▎", "▍", "▌", "▋", "▊", "▉", "█"]

    // MARK: - PrimitiveView

    public func sizeThatFits(_ proposal: SizeProposal, context: RenderContext) -> Size2D {
        let style = resolvedStyle(context: context)
        switch style {
        case .compact:
            let indicatorWidth = 1
            let width = labelWidth + indicatorWidth
            let proposedW = proposal.width ?? width
            return Size2D(width: min(width, proposedW), height: proposedW > 0 ? 1 : 0)
        case .bar:
            let minWidth = labelWidth + 1
            let width = proposal.width ?? minWidth
            return Size2D(width: width, height: width > 0 ? 1 : 0)
        }
    }

    public func render(into buffer: inout Buffer, region: Region, context: RenderContext) {
        guard !region.isEmpty else { return }

        // Read tick from animation tracker (signals animation request)
        let tracker = context.animationTracker
        tracker?.requestAnimation()
        let tick = tracker?.tickCount ?? 0

        var col = region.col

        // Render label if present
        if let label {
            let labelLen = min(label.displayWidth, region.width)
            buffer.write(String(label.prefix(labelLen)), row: region.row, col: col)
            col += labelLen
            if col < region.col + region.width {
                buffer.write(" ", row: region.row, col: col)
                col += 1
            }
        }

        let remaining = region.col + region.width - col
        guard remaining > 0 else { return }

        let style = resolvedStyle(context: context)
        switch style {
        case .compact:
            renderCompact(into: &buffer, row: region.row, col: col, tick: tick)
        case let .bar(showPercent):
            renderBar(
                into: &buffer,
                row: region.row,
                col: col,
                width: remaining,
                showPercent: showPercent,
                tick: tick,
            )
        }
    }

    // MARK: - Rendering Helpers

    private func renderCompact(into buffer: inout Buffer, row: Int, col: Int, tick: Int) {
        if isDeterminate {
            let index = Int(progress * Double(Self.blockChars.count - 1))
            buffer.write(String(Self.blockChars[index]), row: row, col: col)
        } else {
            let frame = Self.spinnerFrames[tick % Self.spinnerFrames.count]
            buffer.write(frame, row: row, col: col)
        }
    }

    private func renderBar(
        into buffer: inout Buffer,
        row: Int,
        col: Int,
        width: Int,
        showPercent: Bool,
        tick: Int,
    ) {
        if isDeterminate {
            let percentWidth = showPercent ? 5 : 0
            let barWidth = max(0, width - percentWidth)
            let filled = Int(progress * Double(barWidth))
            let filledStr = String(repeating: "█", count: filled)
            let emptyStr = String(repeating: "░", count: barWidth - filled)
            buffer.write(filledStr + emptyStr, row: row, col: col)
            if showPercent, barWidth + percentWidth <= width {
                let pct = String(format: "%3d%%", Int(progress * 100))
                buffer.write(" " + pct, row: row, col: col + barWidth)
            }
        } else {
            for i in 0 ..< width {
                let offset = (i + tick) % 4
                let char: Character = offset == 0 ? "█" : "░"
                buffer.write(String(char), row: row, col: col + i)
            }
        }
    }
}
