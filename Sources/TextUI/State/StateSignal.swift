/// A global signal that notifies the run loop when state has changed.
///
/// When an ``Observed`` property is mutated, it calls ``send()`` to
/// signal that a re-render is needed. The run loop consumes the
/// ``stream`` to trigger render cycles.
///
/// Uses `bufferingNewest(1)` for natural debouncing — rapid mutations
/// coalesce into a single signal rather than queuing multiple renders.
@MainActor
public enum StateSignal {
    private static let (internalStream, continuation) = AsyncStream<Void>.makeStream(
        bufferingPolicy: .bufferingNewest(1),
    )

    /// An async stream that yields a value whenever state changes.
    ///
    /// Consume this in the run loop to trigger re-renders.
    public static var stream: AsyncStream<Void> {
        internalStream
    }

    /// Signals that state has changed and a re-render is needed.
    public static func send() {
        continuation.yield(())
    }
}
