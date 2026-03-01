import TextUI

/// Shared observable state for the demo application.
///
/// State is always accessed on the main actor (via the render loop).
/// Uses `@unchecked Sendable` so it can be stored in `Sendable` views.
/// Property setters trigger re-renders via `StateSignal`.
final class DemoState: @unchecked Sendable {
    init() {
        Task { @MainActor [weak self] in
            while let s = self {
                s.progress = 0.0
                for i in 1 ... 100 {
                    try? await Task.sleep(for: .milliseconds(100))
                    guard let s = self else { return }
                    s.progress = Double(i) / 100.0
                }
                try? await Task.sleep(for: .seconds(1))
            }
        }
    }

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
