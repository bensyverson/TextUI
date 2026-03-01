import TextUI

/// Shared theme state injected via `.environmentObject()`.
///
/// This demonstrates the `@EnvironmentObject` pattern for state that
/// multiple views need to read or write. The theme picker in ``FormTab``
/// writes to it; ``ProgressTab`` reads it to tint its progress bars.
final class ThemeState: @unchecked Sendable {
    var colorIndex: Int = 0 {
        didSet {
            MainActor.assumeIsolated { StateSignal.send() }
        }
    }

    /// The theme names displayed in the picker.
    static let names = ["Default", "Ocean", "Forest", "Sunset"]

    /// The accent color for the current theme.
    var accentColor: Style.Color {
        switch colorIndex {
        case 1: .blue
        case 2: .green
        case 3: .yellow
        default: .cyan
        }
    }
}
