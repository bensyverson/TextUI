/// A per-frame cache for layout measurements.
///
/// `LayoutCache` is a reference type so it survives value-type copies of
/// ``RenderContext``. A fresh instance is created by the run loop at the
/// start of each frame and discarded at the end, ensuring no stale data
/// persists across frames.
///
/// Views like ``ScrollView`` use this to avoid redundant child measurements
/// when the same view is probed multiple times within a single frame
/// (e.g. by ``StackLayout/layoutGreedy`` flexibility probes).
@MainActor
final class LayoutCache {
    private var entries: [AnyHashable: any Sendable] = [:]

    /// Returns the cached value for the given key, if it exists and matches the expected type.
    func get<T: Sendable>(forKey key: AnyHashable, as _: T.Type) -> T? {
        entries[key] as? T
    }

    /// Stores a value in the cache under the given key.
    func set(_ value: some Sendable, forKey key: AnyHashable) {
        entries[key] = value
    }
}
