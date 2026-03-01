import TextUI

/// Shared observable state for the demo application.
///
/// State is always accessed on the main actor (via the render loop).
/// Uses `@unchecked Sendable` so it can be stored in `Sendable` views.
/// Property setters trigger re-renders via `StateSignal`.
final class DemoState: @unchecked Sendable {
    var name: String = "" {
        didSet { notifyChange() }
    }

    var email: String = "" {
        didSet { notifyChange() }
    }

    var darkMode: Bool = false {
        didSet { notifyChange() }
    }

    var notifications: Bool = true {
        didSet { notifyChange() }
    }

    var statusMessage: String = "Ready" {
        didSet { notifyChange() }
    }

    var progress: Double = 0.35 {
        didSet { notifyChange() }
    }

    var colorIndex: Int = 0 {
        didSet { notifyChange() }
    }

    private func notifyChange() {
        MainActor.assumeIsolated {
            StateSignal.send()
        }
    }
}
