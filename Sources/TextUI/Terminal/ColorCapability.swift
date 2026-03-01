import Foundation

/// The color capability level of the terminal.
///
/// Used to auto-detect what the terminal supports and downgrade
/// colors accordingly. Detection inspects environment variables
/// like `NO_COLOR`, `COLORTERM`, and `TERM`.
///
/// ```swift
/// let cap = ColorCapability.detect()
/// // Use cap to decide whether to emit RGB, 256-color, or basic ANSI
/// ```
public enum ColorCapability: Friendly, Comparable {
    /// No color support (e.g., `NO_COLOR` is set or `TERM=dumb`).
    case none

    /// Basic 16-color ANSI support.
    case basic16

    /// 256-color palette support.
    case palette256

    /// Full 24-bit RGB (truecolor) support.
    case trueColor

    /// Detects the terminal's color capability from environment variables.
    ///
    /// Detection order:
    /// 1. `NO_COLOR` set → `.none`
    /// 2. `COLORTERM` contains `truecolor` or `24bit` → `.trueColor`
    /// 3. `TERM` contains `256color` → `.palette256`
    /// 4. `TERM` is `dumb` → `.none`
    /// 5. Default → `.basic16`
    ///
    /// - Parameter env: The environment dictionary to inspect. Defaults to
    ///   the current process environment, but can be overridden for testing.
    public static func detect(
        from env: [String: String] = ProcessInfo.processInfo.environment,
    ) -> ColorCapability {
        // NO_COLOR spec: any value (even empty) disables color
        if env["NO_COLOR"] != nil {
            return .none
        }

        if let colorterm = env["COLORTERM"]?.lowercased() {
            if colorterm.contains("truecolor") || colorterm.contains("24bit") {
                return .trueColor
            }
        }

        if let term = env["TERM"]?.lowercased() {
            if term.contains("256color") {
                return .palette256
            }
            if term == "dumb" {
                return .none
            }
        }

        return .basic16
    }
}
