/// Manages async tasks keyed by view identity with frame-based lifecycle.
///
/// `TaskStore` follows the `beginFrame()`/`endFrame()` pattern used by
/// ``FocusStore``, ``AnimationTracker``, and ``OverlayStore``. During
/// each render pass, views call ``markActive(key:action:)`` to declare
/// that their task should be running. After the frame completes, any
/// task whose key was **not** marked active is cancelled and removed.
///
/// This ensures that tasks are:
/// - Started when a view first appears in the tree
/// - Kept alive while the view remains in the tree
/// - Automatically cancelled when the view is removed
///
@MainActor
final class TaskStore {
    /// Running tasks keyed by view identity.
    private var tasks: [String: Task<Void, Never>] = [:]

    /// Keys marked active during the current render frame.
    private var activeKeys: Set<String> = []

    /// Resets the active key set at the start of each frame.
    func beginFrame() {
        activeKeys.removeAll()
    }

    /// Marks a task key as active. If no task exists for the key, one is spawned.
    ///
    /// - Parameters:
    ///   - key: The view identity key (typically `#fileID:#line`).
    ///   - action: The async work to perform.
    func markActive(key: String, action: @escaping @MainActor @Sendable () async -> Void) {
        activeKeys.insert(key)
        if tasks[key] == nil {
            tasks[key] = Task { await action() }
        }
    }

    /// Cancels and removes tasks that were not marked active this frame.
    func endFrame() {
        for (key, task) in tasks where !activeKeys.contains(key) {
            task.cancel()
            tasks.removeValue(forKey: key)
        }
    }
}
